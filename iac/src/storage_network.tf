resource "azurerm_subnet" "storage_private_endpoints" {
  name                              = "${var.workspace_name}-storage-private-endpoints"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [var.storage_private_endpoint_subnet_prefix]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_dns_zone" "storage" {
  for_each = toset(["blob", "dfs"])

  name                = "privatelink.${each.key}.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  for_each = azurerm_private_dns_zone.storage

  name                  = "${var.workspace_name}-${each.key}-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "storage" {
  for_each = azurerm_private_dns_zone.storage

  name                = "${var.workspace_name}-storage-${each.key}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.storage_private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.workspace_name}-storage-${each.key}"
    private_connection_resource_id = azapi_resource.data_storage.id
    subresource_names              = [each.key]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage"
    private_dns_zone_ids = [each.value.id]
  }
}
