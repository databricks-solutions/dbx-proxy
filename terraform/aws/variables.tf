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

variable "vpc_id" {
  description = "ID of the VPC in which to deploy the dbx-proxy instances. If null, a new VPC will be created."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC when creating one automatically."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the dbx-proxy instances and NLB (spread across AZs for HA). If empty, new subnets will be created."
  type        = list(string)
  default     = []
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets when creating them automatically."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet used by the NAT gateway when creating a VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "enable_nat_gateway" {
  description = "Whether to create an Internet Gateway and NAT Gateway for outbound internet connectivity when creating a new VPC."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type for dbx-proxy nodes."
  type        = string
  default     = "t3.medium"
}

variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check (e.g. HAProxy or agent health endpoint)."
  type        = number
  default     = 8080
}

variable "dbx_proxy_listener" {
  description = <<EOT
Logical dbx-proxy listener configuration.

This structure mirrors the ProxyConfig used by the agent and the config.yaml
used by the dbxp CLI. Each listener defines a frontend port and a set of
routes with destinations.
EOT
  type = list(object({
    name   = string
    mode   = string         # "tcp" or "http"
    port   = number
    routes = list(object({
      name         = string
      domains      = list(string)
      destinations = list(object({
        name = string
        host = string
        port = number
      }))
    }))
  }))
  default = []
}
