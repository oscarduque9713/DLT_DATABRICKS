resource "databricks_external_location" "raw_prod" {
  name = "ext_raw_prod"

  url = "abfss://raw@adlsproject13prod2.dfs.core.windows.net/"

  credential_name = databricks_storage_credential.prod.name
  owner           = var.terraform_principal

  comment = "External location for PROD raw data"
}

resource "databricks_grant" "raw_external_location_sp" {
  external_location = databricks_external_location.raw_prod.id

  principal = var.deploy_principal

  privileges = [
    "READ_FILES"
  ]
}