resource "azurerm_public_ip" "appgw_ip" {
  name                = "appgw-public-ip"
  location            = var.connections_resource_group_name.rg.location
  resource_group_name = var.connections_resource_group_name.rg.name
  allocation_method   = "static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-webapp"
  location            = azurerm_public_ip.rg.location
  resource_group_name = azurerm_public_ip.rg.name
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  backend_address_pool {
    name = "backendPool"
    backend_addresses {
      fqdn = azurerm_app_service.webapp.default_site_hostname
    }
  }

  backend_http_settings {
    name                  = "backendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                         = "httpListener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name           = "frontendPort"
    protocol                     = "Http"
  }

  request_routing_rule {
    name                         = "rule1"
    rule_type                    = "Basic"
    http_listener_name           = "httpListener"
    backend_address_pool_name    = "backendPool"
    backend_http_settings_name   = "backendHttpSettings"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "appgw-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}