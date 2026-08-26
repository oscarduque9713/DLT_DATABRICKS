
## importar librerias
from pyspark import pipelines as dp
from pyspark.sql.functions import col, current_timestamp
from pyspark.sql.types import StructType, StructField, StringType


catalog = spark.conf.get("CATALOG")
STORAGE_ACCOUNT = spark.conf.get("STORAGE_ACCOUNT")

source_path = f"abfss://raw@{STORAGE_ACCOUNT}.dfs.core.windows.net/"

source_path_transactions_re = f"{source_path}/src_txn_cdc_re"

txn_schema = StructType([
    StructField("account_id", StringType(), True),
    StructField("amount", StringType(), True),
    StructField("channel", StringType(), True),
    StructField("currency", StringType(), True),
    StructField("merchant", StringType(), True),
    StructField("op", StringType(), True),
    StructField("txn_id", StringType(), True),
    StructField("txn_ts", StringType(), True),
    StructField("updated_at", StringType(), True)
])


@dp.append_flow(
    name = "txn_reprocess",
    target=f"{catalog}.ly_bronze.txn_RW",
    comment= "Reprocess proceso "
)
def txn_reprocess():

    return (
        spark.readStream
        .format("cloudFiles")
        .option("cloudFiles.format", "json")
        .option("multiLine", "true")
        .schema(txn_schema)
        .load(source_path_transactions_re)
        .select( "*", 
                    col("_metadata.file_name").alias("source_file"), 
                    col("_metadata.file_modification_time").alias("file_mod_time"), 
                    current_timestamp().alias("ingestion_ts") 
                    )
    )


#### PARA EL HISTORICO ONCE TRUE
source_path_transactions_historical = (
    f"{source_path}/src_txn_hist"
)


@dp.append_flow(
    name="txn_historical_backfill",
    target=f"{catalog}.ly_bronze.txn_RW",
    once=True,
    comment="Carga histórica de transacciones desde Parquet"
)
def txn_historical_backfill():

    return (
        spark.read
        .format("parquet")
        .schema(txn_schema)
        .load(source_path_transactions_historical)
        .select(
            "*",
            col("_metadata.file_name").alias("source_file"),
            col("_metadata.file_modification_time").alias("file_mod_time"),
            current_timestamp().alias("ingestion_ts")
        )
    )
