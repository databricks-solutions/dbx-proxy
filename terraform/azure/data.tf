data "azurerm_resource_group" "this" {
  count = local.bootstrap_resource_group ? 0 : 1
  name  = var.resource_group
}
