terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.21.1"
    }
  }
}

provider "azurerm" {
  features {}
  tenant_id = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = "Contentful"
  location = "uksouth"
}

variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "contentful_apikey" {
  type      = string
  sensitive = true
}

variable "contentful_space" {
  type      = string
  sensitive = true
}

resource "azurerm_container_group" "contentful-rg" {
  name                = "contentful-group"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = "dfecontentful"
  os_type             = "Linux"

  container {
    name   = "container"
    image  = "albal/contentful:latest"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      CONTENTFUL_APIKEY = var.contentful_apikey,
      CONTENTFUL_SPACE  = var.contentful_space
    }

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}
