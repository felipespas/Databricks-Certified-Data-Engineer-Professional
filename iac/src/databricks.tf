resource "azurerm_databricks_workspace" "this" {
  name                                  = var.workspace_name
  location                              = azurerm_resource_group.this.location
  resource_group_name                   = azurerm_resource_group.this.name
  managed_resource_group_name           = var.managed_resource_group_name
  sku                                   = var.sku
  infrastructure_encryption_enabled     = var.sku == "premium"
  public_network_access_enabled         = true
  network_security_group_rules_required = "AllRules"
  tags                                  = var.tags

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.this.id
    public_subnet_name                                   = azurerm_subnet.this["public"].name
    private_subnet_name                                  = azurerm_subnet.this["private"].name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.this["public"].id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.this["private"].id
  }

  depends_on = [
    azurerm_nat_gateway_public_ip_association.this,
    azurerm_subnet_nat_gateway_association.this,
  ]
}
