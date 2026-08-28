resource "databricks_workspace_binding" "catalog_prod" {
  securable_name = databricks_catalog.prod.name
  securable_type = "catalog"

  workspace_id = var.workspace_id
  binding_type = "BINDING_TYPE_READ_WRITE"
}