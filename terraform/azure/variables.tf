variable "prefix" {
  description = "Prefix for all Azure resources created by this module."
  type        = string
  default     = null
}

variable "location" {
  type        = string
  description = "Azure location to deploy to."
}

variable "resource_group" {
  type        = string
  description = "Resource group name. Required in proxy-only mode. If null in bootstrap mode, a new resource group is created."
  default     = null
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
    condition = var.deployment_mode != "bootstrap" || (
      (var.vnet_name != null && var.subnet_name != null) ||
      (var.vnet_name == null && var.subnet_cidr != null)
    )
    error_message = "bootstrap mode requires either vnet_name and subnet_name (to use existing networking) or vnet_cidr and subnet_cidr (to bootstrap networking)."
  }
  validation {
    condition     = var.deployment_mode != "proxy-only" || (var.vnet_name != null && var.subnet_name != null)
    error_message = "proxy-only mode requires vnet_name and subnet_name (to use existing networking)."
  }
  validation {
    condition     = var.deployment_mode != "proxy-only" || var.slb_name != null
    error_message = "proxy-only mode requires slb_name (to attach to an existing SLB)."
  }
  validation {
    condition     = var.deployment_mode != "proxy-only" || var.resource_group != null
    error_message = "proxy-only mode requires resource_group."
  }
}

variable "vnet_name" {
  description = "Name of existing VNet. If null in bootstrap mode, a new VNet is created."
  type        = string
  default     = null
  validation {
    condition     = var.vnet_name == null || var.subnet_name != null
    error_message = "When vnet_name is set, subnet_name must also be provided."
  }
}

variable "vnet_cidr" {
  description = "CIDR block for the VNet when bootstrapping."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_name" {
  description = "Name of existing subnet. If null in bootstrap mode, a new subnet is created."
  type        = string
  default     = null
}

variable "subnet_cidr" {
  description = "CIDR block for subnet when bootstrapping."
  type        = string
  default     = "10.0.1.0/24"
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for outbound internet connectivity when bootstrapping."
  type        = bool
  default     = true
}

variable "slb_name" {
  description = "Existing Standard Load Balancer name. Required in proxy-only mode."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Azure VM size for dbx-proxy instances."
  type        = string
  default     = "Standard_D2ps_v6"
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
  default     = "0.1.4"
}

variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check."
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
Each listener defines a frontend port and a set of routes with destinations.
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
  validation {
    condition     = alltrue([for listener in var.dbx_proxy_listener : listener.port != var.dbx_proxy_health_port])
    error_message = "dbx_proxy_health_port must not overlap with any dbx_proxy_listener port."
  }
}
