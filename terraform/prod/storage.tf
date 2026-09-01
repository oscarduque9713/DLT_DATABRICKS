resource "databricks_storage_credential" "prod" {
  name = "cred_prod"

  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }

  owner = var.terraform_principal

  comment = "Storage credential PROD managed by Terraform"
}