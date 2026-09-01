# Creates the external location used for PROD managed storage.
resource "databricks_external_location" "metastore_prod" {
  # External location name in Databricks.
  name = "ext_metastore_prod"

  # ADLS Gen2 path used by the external location.
  url = "abfss://metastore@adlsproject13prod2.dfs.core.windows.net/"

  # Storage credential used to access the ADLS container.
  credential_name = databricks_storage_credential.prod.name

  # Terraform principal will own the external location.
  owner = var.terraform_principal

  # Indicates the purpose of this external location.
  comment = "External location for PROD managed storage"
}
