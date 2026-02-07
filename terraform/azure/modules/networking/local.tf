locals {
  vnet_name    = var.bootstrap_networking ? azurerm_virtual_network.this[0].name : var.vnet_name
  subnet_names = length(var.subnet_names) > 0 ? var.subnet_names : [for s in azurerm_subnet.this : s.name]
  subnet_ids   = length(var.subnet_names) > 0 ? [for s in values(data.azurerm_subnet.this) : s.id] : [for s in azurerm_subnet.this : s.id]
  subnet_cidrs = length(var.subnet_names) > 0 ? [for s in values(data.azurerm_subnet.this) : s.address_prefixes[0]] : [for s in azurerm_subnet.this : s.address_prefixes[0]]

}
