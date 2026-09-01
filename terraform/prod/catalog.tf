# Creates the PROD Unity Catalog in Databricks.
resource "databricks_catalog" "prod" {
  # Catalog name.
  name = var.catalog_name

  # Restricts catalog access to explicitly assigned workspaces.
  isolation_mode = "ISOLATED"

  # Root storage location for the catalog.
  storage_root = var.catalog_storage_root

  # Terraform principal will own the catalog.
  owner = var.terraform_principal

  # Indicates this resource is managed by Terraform.
  comment = "Catalog PROD managed by Terraform"

  # The external location must exist before creating the catalog.
  depends_on = [
    databricks_external_location.metastore_prod
  ]
}