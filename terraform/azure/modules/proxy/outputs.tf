output "nsg_id" {
  description = "ID of the Network Security Group attached to dbx-proxy instances."
  value       = azurerm_network_security_group.this.id
}

output "vmss_name" {
  description = "Name of the VM scale set managing dbx-proxy instances."
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}

output "vmss_id" {
  description = "ID of the VM scale set managing dbx-proxy instances."
  value       = azurerm_linux_virtual_machine_scale_set.this.id
}

output "dbx_proxy_cfg" {
  description = "Rendered dbx-proxy config (dbx-proxy.cfg)."
  value       = module.common.dbx_proxy_cfg
}
