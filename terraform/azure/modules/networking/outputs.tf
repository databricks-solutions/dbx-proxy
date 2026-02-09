output "vnet_name" {
  description = "VNet name used by the deployment (created or existing)."
  value       = local.vnet_name
}

output "vnet_cidr" {
  description = "VNet CIDR blocks used by the deployment (created or existing)."
  value       = var.vnet_cidr
}

output "subnet_name" {
  description = "Subnet name used by the deployment (created or existing)."
  value       = local.subnet_name
}

output "subnet_id" {
  description = "Subnet ID used by the deployment (created or existing)."
  value       = local.subnet_id
}

output "subnet_cidr" {
  description = "Subnet CIDR block used by the deployment (created or existing)."
  value       = local.subnet_cidr
}

output "nat_gateway_name" {
  description = "NAT Gateway name if created; otherwise null."
  value       = length(azurerm_nat_gateway.this) > 0 ? azurerm_nat_gateway.this[0].name : null
}

output "nat_gateway_id" {
  description = "NAT Gateway ID if created; otherwise null."
  value       = length(azurerm_nat_gateway.this) > 0 ? azurerm_nat_gateway.this[0].id : null
}
