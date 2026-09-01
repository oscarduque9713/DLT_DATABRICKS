variable "databricks_host" {
  description = "Databricks PROD workspace host"
  type        = string
}

variable "workspace_id" {
  description = "Databricks PROD workspace ID"
  type        = string
}

variable "catalog_name" {
  description = "Unity Catalog de PROD"
  type        = string
}

variable "deploy_principal" {
  description = "Application ID del service principal de GitHub PROD"
  type        = string
}

variable "catalog_storage_root" {
  description = "Managed storage location for PROD catalog"
  type        = string
}

variable "access_connector_id" {
  description = "Azure Databricks Access Connector resource ID"
  type        = string
}

variable "account_id" {
  description = "Databricks Account ID"
  type        = string
}

variable "terraform_principal" {
  description = "Service Principal used by Terraform to manage PROD infrastructure"
  type        = string
}

variable "warehouse_id" {
  description = "SQL Warehouse used by Terraform to execute SQL DDL in PROD"
  type        = string
}