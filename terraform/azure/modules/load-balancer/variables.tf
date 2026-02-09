variable "prefix" {
  description = "Prefix for all Azure resources created by this module."
  type        = string
}

variable "location" {
  description = "Azure region to deploy to."
  type        = string
}

variable "resource_group" {
  description = "Resource group name."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
}

variable "bootstrap_load_balancer" {
  description = "Whether to create a new StandardLoad Balancer and Private Link Service."
  type        = bool
}

variable "slb_name" {
  description = "Existing Standard Load Balancer name. Used when not bootstrapping."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the Load Balancer frontend and Private Link Service."
  type        = string
}

variable "subnet_name" {
  description = "Subnet name for the Load Balancer frontend and Private Link Service."
  type        = string
}

variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check."
  type        = number
}

variable "dbx_proxy_listener" {
  description = "Listener configuration used to build Load Balancer rules."
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
