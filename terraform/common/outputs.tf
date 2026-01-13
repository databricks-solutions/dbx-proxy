output "dbx_proxy_listener" {
  description = "Rendered listener.yaml content."
  value       = local.dbx_proxy_listener_yaml
}

output "docker_compose" {
  description = "Rendered docker-compose.yaml for dbx-proxy."
  value       = local.docker_compose_yaml
}
