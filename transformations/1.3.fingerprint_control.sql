
---- el catalogo ya viene predefinido

CREATE OR REFRESH STREAMING TABLE control.processed_files
AS

SELECT DISTINCT
    'customer' AS source_name,
    source_file,
    file_size,
    file_mod_time,
    file_fingerprint,
    ingestion_ts
FROM STREAM(ly_bronze.customer_RW)

UNION ALL

SELECT DISTINCT
    'account' AS source_name,
    source_file,
    file_size,
    file_mod_time,
    file_fingerprint,
    ingestion_ts
FROM STREAM(ly_bronze.account_RW)

UNION ALL

SELECT DISTINCT
    'txn' AS source_name,
    source_file,
    file_size,
    file_mod_time,
    file_fingerprint,
    ingestion_ts
FROM STREAM(ly_bronze.txn_RW);