resource "azurerm_private_link_service" "this" {
  count               = var.bootstrap_load_balancer ? 1 : 0
  name                = "${var.prefix}-pls"
  location            = var.location
  resource_group_name = var.resource_group

  load_balancer_frontend_ip_configuration_ids = local.slb_frontend_configuration_ids

  nat_ip_configuration {
    name                       = "${var.prefix}-pls-nat"
    primary                    = true
    subnet_id                  = var.subnet_id
    private_ip_address_version = "IPv4"
  }

  tags = var.tags
}
