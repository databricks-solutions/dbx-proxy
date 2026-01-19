variable "prefix" {
  description = "Prefix for all AWS resources created by this module."
  type        = string
  default     = null
}

variable "region" {
  type        = string
  description = "The AWS region to deploy to"
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "deployment_mode" {
  description = "Deployment mode: bootstrap or proxy-only."
  type        = string
  default     = "bootstrap"
  validation {
    condition     = contains(["bootstrap", "proxy-only"], var.deployment_mode)
    error_message = "deployment_mode must be one of: 'bootstrap', 'proxy-only'."
  }
  validation {
    condition     = var.deployment_mode != "bootstrap" || (
      (var.vpc_id != null && length(var.subnet_ids) > 0) ||
      (var.vpc_id == null && length(var.subnet_cidrs) > 0)
    )
    error_message = "bootstrap mode requires either vpc_id and subnet_ids (to use existing networking) or vpc_cidr and subnet_cidrs (to bootstrap networking)."
  }
  validation {
    condition     = var.deployment_mode != "proxy-only" || (var.vpc_id != null && length(var.subnet_ids) > 0)
    error_message = "proxy-only mode requires vpc_id and subnet_ids (to use existing networking)."
  }
  validation {
    condition     = var.deployment_mode != "proxy-only" || var.nlb_arn != null
    error_message = "proxy-only mode requires nlb_arn (to attach listeners/target groups to an existing NLB)."
  }
}

variable "vpc_id" {
  description = "ID of the VPC in which to deploy the dbx-proxy instances. If null, a new VPC will be bootstrapped."
  type        = string
  default     = null
  validation {
    condition     = var.vpc_id != null || length(var.subnet_ids) == 0
    error_message = "When vpc_id is set, subnet_ids must also be provided."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC when bootstrapping a VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the dbx-proxy instance and NLB. If empty, new subnets will be created."
  type        = list(string)
  default     = []
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets when bootstrapping a VPC."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "nat_subnet_cidr" {
  description = "CIDR block for the public subnet used by the NAT gateway when creating a VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "enable_nat_gateway" {
  description = "Whether to create an Internet Gateway and NAT Gateway for outbound internet connectivity when creating a new VPC."
  type        = bool
  default     = true
}

variable "nlb_arn" {
  description = "Existing Network Load Balancer ARN to attach listeners/target groups to in proxy-only mode."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for dbx-proxy instances."
  type        = string
  default     = "t4g.medium"
}

variable "min_capacity" {
  description = "Minimum number of dbx-proxy instances."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of dbx-proxy instances."
  type        = number
  default     = 1
}

variable "dbx_proxy_image_version" {
  description = "Docker image version for dbx-proxy."
  type        = string
  default     = "0.1.1"
}

variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check (e.g. HAProxy or agent health endpoint)."
  type        = number
  default     = 8080
}

variable "dbx_proxy_max_connections" {
  description = "Override dbx-proxy maxconn (default derived from instance_type)."
  type        = number
  default     = null
}

variable "dbx_proxy_listener" {
  description = <<EOT
Logical dbx-proxy listener configuration.

This structure mirrors the ProxyConfig used by the agent and the config.yaml
used by the dbxp CLI. Each listener defines a frontend port and a set of
routes with destinations.
EOT
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
  default = []
}
