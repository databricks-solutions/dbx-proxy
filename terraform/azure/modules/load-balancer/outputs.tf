output "slb_name" {
  description = "Name of the Standard Load Balancer."
  value       = local.slb_name
}

output "slb_id" {
  description = "ID of the Standard Load Balancer."
  value       = local.slb_id
}

output "slb_backend_pool_id" {
  description = "ID of the Load Balancer backend pool."
  value       = azurerm_lb_backend_address_pool.this.id
}

output "slb_health_probe_id" {
  description = "ID of the health probe."
  value       = azurerm_lb_probe.health.id
}

output "private_link_service_id" {
  description = "ID of the Private Link Service if created; otherwise null."
  value       = length(azurerm_private_link_service.this) > 0 ? azurerm_private_link_service.this[0].id : null
}

output "private_link_service_alias" {
  description = "Alias of the Private Link Service if created; otherwise null."
  value       = length(azurerm_private_link_service.this) > 0 ? azurerm_private_link_service.this[0].alias : null
}
