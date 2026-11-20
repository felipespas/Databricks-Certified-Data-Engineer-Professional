output "workspace_id" {
  description = "Azure resource ID of the Databricks workspace."
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_url" {
  description = "HTTPS URL of the Databricks workspace."
  value       = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "resource_group_name" {
  description = "Resource group containing the workspace and injected VNet."
  value       = azurerm_resource_group.this.name
}

output "managed_resource_group_id" {
  description = "Separate resource group managed by the Databricks service."
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}

output "virtual_network_id" {
  description = "Azure resource ID of the injected VNet."
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Public/host and private/container subnet IDs."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "outbound_public_ip" {
  description = "Static public IP used only for outbound connectivity through the NAT Gateway."
  value       = azurerm_public_ip.nat.ip_address
}

output "storage_account_name" {
  description = "ADLS Gen2 data account name, including its persistent random suffix."
  value       = azapi_resource.data_storage.name
}

output "storage_account_id" {
  description = "Azure resource ID of the data account, separate from Databricks-managed storage."
  value       = azapi_resource.data_storage.id
}

output "storage_abfss_url" {
  description = "Data container URL to use when configuring a Unity Catalog external location."
  value       = "abfss://${azurerm_storage_container.data.name}@${azapi_resource.data_storage.name}.dfs.core.windows.net/"
}

output "storage_access_connector_id" {
  description = "Access Connector ID to use when configuring the Unity Catalog storage credential."
  value       = azurerm_databricks_access_connector.storage.id
}

output "storage_perimeter_id" {
  description = "Network Security Perimeter controlling public access to the data account."
  value       = azurerm_network_security_perimeter.storage.id
}
