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
  name     = "s185d01-childrens-social-care-rg"
  location = "westeurope"
  tags = {
    "Environment"      = "Dev",
    "Parent Business"  = "Children’s Care",
    "Service Offering" = "Social Workforce",
    "Portfolio"        = "Vulnerable Children and Families",
    "Service Line"     = "Children and Social care",
    "Service"          = "Children and Social care",
    "Product"          = "Social Workforce"
  }
}