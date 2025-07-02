provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics Workspace for Application Insights
# This resource group and workspace name were hardcoded in the ARM template.
# Consider making these dynamic or ensuring they exist if they are truly external.
resource "azurerm_resource_group" "app_insights_workspace_rg" {
  name     = var.app_insights_workspace_resource_group
  location = var.app_insights_location
  # lifecycle {
  #   ignore_changes = all # Uncomment if this RG is managed outside this Terraform config
  # }
}

resource "azurerm_log_analytics_workspace" "app_insights_workspace" {
  name                = var.app_insights_workspace_name
  location            = azurerm_resource_group.app_insights_workspace_rg.location
  resource_group_name = azurerm_resource_group.app_insights_workspace_rg.name
  sku                 = "PerGB2018" # Default SKU for new workspaces
  retention_in_days   = 30

  depends_on = [azurerm_resource_group.app_insights_workspace_rg]
}

# Application Insights Component
resource "azurerm_application_insights" "main" {
  name                = var.app_service_name
  location            = var.app_insights_location # Using the app insights location as per template
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.app_insights_workspace.id

  tags = {
    "Created By" = "Scott Patterson"
    "Service"    = "Ctaxrebate"
  }

  depends_on = [
    azurerm_log_analytics_workspace.app_insights_workspace,
    azurerm_resource_group.main
  ]
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.hosting_plan_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Windows" # Based on 'dotnet' currentStack and 'netFrameworkVersion'
  sku_name            = var.sku_code

  tags = {
    "Created By" = "Scott Patterson"
    "Service"    = "Ctaxrebate"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet for App Service (hardcoded in ARM template as 'subnet-cptejnku')
resource "azurerm_subnet" "app_service_subnet" {
  name                 = var.app_service_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"] # This address prefix was hardcoded in the ARM template's nested deployment for this subnet.

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverfarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  depends_on = [azurerm_virtual_network.main]
}

# Subnet for PostgreSQL Flexible Server (Delegated Subnet)
resource "azurerm_subnet" "postgresql_subnet" {
  name                 = var.outbound_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.outbound_subnet_address_prefix]

  delegation {
    name = "dlg-database"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  depends_on = [azurerm_virtual_network.main]
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql_private_dns_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
  tags = var.postgresql_server_tags # Reusing tags from server, if specific tags are needed for DNS zone, add a variable
}

# Virtual Network Link for Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_private_dns_link" {
  name                  = var.virtual_link_name
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql_private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  depends_on = [
    azurerm_private_dns_zone.postgresql_private_dns_zone,
    azurerm_virtual_network.main
  ]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                     = var.postgresql_server_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  version                  = "12" # Hardcoded in ARM template
  administrator_login      = var.postgresql_admin_username
  administrator_password   = var.postgresql_admin_password
  sku_name                 = var.postgresql_database_sku
  tier                     = var.postgresql_database_tier
  storage_mb               = 131072 # Hardcoded in ARM template (128GB)
  backup_retention_days    = 7      # Hardcoded in ARM template
  geo_redundant_backup_enabled = false # Hardcoded in ARM template "Disabled"
  zone                     = ""     # Hardcoded in ARM template empty string, means not specified
  public_network_access_enabled = false # Hardcoded in ARM template "Disabled"
  high_availability_enabled     = false # Hardcoded in ARM template "Disabled"

  delegated_subnet_id = azurerm_subnet.postgresql_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql_private_dns_zone.id

  tags = var.postgresql_server_tags

  depends_on = [
    azurerm_subnet.postgresql_subnet,
    azurerm_private_dns_zone_virtual_network_link.postgresql_private_dns_link # Link must be established
  ]
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name                = var.postgresql_database_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_flexible_server.main.name
  charset             = "utf8"       # Hardcoded in ARM template
  collation           = "en_US.utf8" # Hardcoded in ARM template

  tags = var.postgresql_database_tags

  depends_on = [azurerm_postgresql_flexible_server.main]
}

# App Service
resource "azurerm_windows_web_app" "main" {
  name                = var.app_service_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  client_affinity_enabled = true # From ARM template
  public_network_access_enabled = false # From ARM template "Disabled"
  virtual_network_subnet_id = azurerm_subnet.app_service_subnet.id
  vnet_route_all_enabled = true # From ARM template
  auto_generate_slot {
    name_scope = var.auto_generated_domain_name_label_scope
  }

  site_config {
    always_on              = var.always_on
    php_version            = var.php_version
    dotnet_framework_version = var.net_framework_version # For .NET applications
    ftps_state             = var.ftps_state
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~2"
    "XDT_MicrosoftApplicationInsights_Mode" = "default"
    "CURRENT_STACK" = var.current_stack
    "AZURE_POSTGRESQL_CONNECTIONSTRING" = "Database=${var.postgresql_database_name};Server=${var.postgresql_server_name}.postgres.database.azure.com;User Id=${var.postgresql_admin_username};Password=${var.postgresql_admin_password}"
  }

  tags = {
    "Created By" = "Scott Patterson"
    "Service"    = "Ctaxrebate"
  }

  depends_on = [
    azurerm_application_insights.main,
    azurerm_service_plan.main,
    azurerm_subnet.app_service_subnet,
    azurerm_postgresql_flexible_server_database.main # Ensure database is ready for connection string
  ]
}

# Disabling SCM (Kudu) and FTP basic publishing credentials
# Note: These are nested resources under Microsoft.Web/sites in ARM,
# but in Terraform, they are often managed directly via the parent resource
# or through a separate resource if the provider supports it.
# The azurerm_windows_web_app resource has properties for this.

# The ARM template had 'Microsoft.Security/pricings' which is for Azure Security Center.
# This is usually a subscription-level or management group-level setting
# and is often configured outside individual resource deployments.
# If you need this to be part of this deployment, you'd define:
resource "azurerm_security_center_subscription_pricing" "app_services_pricing" {
  tier        = "Standard"
  resource_type = "AppServices" # Correct resource_type for App Services in Security Center
  # scope is usually subscription ID implicitly or explicitly for non-resource-type pricings
  depends_on = [azurerm_resource_group.main] # Ensure the main RG is created before setting subscription-level pricing.
}