provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.application_resource_group_name
  location = var.location
}

resource "azurerm_app_service_plan" "asp" {
  name                = "asp-free-tier"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = "webapp-free-tier"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id
}