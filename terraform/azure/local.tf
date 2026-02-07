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
  bootstrap_networking     = var.deployment_mode == "bootstrap" && (var.vnet_name == null && length(var.subnet_names) == 0)
  bootstrap_load_balancer  = var.deployment_mode == "bootstrap"

  resource_group = (
    local.bootstrap_resource_group
    ? azurerm_resource_group.this[0].name
    : data.azurerm_resource_group.this[0].name
  )

  subnet_names = module.networking.subnet_names
  subnet_ids   = module.networking.subnet_ids
  subnet_cidrs = module.networking.subnet_cidrs

  slb_backend_pool_id = module.load_balancer.slb_backend_pool_id
  slb_health_probe_id = module.load_balancer.slb_health_probe_id
}
