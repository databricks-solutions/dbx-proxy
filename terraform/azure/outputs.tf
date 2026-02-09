output "resource_group" {
  description = "Resource group name used by the deployment."
  value       = local.resource_group
}

output "networking" {
  description = "All networking outputs: vnet_name, vnet_cidr, subnet_name, subnet_id, subnet_cidr, nat_gateway_name, nat_gateway_id."
  value = {
    vnet_name        = module.networking.vnet_name
    vnet_cidr        = module.networking.vnet_cidr
    subnet_name      = module.networking.subnet_name
    subnet_id        = module.networking.subnet_id
    subnet_cidr      = module.networking.subnet_cidr
    nat_gateway_name = module.networking.nat_gateway_name
    nat_gateway_id   = module.networking.nat_gateway_id
  }
}

output "load_balancer" {
  description = "All load balancer outputs: slb_name, slb_id, slb_backend_pool_id, private_link_service_id, private_link_service_alias."
  value = {
    slb_name                   = module.load_balancer.slb_name
    slb_id                     = module.load_balancer.slb_id
    slb_backend_pool_id        = module.load_balancer.slb_backend_pool_id
    private_link_service_id    = module.load_balancer.private_link_service_id
    private_link_service_alias = module.load_balancer.private_link_service_alias
  }
}

output "proxy" {
  description = "All proxy outputs: nsg_id, vmss_name, vmss_id, dbx_proxy_cfg."
  value = {
    nsg_id        = module.proxy.nsg_id
    vmss_name     = module.proxy.vmss_name
    vmss_id       = module.proxy.vmss_id
    dbx_proxy_cfg = module.proxy.dbx_proxy_cfg
  }
}
