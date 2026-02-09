variable "prefix" {
  description = "Prefix for all Azure resources created by this module."
  type        = string
}

variable "location" {
  description = "Azure region to deploy to."
  type        = string
}

variable "resource_group" {
  description = "Resource group name used for all Azure resources."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
}

variable "subnet_name" {
  description = "Subnet name for the VM scale set."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the VM scale set."
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR block used for Network Security Group ingress."
  type        = string
}

variable "slb_backend_pool_id" {
  description = "Load Balancer backend pool ID."
  type        = string
}

variable "slb_health_probe_id" {
  description = "Health probe ID used by the VM scale set."
  type        = string
}

variable "instance_type" {
  description = "Azure VM size for dbx-proxy instances."
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of dbx-proxy instances."
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of dbx-proxy instances."
  type        = number
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
  description = "Listener configuration used to build security rules."
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
