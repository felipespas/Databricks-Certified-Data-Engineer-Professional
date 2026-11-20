resource "azurerm_network_security_perimeter" "storage" {
  name                = "${var.workspace_name}-storage-nsp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_network_security_perimeter_profile" "storage" {
  name                          = "data"
  network_security_perimeter_id = azurerm_network_security_perimeter.storage.id
}

resource "azurerm_network_security_perimeter_access_rule" "storage_public" {
  name                                  = "allow-configured-public-cidrs"
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.storage.id
  direction                             = "Inbound"
  address_prefixes                      = var.storage_perimeter_allowed_cidrs
}

resource "azurerm_network_security_perimeter_association" "storage" {
  name                                  = "${var.workspace_name}-storage"
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.storage.id
  resource_id                           = azapi_resource.data_storage.id
  access_mode                           = "Enforced"

  depends_on = [azurerm_network_security_perimeter_access_rule.storage_public]
}
