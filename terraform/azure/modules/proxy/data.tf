data "azurerm_location" "current" {
  location = var.location
}

data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "#cloud-config\n${yamlencode(local.cloud_config)}"
  }
}
