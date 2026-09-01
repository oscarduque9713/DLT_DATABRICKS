resource "databricks_catalog" "prod" {
  name = var.catalog_name

  isolation_mode = "ISOLATED"
  storage_root   = var.catalog_storage_root
  owner          = var.terraform_principal

  comment = "Catalog PROD managed by Terraform"

  depends_on = [
    databricks_external_location.metastore_prod
  ]
}