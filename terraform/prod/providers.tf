terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.128"
    }
  }
}

provider "databricks" {
  host = var.databricks_host
}