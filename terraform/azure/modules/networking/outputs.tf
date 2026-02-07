output "vnet_name" {
  description = "VNet name used by the deployment (created or existing)."
  value       = local.vnet_name
}

output "vnet_cidr" {
  description = "VNet CIDR blocks used by the deployment (created or existing)."
  value       = var.vnet_cidr
}

output "subnet_names" {
  description = "Subnet names used by the deployment (created or existing)."
  value       = local.subnet_names
}

output "subnet_ids" {
  description = "Subnet IDs used by the deployment (created or existing)."
  value       = local.subnet_ids
}

output "subnet_cidrs" {
  description = "Subnet CIDR blocks used by the deployment (created or existing)."
  value       = local.subnet_cidrs
}

output "nat_gateway_name" {
  description = "NAT Gateway name if created; otherwise null."
  value       = length(azurerm_nat_gateway.this) > 0 ? azurerm_nat_gateway.this[0].name : null
}

output "nat_gateway_id" {
  description = "NAT Gateway ID if created; otherwise null."
  value       = length(azurerm_nat_gateway.this) > 0 ? azurerm_nat_gateway.this[0].id : null
}
