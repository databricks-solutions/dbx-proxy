resource "random_string" "this" {
  special = false
  upper   = false
  length  = 10
}

module "networking" {
  source = "./modules/networking"

  bootstrap_networking  = local.bootstrap_networking

  prefix                = local.prefix
  tags                  = local.tags

  vpc_id                = var.vpc_id
  vpc_cidr              = var.vpc_cidr

  subnet_ids            = var.subnet_ids
  subnet_cidrs          = var.subnet_cidrs

  nat_subnet_cidr       = var.nat_subnet_cidr
  enable_nat_gateway    = var.enable_nat_gateway

}

module "load_balancer" {
  source = "./modules/load-balancer"

  bootstrap_load_balancer = local.bootstrap_load_balancer

  prefix                  = local.prefix
  region                  = var.region
  tags                    = local.tags

  nlb_arn                 = var.nlb_arn

  vpc_id                  = local.vpc_id
  subnet_ids              = local.subnet_ids
  subnet_cidrs            = local.subnet_cidrs

  dbx_proxy_health_port   = var.dbx_proxy_health_port
  dbx_proxy_listener      = var.dbx_proxy_listener

}

module "proxy" {
  source = "./modules/proxy"

  prefix                    = local.prefix
  tags                      = local.tags

  vpc_id                    = local.vpc_id
  subnet_ids                = local.subnet_ids
  subnet_cidrs              = local.subnet_cidrs

  instance_type             = var.instance_type
  min_capacity              = var.min_capacity
  max_capacity              = var.max_capacity
  nlb_target_group_arns     = local.nlb_target_group_arns

  dbx_proxy_image_version   = var.dbx_proxy_image_version
  dbx_proxy_health_port     = var.dbx_proxy_health_port
  dbx_proxy_max_connections = var.dbx_proxy_max_connections
  dbx_proxy_listener        = var.dbx_proxy_listener

}
