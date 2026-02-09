resource "azurerm_lb" "this" {
  count = var.bootstrap_load_balancer ? 1 : 0

  name                = "${var.prefix}-slb"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${var.prefix}-slb-fip-${var.subnet_name}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = "${var.prefix}-slb-bp"
  loadbalancer_id = local.slb_id
}

resource "azurerm_lb_probe" "health" {
  name                = "dbx-proxy-probe-health"
  port                = var.dbx_proxy_health_port
  protocol            = "Http"
  request_path        = "/status"
  interval_in_seconds = 10
  number_of_probes    = 3
  loadbalancer_id     = local.slb_id
}

resource "azurerm_lb_rule" "health" {
  name                           = "${var.prefix}-r-health"
  protocol                       = "Tcp"
  frontend_port                  = var.dbx_proxy_health_port
  backend_port                   = var.dbx_proxy_health_port
  frontend_ip_configuration_name = local.slb_frontend_configuration_name
  loadbalancer_id                = local.slb_id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.health.id
}

resource "azurerm_lb_rule" "this" {
  for_each                       = { for l in var.dbx_proxy_listener : l.name => l }
  name                           = "${var.prefix}-r-${each.key}"
  protocol                       = "Tcp"
  frontend_port                  = each.value.port
  backend_port                   = each.value.port
  frontend_ip_configuration_name = local.slb_frontend_configuration_name
  loadbalancer_id                = local.slb_id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.health.id
}
