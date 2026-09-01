# Creates the external location for PROD raw data.
resource "databricks_external_location" "raw_prod" {
  # External location name in Databricks.
  name = "ext_raw_prod"

  # ADLS Gen2 path where raw data is stored.
  url = "abfss://raw@adlsproject13prod2.dfs.core.windows.net/"

  # Storage credential used to access the ADLS container.
  credential_name = databricks_storage_credential.prod.name

  # Terraform principal will own the external location.
  owner = var.terraform_principal

  # Indicates the purpose of this external location.
  comment = "External location for PROD raw data"
}


# Grants the deployment principal read access to files in the raw external location.
resource "databricks_grant" "raw_external_location_sp" {
  external_location = databricks_external_location.raw_prod.id

  principal = var.deploy_principal

  privileges = [
    "READ_FILES"
  ]
}