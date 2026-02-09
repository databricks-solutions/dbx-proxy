# SSH key for VMSS admin (not exposed; instances are managed via cloud-init only)
resource "tls_private_key" "vmss-admin" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  dynamic "security_rule" {
    for_each = { for idx, l in var.dbx_proxy_listener : idx => l }
    content {
      name                         = "inbound-${security_rule.value.name}"
      description                  = "Databricks to SLB to dbx-proxy listener ${security_rule.value.name}"
      priority                     = 1001 + security_rule.key
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      destination_port_range       = tostring(security_rule.value.port)
      source_address_prefix        = var.subnet_cidr
      destination_address_prefix   = var.subnet_cidr
    }
  }

  security_rule {
    name                         = "inbound-health-check"
    description                  = "Databricks to SLB to dbx-proxy health check"
    priority                     = 1000
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = tostring(var.dbx_proxy_health_port)
    source_address_prefix        = "AzureLoadBalancer"
    destination_address_prefix   = var.subnet_cidr
  }

  security_rule {
    name                         = "allow-egress"
    description                  = "Allow all egress for dbx-proxy instances"
    priority                     = 1000
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = var.subnet_cidr
    destination_address_prefixes = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                 = "${var.prefix}-vmss"
  location             = var.location
  resource_group_name  = var.resource_group
  sku                  = var.instance_type
  instances            = var.min_capacity
  computer_name_prefix = "${var.prefix}-vm-"

  admin_username                  = "dbxproxyadmin"
  disable_password_authentication = true
  custom_data                     = data.cloudinit_config.this.rendered
  health_probe_id                 = var.slb_health_probe_id
  zone_balance                    = true
  zones                           = [for map in data.azurerm_location.current.zone_mappings : map["logical_zone"]]

  admin_ssh_key {
    username   = "dbxproxyadmin"
    public_key = tls_private_key.vmss-admin.public_key_openssh
  }

  # Rolling upgrade policy (similar to AWS ASG instance_refresh)
  upgrade_mode = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = var.max_capacity == 1 ? 100 : 50
    max_unhealthy_instance_percent          = var.max_capacity == 1 ? 100 : 50
    max_unhealthy_upgraded_instance_percent = var.max_capacity == 1 ? 100 : 50
    pause_time_between_batches              = "PT1M"
    cross_zone_upgrades_enabled             = false
    prioritize_unhealthy_instances_enabled  = true
  }

  automatic_instance_repair {
    action       = "Replace"
    enabled      = true
    grace_period = "PT10M"
  }

  scale_in {
    force_deletion_enabled = true
    rule                   = "Default"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server-arm64"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name                      = "${var.prefix}-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.this.id

    ip_configuration {
      name                                   = "${var.prefix}-ipc-${var.subnet_name}"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.slb_backend_pool_id]
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "${var.prefix}-vmss-as"
  location            = var.location
  resource_group_name = var.resource_group
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id
  enabled             = true

  profile {
    name = "defaultProfile"

    capacity {
      default = var.max_capacity
      minimum = var.min_capacity
      maximum = var.max_capacity
    }
  }

  tags = var.tags
}
