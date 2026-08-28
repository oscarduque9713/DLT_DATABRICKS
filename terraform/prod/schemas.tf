resource "databricks_schema" "bronze" {
  catalog_name = databricks_catalog.prod.name
  name         = "ly_bronze"
  comment      = "Bronze schema for PROD"
}

resource "databricks_schema" "silver" {
  catalog_name = databricks_catalog.prod.name
  name         = "ly_silver"
  comment      = "Silver schema for PROD"
}

resource "databricks_schema" "gold" {
  catalog_name = databricks_catalog.prod.name
  name         = "ly_gold"
  comment      = "Gold schema for PROD"
}

resource "databricks_schema" "control" {
  catalog_name = databricks_catalog.prod.name
  name         = "control"
  comment      = "Control schema for PROD"
}

resource "databricks_schema" "security" {
  catalog_name = databricks_catalog.prod.name
  name         = "security"
  comment      = "Security schema for PROD"
}