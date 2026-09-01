terraform {
  backend "azurerm" {
    resource_group_name  = "az-services-0013"
    storage_account_name = "stterraform0013"
    container_name       = "tfstate"
    key                  = "databricks/prod/terraform.tfstate"
  }
}