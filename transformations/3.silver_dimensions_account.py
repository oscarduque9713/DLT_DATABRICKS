
from pyspark import pipelines as dp
from pyspark.sql.functions import (
    col,
    when,
    concat_ws,
    lit,
    current_timestamp,
    to_timestamp,
    to_date
)

catalog = spark.conf.get("CATALOG")


# ---------------------------------------------------------
# 1. Evaluar reglas DQ una sola vez
# ---------------------------------------------------------
@dp.temporary_view(
    name="account_dq"
)
def account_dq():

    account = (
        spark.readStream
        .table(f"{catalog}.ly_bronze.account_RW")
        .withColumn(
            "updated_at",
            to_timestamp(col("updated_at"))
        )
        .withColumn(
            "opened_date",
            to_date(col("opened_date"))
        )
    )
    

    # Referencia a Silver customer
    customer_ref = (
        spark.read
        .table(f"{catalog}.ly_silver.dim_customer")
        .filter(col("__END_AT").isNull())
        .select(
            col("customer_id").alias("cust_customer_id")
        )
        .distinct()
    )

    return (
        account.alias("a")
        .join(
            customer_ref.alias("c"),
            col("a.customer_id") == col("c.cust_customer_id"),
            "left"
        )
        .select(
            col("a.account_id"),
            col("a.customer_id"),
            col("a.status"),
            col("a.opened_date"),
            col("a.updated_at"),
            col("a.source_file"),
            col("a.file_mod_time"),
            col("a.ingestion_ts"),
            col("c.cust_customer_id")
                .isNotNull()
                .alias("account_exists"),

            # Flag DQ
            (
                ~(
                    col("a.account_id").isNotNull()
                    & col("a.account_id").rlike("^ACC[0-9]+$")
                    & col("a.customer_id").isNotNull()
                    & col("a.customer_id").rlike("^CUST[0-9]+$")
                    & col("a.updated_at").isNotNull()
                    & col("c.cust_customer_id").isNotNull()
                )
            ).alias("is_quarantined"),

            # Razones DQ
            concat_ws(
                "; ",

                when(
                    col("a.account_id").isNull(),
                    lit("account_id SIN ID")
                ),

                when(
                    col("a.account_id").isNotNull()
                    & ~col("a.account_id").rlike("^ACC[0-9]+$"),
                    lit("FORMATO account_id INVALIDO")
                ),

                when(
                    col("a.customer_id").isNull(),
                    lit("customer_id SIN ID")
                ),

                when(
                    col("a.customer_id").isNotNull()
                    & ~col("a.customer_id").rlike("^CUST[0-9]+$"),
                    lit("FORMATO customer_id INVALIDO")
                ),

                when(
                    col("a.updated_at").isNull(),
                    lit("UPDATED_AT VACIO")
                ),

                when(
                    col("a.customer_id").isNotNull()
                    & col("c.cust_customer_id").isNull(),
                    lit("CUSTOMER_ID NO EXISTE EN DIM_customer")
                )

            ).alias("quarantine_reason")
        )
    )

    # ---------------------------------------------------------
# 2. account válidos
# ---------------------------------------------------------
@dp.temporary_view(
    name="account_valid"
)
def account_valid():

    return (
        spark.readStream
        .table("account_dq")
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
    name=f"{catalog}.ly_silver.quarantine_account",
    comment="Registros account rechazados por reglas de calidad"
)
def quarantine_account():

    return (
        spark.readStream
        .table("account_dq")
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
    name=f"{catalog}.ly_silver.dim_account",
    comment="Dimensión account SCD Type 2"
)

# ---------------------------------------------------------
# 5. AUTO CDC SCD2
# ---------------------------------------------------------
dp.create_auto_cdc_flow(
    target=f"{catalog}.ly_silver.dim_account",

    source="account_valid",

    keys=["account_id"],

    sequence_by=col("updated_at"),

    except_column_list=[
        "source_file",
        "file_mod_time",
        "ingestion_ts"
    ],

    stored_as_scd_type="2"
)