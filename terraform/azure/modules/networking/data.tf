data "azurerm_subnet" "this" {
  count                = var.bootstrap_networking ? 0 : 1
  name                 = var.subnet_name
  resource_group_name  = var.resource_group
  virtual_network_name = var.vnet_name
}
