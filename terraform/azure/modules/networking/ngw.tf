resource "azurerm_public_ip" "this" {
  count               = var.bootstrap_networking && var.enable_nat_gateway ? 1 : 0
  name                = "${var.prefix}-nat-pip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count               = var.bootstrap_networking && var.enable_nat_gateway ? 1 : 0
  name                = "${var.prefix}-nat"
  location            = var.location
  resource_group_name = var.resource_group
  sku_name            = "Standard"

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count                = var.bootstrap_networking && var.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.this[0].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each       = var.bootstrap_networking && var.enable_nat_gateway ? { for id in local.subnet_ids : id => id } : {}
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}
