# Creates the storage credential used to access PROD Azure storage.
resource "databricks_storage_credential" "prod" {
  # Storage credential name in Databricks.
  name = "cred_prod"

  # Uses an Azure Managed Identity through an Access Connector.
  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }

  # Terraform principal will own the storage credential.
  owner = var.terraform_principal

  # Indicates that this credential is managed by Terraform.
  comment = "Storage credential PROD managed by Terraform"
}