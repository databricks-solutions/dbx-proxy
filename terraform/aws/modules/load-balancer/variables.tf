variable "prefix" {
  description = "Prefix for all AWS resources created by this module."
  type        = string
}

variable "region" {
  description = "The AWS region to deploy to."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
}

variable "bootstrap_load_balancer" {
  description = "Whether to create a new NLB and PrivateLink endpoint service."
  type        = bool
}

variable "nlb_arn" {
  description = "Existing NLB ARN to attach listeners/target groups to when not creating a new NLB."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC hosting the NLB target groups."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the NLB when creating a new one."
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "Subnet CIDR blocks used for NLB security group egress rules."
  type        = list(string)
}

variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check."
  type        = number
}

variable "dbx_proxy_listener" {
  description = "Listener configuration used to build NLB target groups and listeners."
  type = list(object({
    name = string
    mode = string # "tcp" or "http"
    port = number
    routes = list(object({
      name    = string
      domains = list(string)
      destinations = list(object({
        name = string
        host = string
        port = number
      }))
    }))
  }))
}
