required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = ">= 3.22"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "Contentful"
  location = "uksouth"
}

resource "azurerm_container_group" "ntweekly" {
  name                = "ntweekly-group"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "public"
  dns_name_label      = "dfecontentful"
  os_type             = "Linux"

  container {
    name   = "container"
    image  = "albal/contentful:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}
