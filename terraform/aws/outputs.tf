output "nlb_arn" {
  description = "ARN of the Network Load Balancer fronting the dbx-proxy instances."
  value       = aws_lb.this.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer."
  value       = aws_lb.this.dns_name
}

output "nlb_zone_id" {
  description = "Route 53 hosted zone ID for aliasing to the NLB."
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "ARNs of the NLB target groups, keyed by listener port."
  value       = { for port, tg in aws_lb_target_group.this : port => tg.arn }
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group managing dbx-proxy instances."
  value       = aws_autoscaling_group.this.name
}

output "security_group_id" {
  description = "ID of the security group attached to dbx-proxy instances."
  value       = aws_security_group.this.id
}

output "vpc_endpoint_service_name" {
  description = "Service name to be used by Databricks (or other consumers) when creating PrivateLink endpoints."
  value       = aws_vpc_endpoint_service.this.service_name
}

output "vpc_endpoint_service_arn" {
  description = "ARN of the VPC endpoint service."
  value       = aws_vpc_endpoint_service.this.arn
}
