variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check (e.g. HAProxy or agent health endpoint)."
  type        = number
  default     = 8080
}

variable "dbx_proxy_listener" {
  description = <<EOT
Logical dbx-proxy listener configuration.

Each listener defines a frontend port and a set of routes with destinations.
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
}
