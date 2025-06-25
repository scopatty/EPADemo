# main.tf - Terraform configuration for Azure Council Tax Rebate Platform

# Configure the AzureRM Provider
# Ensure you are logged into Azure CLI with 'az login' and have selected the correct subscription
# Set environment variables for Azure authentication for CI/CD:
# AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
# Alternatively, for local development, 'az login' is sufficient.
provider "azurerm" {
  features {}
}

# Generate a random suffix for globally unique resources
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

# --- Resource Group ---
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# --- Networking ---

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.resource_group_name}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Application Subnet
resource "azurerm_subnet" "app" {
  name                 = "snet-app-tier"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.app_subnet_address_prefix]

  # This is crucial for App Service VNet Integration
  # Ensure the service endpoint is enabled for SQL if not using Private Link (less secure, not recommended)
  # For Private Link, no service endpoints are needed on the subnet.
  # We will use Private Link for Azure SQL for higher security.
}

# Database Subnet
resource "azurerm_subnet" "db" {
  name                 = "snet-db-tier"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.db_subnet_address_prefix]

  # Delegation for Private Link Service, if needed for other services.
  # For Azure SQL Private Link, no specific delegation on the subnet is needed.
}

# Bastion Host Subnet (for secure admin access, if needed)
# Not strictly required for the web app to function, but good for admin
resource "azurerm_subnet" "bastion" {
  name                 = "snet-bastion-host"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_address_prefix]
}

# Network Security Group for Application Subnet
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-app-tier"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Rule: Allow inbound HTTPS from internet (or specific WAF/Front Door IPs)
resource "azurerm_network_security_rule" "allow_https_inbound" {
  name                        = "AllowHTTPSInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*" # For public access, restrict to WAF/Front Door IPs in production
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

# Rule: Allow outbound to SQL Database Subnet (Port 1433)
resource "azurerm_network_security_rule" "allow_sql_outbound" {
  name                        = "AllowSQLOutbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = azurerm_subnet.app.address_prefixes[0]
  destination_address_prefix  = azurerm_subnet.db.address_prefixes[0]
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

# Network Security Group for Database Subnet
resource "azurerm_network_security_group" "db_nsg" {
  name                = "nsg-db-tier"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_association" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# Rule: Allow inbound SQL from Application Subnet ONLY
resource "azurerm_network_security_rule" "allow_sql_inbound_from_app" {
  name                        = "AllowSQLFromApp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = azurerm_subnet.app.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

# --- Azure SQL Database ---

# SQL Server
resource "azurerm_sql_server" "main" {
  name                         = "${var.sql_server_name}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0" # Use a compatible version, e.g., 12.0 for SQL Database
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2" # Enforce TLS 1.2+ for security

  # For security, disable public network access and rely on Private Link
  public_network_access_enabled = false
}

# Private Endpoint for Azure SQL Server (highly recommended for security)
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "pe-sql-${azurerm_sql_server.main.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.db.id # Connects to the database subnet

  private_service_connection {
    name                           = "psc-sql-${azurerm_sql_server.main.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_sql_server.main.id
    subresource_names              = ["sqlServer"]
  }
}

# Private DNS Zone for Azure SQL (allows private IP resolution via FQDN)
resource "azurerm_private_dns_zone" "sql_private_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_vnet_link" {
  name                  = "link-to-${azurerm_virtual_network.main.name}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_dns_a_record" "sql_private_dns_a_record" {
  name                = azurerm_sql_server.main.name
  zone_name           = azurerm_private_dns_zone.sql_private_dns_zone.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql_private_endpoint.private_service_connection[0].private_ip_address]
}


# SQL Database
resource "azurerm_sql_database" "main" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_name         = azurerm_sql_server.main.name
  sku_name            = "S0" # Basic SKU for development/testing. Consider higher (e.g., GP_Gen5_2) for production.
  collation           = "SQL_Latin1_General_CP1_CI_AS"

  # Enable SQL Auditing (highly recommended for sensitive data)
  # Requires a Storage Account or Log Analytics Workspace
  lifecycle {
    ignore_changes = [
      extended_auditing_policy,
    ]
  }
}


# --- Azure Key Vault ---

resource "azurerm_key_vault" "main" {
  name                        = "${var.key_vault_name}-${random_string.suffix.result}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true # Recommended for critical secrets

  # Network ACLs for Key Vault (restrict access to VNet)
  # For the project, you might start with public access allowed for easier CI/CD setup,
  # but for production, restrict to your VNet via private endpoint or service endpoints.
  network_acls {
    default_action = "Deny" # Deny all by default
    bypass         = "AzureServices" # Allow Azure services like App Service
    virtual_network_subnet_ids = [
        azurerm_subnet.app.id, # Allow App Service subnet
        azurerm_subnet.bastion.id # Allow Bastion subnet for admin access
    ]
    ip_rules = [] # Add specific trusted public IPs if needed for CI/CD agents or dev machines not in VNet
  }
}

data "azurerm_client_config" "current" {}

# Store SQL Admin Password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password_secret" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain" # Or a more specific type
}

# Store SQL Admin Username in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_username_secret" {
  name         = "sql-admin-username"
  value        = var.sql_admin_username
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"
}

# --- Azure App Service ---

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux" # Or "Windows" if using .NET Framework etc.
  sku_name            = "P1v2"  # Production tier for VNet integration, deployment slots, auto-scaling
}

# Web App
resource "azurerm_linux_web_app" "main" {
  name                = var.web_app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  # Enable Managed Identity for the Web App to access Key Vault and SQL DB
  identity {
    type = "SystemAssigned"
  }

  site_config {
    linux_fx_version = "PYTHON|3.9" # Or your chosen runtime (e.g., "DOTNETCORE|6.0")
    scm_type         = "VSTS"       # For Azure DevOps deployments
    always_on        = true         # Keep app warm for faster responses
    ftps_state       = "Disabled"   # Disable FTP for security
    min_tls_version  = "1.2"        # Enforce TLS 1.2+
  }

  # VNet Integration for secure communication with SQL DB (via Private Link)
  # This makes the App Service inject network interfaces into the app subnet
  virtual_network_native_ip_enabled = true # Required for VNet integration
  virtual_network_subnet_id         = azurerm_subnet.app.id

  # Application Settings (will inject as environment variables into the app)
  # Reference Key Vault secrets using Managed Identity
  app_settings = {
    # SQL Connection String (retrieve from Key Vault using Managed Identity)
    # The format will depend on your chosen database driver (e.g., pyodbc)
    # Example using SQL Server
    "DB_CONNECTION_STRING" = "Server=tcp:${azurerm_sql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_sql_database.main.name};UID=${azurerm_key_vault_secret.sql_admin_username_secret.value};PWD=${azurerm_key_vault_secret.sql_admin_password_secret.value};Encrypt=True;Connection Timeout=30;"
    # Alternatively, for production, refer to Key Vault directly like this:
    # "DB_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/sql-connection-string/)"
    # Where 'sql-connection-string' is another secret you create in KV with the full connection string.
    # This requires granting the App Service's Managed Identity 'Get' permission on the secret.
    "PYTHON_VERSION"       = "3.9" # Required for some Python setups on App Service
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true" # Ensure build during deployment for Python
    "FLASK_APP"            = "app.py" # For Flask applications
    "FLASK_ENV"            = "production" # Set to production for security

    # Ensure HTTPS is enforced by the app itself as well, or use Azure Front Door / Application Gateway
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false" # Use this for ephemeral storage, better for stateless apps

    # Example: App setting for sensitive data encryption key (if using app-level encryption)
    # "APP_ENCRYPTION_KEY" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.id}/secrets/app-encryption-key/)"
  }

  # HTTPS Only
  https_only = true

  # Set up a staging deployment slot
  site_config {
    linux_fx_version = "PYTHON|3.9"
    scm_type         = "VSTS"
    always_on        = true
    ftps_state       = "Disabled"
    min_tls_version  = "1.2"
  }
}

# Grant Web App Managed Identity 'Get' permissions on Key Vault secrets
resource "azurerm_key_vault_access_policy" "webapp_secret_policy" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = azurerm_linux_web_app.main.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.main.identity[0].principal_id

  secret_permissions = [
    "Get",
  ]
}

# --- Monitoring & Logging ---

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "logws-${var.resource_group_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.web_app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
}

# Diagnostic settings for Web App to send logs to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "web_app_diagnostics" {
  name                       = "web-app-diagnostics"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log {
    category = "AppServiceHTTPLogs"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServiceConsoleLogs"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServiceAppLogs"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
}

# Diagnostic settings for SQL Database to send logs to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "sql_db_diagnostics" {
  name                       = "sql-db-diagnostics"
  target_resource_id         = azurerm_sql_database.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log {
    category = "SQLInsights"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AutomaticTuning"
    enabled = true
    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
}

# --- Outputs (for easy access to deployed resource info) ---

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "web_app_default_hostname" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "sql_server_fqdn" {
  value = azurerm_sql_server.main.fully_qualified_domain_name
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "app_service_plan_id" {
  value = azurerm_service_plan.main.id
}

output "web_app_id" {
  value = azurerm_linux_web_app.main.id
}
