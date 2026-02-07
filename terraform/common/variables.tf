variable "dbx_proxy_image_version" {
  description = "Docker image version for dbx-proxy."
  type        = string
  validation {
    condition = (
      var.dbx_proxy_image_version == "latest"
      || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.dbx_proxy_image_version))
      || can(regex("^[0-9a-f]{7,40}$", lower(var.dbx_proxy_image_version)))
    )
    error_message = "dbx_proxy_image_version must be a real image tag: semver (e.g., 0.1.1), (short)git hash, or \"latest\"."
  }
}

variable "dbx_proxy_health_port" {
  description = "Port on which the dbx-proxy instances expose a TCP health check (e.g. HAProxy or agent health endpoint)."
  type        = number
}

variable "dbx_proxy_max_connections" {
  description = "HAProxy maxconn (optional override)."
  type        = number
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
}
