resource "random_string" "this" {
  special = false
  upper   = false
  length  = 10
}

resource "azurerm_resource_group" "this" {
  count    = local.bootstrap_resource_group ? 1 : 0
  name     = "${local.prefix}-rg"
  location = var.location

  tags = local.tags
}

module "networking" {
  source = "./modules/networking"

  bootstrap_networking = local.bootstrap_networking

  prefix         = local.prefix
  location       = var.location
  resource_group = local.resource_group
  tags           = local.tags

  vnet_name = var.vnet_name
  vnet_cidr = var.vnet_cidr

  subnet_names = var.subnet_names
  subnet_cidrs = var.subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
}

module "load_balancer" {
  source = "./modules/load-balancer"

  bootstrap_load_balancer = local.bootstrap_load_balancer

  prefix         = local.prefix
  location       = var.location
  resource_group = local.resource_group
  tags           = local.tags

  slb_name     = var.slb_name
  subnet_names = local.subnet_names
  subnet_ids   = local.subnet_ids

  dbx_proxy_health_port = var.dbx_proxy_health_port
  dbx_proxy_listener    = var.dbx_proxy_listener
}

module "proxy" {
  source = "./modules/proxy"

  prefix         = local.prefix
  location       = var.location
  resource_group = local.resource_group
  tags           = local.tags

  subnet_names        = local.subnet_names
  subnet_ids          = local.subnet_ids
  subnet_cidrs        = local.subnet_cidrs
  slb_backend_pool_id = local.slb_backend_pool_id
  slb_health_probe_id = local.slb_health_probe_id

  instance_type = var.instance_type
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  dbx_proxy_image_version   = var.dbx_proxy_image_version
  dbx_proxy_health_port     = var.dbx_proxy_health_port
  dbx_proxy_max_connections = var.dbx_proxy_max_connections
  dbx_proxy_listener        = var.dbx_proxy_listener
}
