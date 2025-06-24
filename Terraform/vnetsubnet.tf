# Create a Virtual Network for the Application Gateway
resource "azurerm_virtual_network" "appgw_vnet" {
  name                = "appgw-vnet-${var.environment}" # Naming convention with environment for clarity
  address_space       = ["192.0.0.0/16"]                   # VNet address space updated to /16 to accommodate broader subnets
  location            = var.location                       # Location now comes from a variable
  resource_group_name = var.connections_resource_group_name          # Resource group name now comes from a variable
}

# Create a dedicated subnet for the Application Gateway within the VNet
# Application Gateways require a dedicated subnet.
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet-${var.environment}" # Naming convention with environment for clarity
  resource_group_name  = azurerm_virtual_network.appgw_vnet.resource_group_name          # Resource group name now comes from a variable
  virtual_network_name = azurerm_virtual_network.appgw_vnet.name
  address_prefixes     = ["192.0.1.0/28"]                     # Subnet address updated to provide ~64 addresses (more than 40)
}
