resource "azurerm_databricks_access_connector" "storage" {
  name                = "${var.workspace_name}-storage-connector"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "databricks_storage" {
  scope                = azurerm_storage_container.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.storage.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "databricks_storage_delegator" {
  scope                = azapi_resource.data_storage.id
  role_definition_name = "Storage Blob Delegator"
  principal_id         = azurerm_databricks_access_connector.storage.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "storage_data_access" {
  for_each = var.storage_data_access_principal_ids

  scope                = azurerm_storage_container.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}
