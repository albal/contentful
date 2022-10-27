resource "azurerm_network_security_group" "nsg" {
  name                = "s185d01-chidrens-social-care-cpd-sn01-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
}


resource "azurerm_network_security_rule" "nsg-rule-01" {
  name                        = "Allow-Al"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "86.10.229.100"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# resource "azurerm_network_security_rule" "nsg-rule-02" {
#   name                        = "AllowVnetInBound"
#   priority                    = 3650
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "VirtualNetwork"
#   destination_address_prefix  = "VirtualNetwork"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.nsg.name
# }

resource "azurerm_network_security_rule" "nsg-rule-03" {
  name                         = "AllowAzureLoadBalancerInBound"
  priority                     = 3651
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "*"
  source_port_range            = "*"
  destination_port_range       = "65200-65535"
  source_address_prefix        = "*"
  destination_address_prefixes = azurerm_subnet.frontend.address_prefixes
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.nsg.name
}

# resource "azurerm_network_security_rule" "nsg-rule-04" {
#   name                        = "DenyAllInBound"
#   priority                    = 3655
#   direction                   = "Inbound"
#   access                      = "Deny"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.nsg.name
# }

# resource "azurerm_network_security_rule" "nsg-rule-05" {
#   name                        = "AllowVnetOutBound"
#   priority                    = 3650
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "VirtualNetwork"
#   destination_address_prefix  = "VirtualNetwork"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.nsg.name
# }

# resource "azurerm_network_security_rule" "nsg-rule-06" {
#   name                        = "AllowAzureInternetOutBound"
#   priority                    = 3651
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "Internet"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.nsg.name
# }

# resource "azurerm_network_security_rule" "nsg-rule-07" {
#   name                        = "DenyAllOutBound"
#   priority                    = 3655
#   direction                   = "Outbound"
#   access                      = "Deny"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.nsg.name
# }