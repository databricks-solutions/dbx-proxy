locals {
  slb_name                    = var.bootstrap_load_balancer ? azurerm_lb.this[0].name : data.azurerm_lb.this[0].name
  slb_id                      = var.bootstrap_load_balancer ? azurerm_lb.this[0].id : data.azurerm_lb.this[0].id
  slb_frontend_configurations = var.bootstrap_load_balancer ? azurerm_lb.this[0].frontend_ip_configuration : data.azurerm_lb.this[0].frontend_ip_configuration

  # List of all frontend IPs (for Private Link Service)
  slb_frontend_configuration_ids = local.slb_frontend_configurations[*].id

  # First frontend IP (for LB rules - rules need a single frontend)
  slb_frontend_configuration_name = local.slb_frontend_configurations[0].name
}
