
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

@dp.temporary_view(name="txn_dq")
def txn_dq():

    txn = (
        spark.readStream
        .table(f"{catalog}.ly_bronze.txn_RW")
        .withColumn(
            "updated_at",
            to_timestamp(col("updated_at"))
        )
        .withColumn(
            "txn_ts",
            to_timestamp(col("txn_ts"))
        )
    )

    account_ref = (
        spark.read
        .table(f"{catalog}.ly_silver.dim_account")
        .filter(col("__END_AT").isNull())
        .select(
            col("account_id").alias("ref_account_id")
        )
        .distinct()
    )

    return (
        txn.alias("t")
        .join(
            account_ref.alias("a"),
            col("t.account_id") == col("a.ref_account_id"),
            "left"
        )
        .select(
            col("t.*"),

            col("a.ref_account_id")
                .isNotNull()
                .alias("account_exists"),

            (
                ~(
                    col("t.op").isin("I", "U", "D")
                    & col("t.txn_id").isNotNull()
                    & (
                        (col("t.op") == "D")
                        | col("t.account_id").isNotNull()
                    )
                    & col("t.updated_at").isNotNull()
                    & (
                        (col("t.op") == "D")
                        | col("a.ref_account_id").isNotNull()
                    )
                )
            ).alias("is_quarantined"),

            concat_ws(
                "; ",

                when(
                    ~col("t.op").isin("I", "U", "D"),
                    lit("OPERACION CDC INVALIDA")
                ),

                when(
                    col("t.txn_id").isNull(),
                    lit("TXN_ID VACIO")
                ),

                when(
                    col("t.op").isin("I", "U")
                    & col("t.account_id").isNull(),
                    lit("ACCOUNT_ID VACIO")
                ),

                when(
                    col("t.op").isin("I", "U")
                    & col("t.account_id").isNotNull()
                    & col("a.ref_account_id").isNull(),
                    lit("ACCOUNT_ID NO EXISTE EN DIM_ACCOUNT")
                ),

                when(
                    col("t.updated_at").isNull(),
                    lit("UPDATED_AT VACIO O INVALIDO")
                )

            ).alias("quarantine_reason")
        )
    )



# ---------------------------------------------------------
# 2. Registros válidos + lógica de soft delete
# ---------------------------------------------------------
@dp.temporary_view(
    name="txn_valid"
)
def txn_valid():

    return (
        spark.readStream
        .table("txn_dq")
        .filter(col("is_quarantined") == False)

        # Soft delete
        .withColumn(
            "is_deleted",
            when(
                col("op") == "D",
                lit(True)
            ).otherwise(lit(False))
        )

        .withColumn(
            "deleted_at",
            when(
                col("op") == "D",
                col("updated_at")
            ).otherwise(
                lit(None).cast("timestamp")
            )
        )

        .drop(
            "is_quarantined",
            "quarantine_reason",
            "account_exists"
        )
    )


# ---------------------------------------------------------
# 3. Tabla quarantine
# ---------------------------------------------------------
@dp.table(
    name=f"{catalog}.ly_silver.quarantine_txn",
    comment="Transacciones rechazadas por reglas DQ e integridad referencial"
)
def quarantine_txn():

    return (
        spark.readStream
        .table("txn_dq")
        .filter(col("is_quarantined") == True)
        .withColumn(
            "quarantine_ts",
            current_timestamp()
        )
    )


# ---------------------------------------------------------
# 4. Target Silver
# ---------------------------------------------------------
dp.create_streaming_table(
    name=f"{catalog}.ly_silver.transactions",
    comment="Transacciones Silver con CDC, idempotencia y soft delete"
)


# ---------------------------------------------------------
# 5. AUTO CDC
# ---------------------------------------------------------
dp.create_auto_cdc_flow(
    target=f"{catalog}.ly_silver.transactions",

    source="txn_valid",

    # Business key
    keys=["txn_id"],

    # Orden lógico de los eventos
    sequence_by=col("updated_at"),

    # op se usa solo para construir el soft delete
    except_column_list=[
        "op",
        "source_file",
        "file_mod_time",
        "ingestion_ts"
    ],

    # Queremos estado actual de cada transacción
    stored_as_scd_type="1"
)