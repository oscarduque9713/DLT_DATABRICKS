
resource "databricks_grant" "prod_catalog_sp" {
  catalog = databricks_catalog.prod.name

  principal = var.deploy_principal

  privileges = [
    "USE_CATALOG"
  ]
}


resource "databricks_grant" "bronze_sp" {
  schema = databricks_schema.bronze.id

  principal = var.deploy_principal

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "CREATE_VOLUME",
    "SELECT",
    "MODIFY",
    "APPLY_TAG"
  ]
}

resource "databricks_grant" "silver_sp" {
  schema = databricks_schema.silver.id

  principal = var.deploy_principal

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "CREATE_VOLUME",
    "SELECT",
    "MODIFY",
    "APPLY_TAG"
  ]
}

resource "databricks_grant" "gold_sp" {
  schema = databricks_schema.gold.id

  principal = var.deploy_principal

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "CREATE_VOLUME",
    "SELECT",
    "MODIFY"
  ]
}


resource "databricks_grant" "control_sp" {
  schema = databricks_schema.control.id

  principal = var.deploy_principal

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "SELECT",
    "MODIFY"
  ]
}

resource "databricks_grant" "security_sp" {
  schema = databricks_schema.security.id

  principal = var.deploy_principal

  privileges = [
    "USE_SCHEMA",
    "CREATE_FUNCTION",
    "EXECUTE"
  ]
}
