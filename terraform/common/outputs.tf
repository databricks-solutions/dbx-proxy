output "dbx_proxy_cfg" {
  description = "Rendered dbx-proxy config (dbx-proxy.cfg) derived from dbx_proxy_listener."
  value       = local.dbx_proxy_cfg
}

output "docker_compose" {
  description = "Rendered docker-compose.yaml for dbx-proxy."
  value       = local.docker_compose_yaml
}
