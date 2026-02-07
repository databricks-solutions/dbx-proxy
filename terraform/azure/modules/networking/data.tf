data "azurerm_subnet" "this" {
  for_each             = { for idx, name in var.subnet_names : tostring(idx) => name }
  name                 = each.value
  resource_group_name  = var.resource_group
  virtual_network_name = var.vnet_name
}
