locals {
  prefix = var.prefix == null ? "dbx-proxy-${random_string.this.result}" : "${var.prefix}-dbx-proxy-${random_string.this.result}"

  tags = merge(
    {
      "Component" = local.prefix
      "ManagedBy" = "terraform"
    },
    var.tags,
  )

  bootstrap_resource_group = var.deployment_mode == "bootstrap" && var.resource_group == null
  bootstrap_networking     = var.deployment_mode == "bootstrap" && (var.vnet_name == null && var.subnet_name == null)
  bootstrap_load_balancer  = var.deployment_mode == "bootstrap"

  resource_group = (
    local.bootstrap_resource_group
    ? azurerm_resource_group.this[0].name
    : data.azurerm_resource_group.this[0].name
  )

  subnet_name = module.networking.subnet_name
  subnet_id   = module.networking.subnet_id
  subnet_cidr = module.networking.subnet_cidr

  slb_backend_pool_id = module.load_balancer.slb_backend_pool_id
  slb_health_probe_id = module.load_balancer.slb_health_probe_id
}
