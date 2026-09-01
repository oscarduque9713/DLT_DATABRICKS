
# Grants the deployment principal access to the PROD catalog.
resource "databricks_grant" "prod_catalog_sp" {
  catalog = databricks_catalog.prod.name

  principal = var.deploy_principal

  # Allows the principal to access and use the catalog.
  privileges = [
    "USE_CATALOG"
  ]
}


# Grants the deployment principal permissions to create and manage Bronze layer objects.
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


# Grants the deployment principal permissions to create and manage Silver layer objects.
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


# Grants the deployment principal permissions to create and manage Gold layer objects.
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


# Grants the deployment principal permissions to manage control tables.
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


# Grants the deployment principal permissions to create and execute security functions.
resource "databricks_grant" "security_sp" {
  schema = databricks_schema.security.id

  principal = var.deploy_principal

  privileges = [
    "USE_SCHEMA",
    "CREATE_FUNCTION",
    "EXECUTE"
  ]
}

