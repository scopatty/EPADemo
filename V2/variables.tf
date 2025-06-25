# variables.tf - Terraform variables for Azure Council Tax Rebate Platform

# --- Variables ---
# Define variables for customization
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-rebate-devops-project"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "uksouth" # Chosen for UK context
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "asp-rebate-project"
}

variable "web_app_name" {
  description = "Name of the Web App"
  type        = string
  default     = "webapp-rebate-app"
}

variable "sql_server_name" {
  description = "Name of the Azure SQL Server (must be globally unique)"
  type        = string
  default     = "sqlserver-rebate-db-proj" # Append a random suffix for uniqueness
}

variable "sql_database_name" {
  description = "Name of the Azure SQL Database"
  type        = string
  default     = "sqldb-rebate-data"
}

variable "sql_admin_username" {
  description = "SQL Server Administrator Username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server Administrator Password"
  type        = string
  # IMPORTANT: In a real-world scenario, this should be retrieved from a secure vault (e.g., Azure Key Vault)
  # and never hardcoded in Terraform files, especially if committed to source control.
  # For this project, we'll generate it and store it in Key Vault.
  sensitive   = true # Mark as sensitive to prevent output in logs
  default     = "ComplexP@ssw0rd123!" # Replace with a strong password or generate
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault (must be globally unique)"
  type        = string
  default     = "kv-rebate-project-secure" # Append a random suffix for uniqueness
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_subnet_address_prefix" {
  description = "Address prefix for the application subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_subnet_address_prefix" {
  description = "Address prefix for the database subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "bastion_subnet_address_prefix" {
  description = "Address prefix for the bastion host subnet"
  type        = string
  default     = "10.0.3.0/24"
}
