module "common" {
  source = "../../../common"

  dbx_proxy_image_version   = var.dbx_proxy_image_version
  dbx_proxy_health_port     = var.dbx_proxy_health_port
  dbx_proxy_listener        = var.dbx_proxy_listener
  dbx_proxy_max_connections = local.dbx_proxy_max_connections
}
