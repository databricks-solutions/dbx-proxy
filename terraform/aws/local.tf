locals {
  prefix = var.prefix == null ? "dbx-proxy-${random_string.this.result}" : "${var.prefix}-dbx-proxy-${random_string.this.result}"

  tags = merge(
    {
      "Component" = local.prefix
      "ManagedBy" = "terraform"
    },
    var.tags,
  )

  bootstrap_networking    = var.deployment_mode == "bootstrap" && (var.vpc_id == null && length(var.subnet_ids) == 0)
  bootstrap_load_balancer = var.deployment_mode == "bootstrap"

  vpc_id       = module.networking.vpc_id
  subnet_ids   = module.networking.subnet_ids
  subnet_cidrs = module.networking.subnet_cidrs

  nlb_target_group_arns = module.load_balancer.nlb_target_group_arns

}
