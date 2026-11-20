resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.virtual_network_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnet_address_prefixes

  name                            = "${var.workspace_name}-${each.key}"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [each.value]
  default_outbound_access_enabled = false

  delegation {
    name = "databricks"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# Databricks manages the required NSG rules through subnet delegation.
resource "azurerm_network_security_group" "this" {
  for_each = var.subnet_address_prefixes

  name                = "${var.workspace_name}-${each.key}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_address_prefixes

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
