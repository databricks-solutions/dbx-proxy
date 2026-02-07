output "vpc_id" {
  description = "VPC ID used by the deployment (created or existing)."
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block used by the deployment (created or existing)."
  value       = var.vpc_cidr
}

output "subnet_ids" {
  description = "Subnet IDs used by the deployment (created or existing)."
  value       = local.subnet_ids
}

output "subnet_cidrs" {
  description = "Subnet CIDR blocks used by the deployment (created or existing)."
  value       = local.subnet_cidrs
}

output "nat_subnet_id" {
  description = "NAT public subnet ID if created; otherwise null."
  value       = length(aws_subnet.public) > 0 ? aws_subnet.public[0].id : null
}

output "nat_subnet_cidr" {
  description = "NAT public subnet CIDR block if created; otherwise null."
  value       = length(aws_subnet.public) > 0 ? aws_subnet.public[0].cidr_block : null
}

output "internet_gateway_id" {
  description = "Internet Gateway ID if created; otherwise null."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "nat_gateway_id" {
  description = "NAT Gateway ID if created; otherwise null."
  value       = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
}
