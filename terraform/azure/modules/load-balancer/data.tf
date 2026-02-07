data "azurerm_lb" "this" {
  count               = var.bootstrap_load_balancer == false ? 1 : 0
  name                = var.slb_name
  resource_group_name = var.resource_group
}
