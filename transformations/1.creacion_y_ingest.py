
## importar librerias
from pyspark import pipelines as dp
from pyspark.sql.functions import col, current_timestamp, sha2, concat_ws


catalog = spark.conf.get("CATALOG")
STORAGE_ACCOUNT = spark.conf.get("STORAGE_ACCOUNT")

source_path = f"abfss://raw@{STORAGE_ACCOUNT}.dfs.core.windows.net/"

source_path_customer = f"{source_path}/customer"
source_path_account = f"{source_path}/account"
source_path_transactions = f"{source_path}/src_txn_cdc"


### customer
@dp.table( 
          name=f"{catalog}.ly_bronze.customer_RW", 
          comment="Tabla Bronze que almacena el contenido crudo de customers en CSV" ) 

def customer_bronze(): 
    return ( 
            spark.readStream 
            .format("cloudFiles") 
            .option("cloudFiles.format", "csv") 
            .option("header", "true") 
            .option("delimiter", ",") 
            .option("cloudFiles.schemaEvolutionMode", "addNewColumns") 
            .load(source_path_customer) 
            .select( "*", 
                    col("_metadata.file_name").alias("source_file"), 
                    col("_metadata.file_modification_time").alias("file_mod_time"),
                    col("_metadata.file_size").alias("file_size"), 
                    current_timestamp().alias("ingestion_ts"),
                    sha2(
                        concat_ws(
                        "||",
                        col("_metadata.file_name"),
                        col("_metadata.file_size"),
                        col("_metadata.file_modification_time").cast("string")
                        ),
                        256
                    ).alias("file_fingerprint")
                    )
    )


## account

@dp.table( 
          name=f"{catalog}.ly_bronze.account_RW", 
          comment="Tabla Bronze que almacena el contenido crudo de account en CSV" 
    ) 

def account_bronze(): 
    return ( 
            spark.readStream 
            .format("cloudFiles") 
            .option("cloudFiles.format", "csv") 
            .option("header", "true") 
            .option("delimiter", ",") 
            .option("cloudFiles.schemaEvolutionMode", "addNewColumns") 
            .load(source_path_account) 
            .select( "*", 
                    col("_metadata.file_name").alias("source_file"), 
                    col("_metadata.file_modification_time").alias("file_mod_time"), 
                    col("_metadata.file_size").alias("file_size"),
                    current_timestamp().alias("ingestion_ts"),
                    sha2(
                        concat_ws(
                        "||",
                        col("_metadata.file_name"),
                        col("_metadata.file_size"),
                        col("_metadata.file_modification_time").cast("string")
                        ),
                        256
                    ).alias("file_fingerprint")
                    )
    )

### txn transaccions

@dp.table( 
          name=f"{catalog}.ly_bronze.txn_RW", 
          comment="Tabla Bronze que almacena el contenido crudo de txn transaccions en CSV" ) 

def txn_bronze(): 
    return ( 
            spark.readStream 
            .format("cloudFiles") 
            .option("cloudFiles.format", "json") 
            .option("multiLine", "true")
            .option("cloudFiles.schemaEvolutionMode", "addNewColumns") 
            .load(source_path_transactions) 
            .select( "*", 
                    col("_metadata.file_name").alias("source_file"), 
                    col("_metadata.file_modification_time").alias("file_mod_time"),
                    col("_metadata.file_size").alias("file_size"),  
                    current_timestamp().alias("ingestion_ts"),
                    sha2(
                        concat_ws(
                        "||",
                        col("_metadata.file_name"),
                        col("_metadata.file_size"),
                        col("_metadata.file_modification_time").cast("string")
                        ),
                        256
                    ).alias("file_fingerprint")
                    )
    )