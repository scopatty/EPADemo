# variables.tf

variable "subscription_id" {
  description = "The Azure Subscription ID."
  type        = string
  default     = "9bc0a274-11f2-44a8-b46b-319480e1d929"
}

variable "resource_group_name" {
  description = "The name of the resource group where resources will be deployed."
  type        = string
  default     = "rg-uks-webapps"
}

variable "app_service_name" {
  description = "The name of the App Service."
  type        = string
  default     = "web-app-ctaxrebate"
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "uksouth" # Converted from 'UK South' to a valid Terraform location
}

variable "hosting_plan_name" {
  description = "The name of the App Service Plan."
  type        = string
  default     = "ASP-rgukswebapps-8d41"
}

variable "server_farm_resource_group" {
  description = "The resource group name of the server farm (App Service Plan)."
  type        = string
  default     = "rg-uks-webapps"
}

variable "always_on" {
  description = "Specifies if the App Service should be always on."
  type        = bool
  default     = false
}

variable "ftps_state" {
  description = "State of FTP/FTPS for the App Service. Possible values are FtpsOnly and Disabled."
  type        = string
  default     = "FtpsOnly"
}

variable "auto_generated_domain_name_label_scope" {
  description = "The scope of auto generated domain name label."
  type        = string
  default     = "TenantReuse"
}

variable "sku" {
  description = "The SKU tier of the App Service Plan (e.g., Basic, Standard, PremiumV2)."
  type        = string
  default     = "Basic"
}

variable "sku_code" {
  description = "The SKU name of the App Service Plan (e.g., B1, S1, P1v2)."
  type        = string
  default     = "B1"
}

variable "worker_size" {
  description = "The worker size (e.g., Small, Medium, Large)."
  type        = string
  default     = "0" # Corresponds to Sku.Capacity for B1
}

variable "worker_size_id" {
  description = "The worker size ID."
  type        = string
  default     = "0" # Corresponds to Sku.Capacity for B1
}

variable "number_of_workers" {
  description = "The number of workers in the App Service Plan."
  type        = string
  default     = "1"
}

variable "current_stack" {
  description = "The current stack for the App Service (e.g., dotnet, php, node)."
  type        = string
  default     = "dotnet"
}

variable "php_version" {
  description = "The PHP version for the App Service (e.g., 7.4, 8.0, OFF)."
  type        = string
  default     = "OFF"
}

variable "net_framework_version" {
  description = "The .NET Framework version for the App Service (e.g., v4.0, v6.0, v8.0)."
  type        = string
  default     = "v8.0"
}

variable "postgresql_server_name" {
  description = "The name of the PostgreSQL Flexible Server."
  type        = string
  default     = "web-app-ctaxrebate-server"
}

variable "postgresql_database_name" {
  description = "The name of the PostgreSQL database."
  type        = string
  default     = "web-app-ctaxrebate-database"
}

variable "postgresql_database_sku" {
  description = "The SKU name for the PostgreSQL Flexible Server (e.g., Standard_D2s_v3)."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "postgresql_database_tier" {
  description = "The SKU tier for the PostgreSQL Flexible Server (e.g., Burstable, GeneralPurpose, MemoryOptimized)."
  type        = string
  default     = "GeneralPurpose"
}

variable "postgresql_admin_username" {
  description = "The administrator username for the PostgreSQL Flexible Server."
  type        = string
  default     = "yjtrnqzhrn"
}

variable "postgresql_admin_password" {
  description = "The administrator password for the PostgreSQL Flexible Server."
  type        = string
  # NOTE: The ARM parameter file had a 'null' value for the password.
  # Terraform requires a non-null string for securestring.
  # You MUST provide a secure password here, ideally from a secure source like Azure Key Vault.
  # For demonstration, a placeholder is used. Replace this with a real, secure value.
  sensitive = true
  default   = "StrongPassword!123" # <<< IMPORTANT: CHANGE THIS TO A SECURE PASSWORD
}

variable "postgresql_server_tags" {
  description = "Tags for the PostgreSQL Flexible Server."
  type        = map(string)
  default = {
    "Created By" = "Scott Patterson"
    "Service"    = "Ctaxrebate"
  }
}

variable "postgresql_database_tags" {
  description = "Tags for the PostgreSQL database."
  type        = map(string)
  default = {
    "Created By" = "Scott Patterson"
    "Service"    = "Ctaxrebate"
  }
}

variable "outbound_subnet_address_prefix" {
  description = "The address prefix for the outbound subnet (for PostgreSQL delegation)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
  default     = "vnet-ctaxrebate"
}

variable "private_dns_zone_name" {
  description = "The name of the private DNS zone for PostgreSQL."
  type        = string
  default     = "privatelink.postgres.database.azure.com"
}

variable "site_config_name" {
  description = "The name used for the site config resource (connection strings)."
  type        = string
  default     = "connectionstrings"
}

# Variables for hardcoded values in the ARM template (e.g., specific resource group for workspace)
variable "app_insights_workspace_resource_group" {
  description = "Resource Group for the Application Insights Log Analytics Workspace."
  type        = string
  default     = "DefaultResourceGroup-SUK"
}

variable "app_insights_workspace_name" {
  description = "Name of the Application Insights Log Analytics Workspace."
  type        = string
  default     = "DefaultWorkspace-9bc0a274-11f2-44a8-b46b-319480e1d929-SUK"
}

variable "app_insights_location" {
  description = "Location for Application Insights and its associated Log Analytics Workspace."
  type        = string
  default     = "uksouth"
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_service_subnet_name" {
  description = "The name of the subnet delegated to App Service. Note: This was hardcoded in the template."
  type        = string
  default     = "subnet-cptejnku"
}

variable "outbound_subnet_name" {
  description = "The name of the outbound subnet (for PostgreSQL delegation)."
  type        = string
  default     = "subnet-${resource_group_name}" # This was dynamically generated in the ARM template with uniqueString(deployment().name) but for clarity using RG name
}

variable "virtual_link_name" {
  description = "The name of the virtual network link for the private DNS zone."
  type        = string
  default     = "link-${resource_group_name}" # This was dynamically generated in the ARM template with uniqueString(deployment().name) but for clarity using RG name
}