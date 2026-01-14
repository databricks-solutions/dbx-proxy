locals {
  dbx_proxy_cfg = templatefile("${path.module}/templates/dbx-proxy.cfg.tpl", {
    dbx_proxy_health_port = var.dbx_proxy_health_port
    dbx_proxy_listener    = var.dbx_proxy_listener
  })

  docker_compose_yaml = templatefile("${path.module}/templates/docker-compose.yaml.tpl", {
    dbx_proxy_image_version = var.dbx_proxy_image_version
    dbx_proxy_health_port   = var.dbx_proxy_health_port
  })
}
