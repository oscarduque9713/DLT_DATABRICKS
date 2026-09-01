# Defines the Terraform providers required by this project.
terraform {
  required_providers {
    databricks = {
      # Official Databricks Terraform provider.
      source = "databricks/databricks"

      # Uses Databricks provider version 1.128.x.
      version = "~> 1.128"
    }
  }
}

# Configures the Databricks provider for the PROD environment.
provider "databricks" {
  # Databricks workspace URL.
  host = var.databricks_host

  # Uses the PROD authentication profile from the Databricks CLI config.
  profile = "PROD"
}