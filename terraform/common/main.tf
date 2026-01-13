locals {
  dbx_proxy_listener_yaml = yamlencode({
    listeners = var.dbx_proxy_listener
  })

  docker_compose_yaml = templatefile("${path.module}/templates/docker-compose.yaml.tpl", {
    dbx_proxy_health_port                   = var.dbx_proxy_health_port
  })
}
