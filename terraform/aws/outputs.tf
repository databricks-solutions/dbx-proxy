output "networking" {
  description = "All networking outputs: vpc_id, subnet_ids, subnet_cidrs, internet_gateway_id, nat_gateway_id, nat_subnet_id, nat_subnet_cidr."
  value = {
    vpc_id              = module.networking.vpc_id
    vpc_cidr            = module.networking.vpc_cidr
    subnet_ids          = module.networking.subnet_ids
    subnet_cidrs        = module.networking.subnet_cidrs
    nat_gateway_id      = module.networking.nat_gateway_id
    nat_subnet_id       = module.networking.nat_subnet_id
    nat_subnet_cidr     = module.networking.nat_subnet_cidr
    internet_gateway_id = module.networking.internet_gateway_id
  }
}

output "load_balancer" {
  description = "All load balancer outputs: nlb_arn, nlb_dns_name, nlb_target_group_arns, vpc_endpoint_service_arn, vpc_endpoint_service_name."
  value = {
    nlb_arn                   = module.load_balancer.nlb_arn
    nlb_dns_name              = module.load_balancer.nlb_dns_name
    nlb_target_group_arns     = module.load_balancer.nlb_target_group_arns
    nlb_security_group_ids    = module.load_balancer.nlb_security_group_ids
    vpc_endpoint_service_arn  = module.load_balancer.vpc_endpoint_service_arn
    vpc_endpoint_service_name = module.load_balancer.vpc_endpoint_service_name
  }
}

output "proxy" {
  description = "All proxy outputs: iam_role_name, iam_role_arn, instance_profile_name, instance_profile_arn, security_group_id, autoscaling_group_name, launch_template_name, dbx_proxy_cfg."
  value = {
    iam_role_name          = module.proxy.iam_role_name
    iam_role_arn           = module.proxy.iam_role_arn
    instance_profile_name  = module.proxy.instance_profile_name
    instance_profile_arn   = module.proxy.instance_profile_arn
    security_group_id      = module.proxy.security_group_id
    autoscaling_group_name = module.proxy.autoscaling_group_name
    launch_template_name   = module.proxy.launch_template_name
    dbx_proxy_cfg          = module.proxy.dbx_proxy_cfg
  }
}
