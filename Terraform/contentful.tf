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
  name     = "s185d01-devcontentful-rg"
  location = "westeurope"
  tags = {
    "Environment"  = "dev",
    "Portfolio"    = "Digital and Technology",
    "Service Line" = "Childrens Social Care Improvement and Learning",
    "Service"      = "Azure Platform"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "s185d01VNet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.21.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "s185d01AGSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.21.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "s185d01BackendSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.21.1.0/24"]
}

resource "azurerm_public_ip" "pip1" {
  name                = "s185d01AGPublicIPAddress"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_service_plan" "service-plan" {
  name                = "s185d01ServicePlan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "linux-web-app" {
  name                = "s185d01Linux-Web-App"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.service-plan.id

  app_settings = {
    CONTENTFUL_SPACE = var.contentful_space
    CONTENTFUL_APIKEY = var.contentful_apikey
  }

  site_config {
    ip_restriction {
      name       = "AGW-PIP"
      ip_address = "${azurerm_public_ip.pip1.ip_address}/32"
      priority   = 1000
      action     = "Allow"
    }

    ip_restriction {
      name                      = "AGW-Subnet"
      virtual_network_subnet_id = azurerm_subnet.frontend.id      
      priority                  = 2000
      action                    = "Allow"
    }

    ip_restriction {
      name       = "BlockAll"
      ip_address = "0.0.0.0/0"
      priority   = 3000
      action     = "Deny"
    }

    application_stack {
      docker_image     = "albal/contentful"
      docker_image_tag = "latest"
    }
  }
}

resource "azurerm_application_gateway" "network" {
  name                = "s185d01AppGateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "s185d01-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip1.id
  }

  backend_address_pool {
    name  = var.backend_address_pool_name
    fqdns = [azurerm_linux_web_app.linux-web-app.default_hostname]
  }

  backend_http_settings {
    name                                = var.http_setting_name
    pick_host_name_from_backend_address = true
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    priority                   = 2000
    http_listener_name         = var.listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = var.http_setting_name
  }

  probe {
    name                                      = "s185d01AGProbe"
    pick_host_name_from_backend_http_settings = true
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    protocol                                  = "Http"
  }

  tags = azurerm_resource_group.rg.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "s185d01nic-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "s185d01nic-ipconfig-1"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc01" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "s185d01nic-ipconfig-1"
  backend_address_pool_id = tolist(azurerm_application_gateway.network.backend_address_pool).0.id
}

output "public_ip_address" {
  value = azurerm_public_ip.pip1.*.ip_address
}