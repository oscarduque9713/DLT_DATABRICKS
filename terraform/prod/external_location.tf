resource "databricks_external_location" "metastore_prod" {
  name = "ext_metastore_prod"

  url = "abfss://metastore@adlsproject13prod2.dfs.core.windows.net/"

  credential_name = databricks_storage_credential.prod.name

  comment = "External location for PROD managed storage"
}