
from pyspark import pipelines as dp
from pyspark.sql.functions import (
    col,
    when,
    concat_ws,
    lit,
    current_timestamp,
    to_timestamp
)

catalog = spark.conf.get("CATALOG")


# ---------------------------------------------------------
# 1. Evaluar reglas DQ una sola vez
# ---------------------------------------------------------
@dp.temporary_view(
    name="customer_dq"
)
def customer_dq():

    customer = (
        spark.readStream
        .table(f"{catalog}.ly_bronze.customer_RW")
        .withColumn(
            "updated_at",
            to_timestamp(col("updated_at"))
        )
    )

    return (
        customer
        .select(
            col("customer_id"),
            col("full_name"),
            col("doc_id"),
            col("email"),
            col("phone"),
            col("updated_at"),
            col("source_file"),
            col("file_mod_time"),
            col("ingestion_ts"),

            (
                ~(
                    col("customer_id").isNotNull()
                    & col("customer_id").rlike("^CUST[0-9]+$")
                    & col("full_name").isNotNull()
                    & col("doc_id").isNotNull()
                    & col("updated_at").isNotNull()
                )
            ).alias("is_quarantined"),

            concat_ws(
                "; ",

                when(
                    col("customer_id").isNull(),
                    lit("CUSTOMER_ID SIN ID")
                ),

                when(
                    col("customer_id").isNotNull()
                    & ~col("customer_id").rlike("^CUST[0-9]+$"),
                    lit("FORMATO CUSTOMER_ID INVALIDO")
                ),

                when(
                    col("full_name").isNull(),
                    lit("FULL_NAME VACIO")
                ),

                when(
                    col("doc_id").isNull(),
                    lit("DOC_ID VACIO")
                ),

                when(
                    col("updated_at").isNull(),
                    lit("UPDATED_AT VACIO")
                )
            ).alias("quarantine_reason")
        )
    )

    # ---------------------------------------------------------
# 2. Customers válidos
# ---------------------------------------------------------
@dp.temporary_view(
    name="customer_valid"
)
def customer_valid():

    return (
        spark.readStream
        .table("customer_dq")
        .filter(col("is_quarantined") == False)
        .drop(
            "is_quarantined",
            "quarantine_reason"
        )
    )

# ---------------------------------------------------------
# 3. Tabla quarantine
# ---------------------------------------------------------
@dp.table(
    name=f"{catalog}.ly_silver.quarantine_customer",
    comment="Registros customer rechazados por reglas de calidad"
)
def quarantine_customer():

    return (
        spark.readStream
        .table("customer_dq")
        .filter(col("is_quarantined") == True)
        .withColumn(
            "quarantine_ts",
            current_timestamp()
        )
    )

# ---------------------------------------------------------
# 4. Target Silver SCD Type 2
# ---------------------------------------------------------
dp.create_streaming_table(
    name=f"{catalog}.ly_silver.dim_customer",
    comment="Dimensión Customer SCD Type 2"
)

# ---------------------------------------------------------
# 5. AUTO CDC SCD2
# ---------------------------------------------------------
dp.create_auto_cdc_flow(
    target=f"{catalog}.ly_silver.dim_customer",

    source="customer_valid",

    keys=["customer_id"],

    sequence_by=col("updated_at"),

    except_column_list=[
        "source_file",
        "file_mod_time",
        "ingestion_ts"
    ],

    stored_as_scd_type="2"
)