resource "azurerm_virtual_network" "this" {
  count = var.bootstrap_networking ? 1 : 0

  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  count = var.bootstrap_networking ? 1 : 0

  name                 = "${var.prefix}-sn"
  resource_group_name  = var.resource_group
  virtual_network_name = local.vnet_name
  address_prefixes     = [var.subnet_cidr]
  private_link_service_network_policies_enabled = false

}
