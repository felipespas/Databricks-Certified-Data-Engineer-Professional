resource "random_string" "storage_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# AzureRM's boolean public access setting cannot express SecuredByPerimeter.
resource "azapi_resource" "data_storage" {
  type      = "Microsoft.Storage/storageAccounts@2025-01-01"
  name      = "${var.storage_account_name_prefix}${random_string.storage_suffix.result}"
  parent_id = azurerm_resource_group.this.id
  location  = azurerm_resource_group.this.location
  tags      = var.tags

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_${var.storage_replication_type}"
    }
    properties = {
      accessTier                   = "Hot"
      isHnsEnabled                 = true
      allowBlobPublicAccess        = false
      allowSharedKeyAccess         = false
      defaultToOAuthAuthentication = true
      supportsHttpsTrafficOnly     = true
      minimumTlsVersion            = "TLS1_2"
      publicNetworkAccess          = "SecuredByPerimeter"
      networkAcls = {
        defaultAction = "Deny"
        bypass        = "None"
      }
    }
  }
}

resource "azurerm_storage_container" "data" {
  name                  = var.storage_container_name
  storage_account_id    = azapi_resource.data_storage.id
  container_access_type = "private"
}
