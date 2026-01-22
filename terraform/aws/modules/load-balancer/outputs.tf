output "nlb_arn" {
  description = "ARN of the Network Load Balancer."
  value       = local.nlb_arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer."
  value       = local.nlb_dns_name
}

output "nlb_target_group_arns" {
  description = "ARNs of the NLB target groups, keyed by listener name (plus health when created)."
  value = merge(
    { for name, tg in aws_lb_target_group.this : name => tg.arn },
    { health = aws_lb_target_group.health.arn },
  )
}

output "nlb_security_group_ids" {
  description = "Security group IDs attached to the NLB (if any)."
  value       = tolist(local.nlb_security_group_ids)
}

output "vpc_endpoint_service_arn" {
  description = "ARN of the VPC endpoint service if created; otherwise null."
  value       = length(aws_vpc_endpoint_service.this) > 0 ? aws_vpc_endpoint_service.this[0].arn : null
}

output "vpc_endpoint_service_name" {
  description = "Service name for PrivateLink if created; otherwise null."
  value       = length(aws_vpc_endpoint_service.this) > 0 ? aws_vpc_endpoint_service.this[0].service_name : null
}
