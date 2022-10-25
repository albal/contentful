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
    "Environment"  = "Dev",
    "Portfolio"    = "Children’s and families",
    "Service Line" = "Childrens Social Care Improvement and Learning",
    "Service"      = "Social Worker Career Progression"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "s185d01-chidrens-social-care-cpd-vn01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  tags                = azurerm_resource_group.rg.tags
}

resource "azurerm_subnet" "frontend" {
  name                 = "s185d01-chidrens-social-care-cpd-sn01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_subnet" "backend" {
  name                 = "s185d01-chidrens-social-care-cpd-sn02"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.128/26"]
}

resource "azurerm_public_ip" "pip1" {
  name                = "s185d01AGPublicIPAddress"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = azurerm_resource_group.rg.tags
}

resource "azurerm_service_plan" "service-plan" {
  name                = "s185d01-chidrens-social-care-cpd-app-service-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = azurerm_resource_group.rg.tags
}

resource "azurerm_linux_web_app" "linux-web-app" {
  name                = "s185d01-chidrens-social-care-cpd-app-service"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.service-plan.id

  app_settings = {
    CONTENTFUL_SPACE  = var.contentful_space
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
      name       = "s185d01-c-s-c-cpd-02-nsg"
      ip_address = "0.0.0.0/0"
      priority   = 3000
      action     = "Deny"
    }

    application_stack {
      docker_image     = "nginx"
      docker_image_tag = "latest"
    }
  }

  tags = azurerm_resource_group.rg.tags
}

#resource "azurerm_web_application_firewall_policy" "appfirewall" {
#  name                = "s185d01AllowOnlyKnownIPs"
#  resource_group_name = azurerm_resource_group.rg.name
#  location            = azurerm_resource_group.rg.location
#
#  custom_rules {
#    name      = "AllowKnownIPs"
#    priority  = 1
#    rule_type = "MatchRule"
#
#    match_conditions {
#      match_variables {
#        variable_name = "RemoteAddr"
#      }
#      operator           = "IPMatch"
#      negation_condition = false
#      match_values       = ["0.0.0.0/0"]
#    }
#    action = "Block"
#  }
#
#  custom_rules {
#    name      = "BlockAnythingElse"
#    priority  = 2
#    rule_type = "MatchRule"
#
#    match_conditions {
#      match_variables {
#        variable_name = "RemoteAddr"
#      }
#      operator           = "IPMatch"
#      negation_condition = false
#      match_values       = ["0.0.0.0"]
#    }
#    action = "Block"
#  }
#
#  policy_settings {
#    enabled = true
#    mode    = "Detection"
#    # Global parameters
#    request_body_check          = true
#    max_request_body_size_in_kb = 128
#    file_upload_limit_in_mb     = 100
#  }
#
#  managed_rules {
#    managed_rule_set {
#      type    = "OWASP"
#      version = "3.1"
#    }
#  }
#}

resource "azurerm_application_gateway" "appgw" {
  name                = "s185d01-chidrens-social-care-cpd-app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  #  firewall_policy_id = azurerm_web_application_firewall_policy.appfirewall.id

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

  depends_on = [
    azurerm_network_security_group.nsg,
    azurerm_subnet_network_security_group_association.blockall
  ]
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

  tags = azurerm_resource_group.rg.tags
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc01" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "s185d01nic-ipconfig-1"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgw.backend_address_pool).0.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "s185d01-chidrens-social-care-cpd-sn01-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-Al"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "86.10.229.100"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "GatewayBackEndHealthInBound"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVnetInBound"
    priority                   = 3650
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerInBound"
    priority                   = 3651
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInBound"
    priority                   = 3655
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # security_rule {
  #   name                       = "AllowVnetOutBound"
  #   priority                   = 3650
  #   direction                  = "Outbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "VirtualNetwork"
  #   destination_address_prefix = "VirtualNetwork"
  # }

  # security_rule {
  #   name                       = "AllowAzureInternetOutBound"
  #   priority                   = 3651
  #   direction                  = "Outbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "Internet"
  # }

  # security_rule {
  #   name                       = "DenyAllOutBound"
  #   priority                   = 3655
  #   direction                  = "Outbound"
  #   access                     = "Deny"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }

  tags = azurerm_resource_group.rg.tags
}

resource "azurerm_subnet_network_security_group_association" "blockall" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

output "public_ip_address" {
  value = azurerm_public_ip.pip1.*.ip_address
}