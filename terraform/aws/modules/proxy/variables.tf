variable "prefix" {
  description = "Prefix for all AWS resources created by this module."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID where the dbx-proxy instances run."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the Auto Scaling Group."
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "Subnet CIDR blocks used for security group ingress."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for dbx-proxy instances. Must be a Graviton (arm64) type unless ami_id overrides the default arm64 AMI."
  type        = string
}

variable "ami_id" {
  description = "AMI ID for dbx-proxy instances. When null, the latest Amazon Linux 2023 arm64 AMI is resolved from SSM. Set this to pin a specific image, e.g. a hardened/CIS golden AMI (must match instance_type's architecture)."
  type        = string
  default     = null
}

variable "max_instance_lifetime" {
  description = "Maximum lifetime, in seconds, of dbx-proxy instances before the Auto Scaling group replaces them (rolling onto the current AMI). 0 disables age-based replacement. AWS requires 0 or a value between 86400 (1 day) and 31536000 (1 year)."
  type        = number
  default     = 0

  validation {
    condition     = var.max_instance_lifetime == 0 || (var.max_instance_lifetime >= 86400 && var.max_instance_lifetime <= 31536000)
    error_message = "max_instance_lifetime must be 0 (disabled) or between 86400 and 31536000 seconds."
  }
}

variable "min_capacity" {
  description = "Minimum number of dbx-proxy instances."
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of dbx-proxy instances."
  type        = number
}

variable "nlb_target_group_arns" {
  description = "NLB target group ARNs keyed by listener name."
  type        = map(string)
}

variable "dbx_proxy_image_version" {
  description = "Docker image version for dbx-proxy."
  type        = string
}

variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check."
  type        = number
}

variable "dbx_proxy_max_connections" {
  description = "Override dbx-proxy maxconn (default derived from instance_type)."
  type        = number
}

variable "dbx_proxy_listener" {
  description = "Listener configuration used to build security group ingress rules."
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
