locals {

  nlb_arn      = var.bootstrap_load_balancer ? aws_lb.this[0].arn : data.aws_lb.this[0].arn
  nlb_dns_name = var.bootstrap_load_balancer ? aws_lb.this[0].dns_name : data.aws_lb.this[0].dns_name

  nlb_security_group_ids = var.bootstrap_load_balancer ? aws_lb.this[0].security_groups : data.aws_lb.this[0].security_groups


  nlb_ports_for_egress_rules = concat(
    [for l in var.dbx_proxy_listener : { port = l.port, description = "Databricks to NLB to dbx-proxy listener ${l.name}" }],
    [{ port = var.dbx_proxy_health_port, description = "Databricks to NLB to dbx-proxy health check" }],
  )

  nlb_sg_egress_rules = length(local.nlb_security_group_ids) > 0 ? [
    for pair in setproduct(local.nlb_security_group_ids, local.nlb_ports_for_egress_rules, var.subnet_cidrs) : {
      security_group_id = pair[0]
      description       = pair[1].description
      port              = pair[1].port
      cidr              = pair[2]
    }
  ] : []

  allowed_principals = [
    "arn:aws:iam::565502421330:role/private-connectivity-role-${var.region}"
  ]

}
