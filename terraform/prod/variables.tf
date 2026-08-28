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