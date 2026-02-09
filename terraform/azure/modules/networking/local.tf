locals {
  vnet_name   = var.bootstrap_networking ? azurerm_virtual_network.this[0].name : var.vnet_name
  subnet_name = var.bootstrap_networking ? azurerm_subnet.this[0].name : var.subnet_name
  subnet_id   = var.bootstrap_networking ? azurerm_subnet.this[0].id : data.azurerm_subnet.this[0].id
  subnet_cidr = var.bootstrap_networking ? azurerm_subnet.this[0].address_prefixes[0] : data.azurerm_subnet.this[0].address_prefixes[0]

}
