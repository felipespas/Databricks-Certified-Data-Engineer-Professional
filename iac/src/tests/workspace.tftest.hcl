mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev"
    }
  }

  mock_resource "azurerm_storage_container" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Storage/storageAccounts/stdatabricksdevabc123/blobServices/default/containers/data"
    }
  }

  mock_resource "azurerm_databricks_access_connector" {
    defaults = {
      identity = {
        principal_id = "11111111-1111-1111-1111-111111111111"
        tenant_id    = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }

  mock_resource "azurerm_network_security_perimeter" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/networkSecurityPerimeters/databricks-dev-storage-nsp"
    }
  }

  mock_resource "azurerm_network_security_perimeter_profile" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/networkSecurityPerimeters/databricks-dev-storage-nsp/profiles/data"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/virtualNetworks/databricks-dev-vnet"
    }
  }

  override_resource {
    target = azurerm_subnet.storage_private_endpoints
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/virtualNetworks/databricks-dev-vnet/subnets/databricks-dev-storage-private-endpoints"
    }
  }

  mock_resource "azurerm_nat_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/natGateways/databricks-dev-nat"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/publicIPAddresses/databricks-dev-nat-pip"
      ip_address = "203.0.113.10"
    }
  }
}

mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Storage/storageAccounts/stdatabricksdevabc123"
    }
  }
}

mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "abc123"
    }
  }
}

override_resource {
  target = azurerm_subnet.this["public"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/virtualNetworks/databricks-dev-vnet/subnets/databricks-dev-public"
  }
}

override_resource {
  target = azurerm_subnet.this["private"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/virtualNetworks/databricks-dev-vnet/subnets/databricks-dev-private"
  }
}

override_resource {
  target = azurerm_network_security_group.this["public"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/networkSecurityGroups/databricks-dev-public-nsg"
  }
}

override_resource {
  target = azurerm_network_security_group.this["private"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/networkSecurityGroups/databricks-dev-private-nsg"
  }
}

override_resource {
  target = azurerm_subnet_network_security_group_association.this["public"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/virtualNetworks/databricks-dev-vnet/subnets/databricks-dev-public"
  }
}

override_resource {
  target = azurerm_subnet_network_security_group_association.this["private"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azure-databricks-dev/providers/Microsoft.Network/virtualNetworks/databricks-dev-vnet/subnets/databricks-dev-private"
  }
}

variables {
  subscription_id               = "00000000-0000-0000-0000-000000000000"
  location                      = "westus"
  workspace_name                = "databricks-dev"
  resource_group_name           = "azure-databricks-dev"
  managed_resource_group_name   = "azure-databricks-dev-managed"
  virtual_network_name          = "databricks-dev-vnet"
  sku                           = "premium"
  virtual_network_address_space = "10.42.0.0/16"
  subnet_address_prefixes = {
    public  = "10.42.1.0/24"
    private = "10.42.2.0/24"
  }
  nat_idle_timeout_in_minutes = 10
  public_ip_tags = {
    FirstPartyUsage = "/Unprivileged"
  }
  storage_account_name_prefix            = "stdatabricksdev"
  storage_container_name                 = "data"
  storage_replication_type               = "LRS"
  storage_private_endpoint_subnet_prefix = "10.42.3.0/24"
  storage_perimeter_allowed_cidrs        = ["0.0.0.0/0"]
  storage_data_access_principal_ids      = []
  tags = {
    environment  = "dev"
    workload     = "databricks"
    "managed-by" = "terraform"
  }
}

run "development_workspace" {
  command = plan

  assert {
    condition = (
      azurerm_databricks_workspace.this.name == "databricks-dev" &&
      azurerm_databricks_workspace.this.resource_group_name == "azure-databricks-dev" &&
      azurerm_databricks_workspace.this.location == "westus" &&
      azurerm_databricks_workspace.this.sku == "premium" &&
      azurerm_virtual_network.this.name == "databricks-dev-vnet" &&
      azurerm_virtual_network.this.resource_group_name == azurerm_resource_group.this.name &&
      azurerm_virtual_network.this.location == azurerm_databricks_workspace.this.location &&
      azurerm_databricks_workspace.this.managed_resource_group_name != azurerm_resource_group.this.name
    )
    error_message = "Workspace and injected VNet must use the requested names, region and resource group, with a separate managed resource group."
  }

  assert {
    condition = (
      azurerm_databricks_workspace.this.custom_parameters[0].no_public_ip &&
      azurerm_databricks_workspace.this.public_network_access_enabled &&
      azurerm_databricks_workspace.this.network_security_group_rules_required == "AllRules" &&
      azurerm_databricks_workspace.this.custom_parameters[0].public_subnet_name == azurerm_subnet.this["public"].name &&
      azurerm_databricks_workspace.this.custom_parameters[0].private_subnet_name == azurerm_subnet.this["private"].name
    )
    error_message = "VNet injection must use both dedicated subnets with secure cluster connectivity while preserving public workspace access."
  }

  assert {
    condition = (
      length(azurerm_subnet.this) == 2 &&
      length(azurerm_subnet_network_security_group_association.this) == 2 &&
      alltrue([
        for subnet in azurerm_subnet.this :
        !subnet.default_outbound_access_enabled &&
        one(one(subnet.delegation).service_delegation).name == "Microsoft.Databricks/workspaces"
      ])
    )
    error_message = "Both subnets must have NSG associations, Databricks delegation and default outbound access disabled."
  }

  assert {
    condition = (
      length(azurerm_subnet_nat_gateway_association.this) == 2 &&
      azurerm_public_ip.nat.sku == "Standard" &&
      azurerm_public_ip.nat.allocation_method == "Static" &&
      azurerm_public_ip.nat.ip_tags["FirstPartyUsage"] == "/Unprivileged"
    )
    error_message = "Both subnets must use NAT with a static Standard public IP and explicitly declare the policy-required service tag to avoid replacement drift."
  }
}

run "injected_network_wiring" {
  command = apply

  assert {
    condition = (
      azurerm_databricks_workspace.this.custom_parameters[0].virtual_network_id == azurerm_virtual_network.this.id &&
      azurerm_databricks_workspace.this.custom_parameters[0].public_subnet_network_security_group_association_id == azurerm_subnet_network_security_group_association.this["public"].id &&
      azurerm_databricks_workspace.this.custom_parameters[0].private_subnet_network_security_group_association_id == azurerm_subnet_network_security_group_association.this["private"].id &&
      alltrue([
        for name, association in azurerm_subnet_network_security_group_association.this :
        association.subnet_id == azurerm_subnet.this[name].id &&
        association.network_security_group_id == azurerm_network_security_group.this[name].id
      ])
    )
    error_message = "The workspace must reference the injected VNet and each subnet's corresponding NSG association."
  }

  assert {
    condition = (
      azurerm_nat_gateway_public_ip_association.this.nat_gateway_id == azurerm_nat_gateway.this.id &&
      azurerm_nat_gateway_public_ip_association.this.public_ip_address_id == azurerm_public_ip.nat.id &&
      alltrue([
        for name, association in azurerm_subnet_nat_gateway_association.this :
        association.subnet_id == azurerm_subnet.this[name].id &&
        association.nat_gateway_id == azurerm_nat_gateway.this.id
      ])
    )
    error_message = "Both delegated subnets must connect to the NAT Gateway associated with the outbound public IP."
  }

  assert {
    condition = (
      azurerm_storage_container.data.storage_account_id == azapi_resource.data_storage.id &&
      azurerm_role_assignment.databricks_storage.scope == azurerm_storage_container.data.id &&
      azurerm_role_assignment.databricks_storage.principal_id == azurerm_databricks_access_connector.storage.identity[0].principal_id &&
      azurerm_role_assignment.databricks_storage_delegator.scope == azapi_resource.data_storage.id &&
      azurerm_role_assignment.databricks_storage_delegator.principal_id == azurerm_databricks_access_connector.storage.identity[0].principal_id &&
      azurerm_role_assignment.databricks_storage_delegator.role_definition_name == "Storage Blob Delegator" &&
      azurerm_network_security_perimeter_association.storage.resource_id == azapi_resource.data_storage.id &&
      azurerm_network_security_perimeter_association.storage.network_security_perimeter_profile_id == azurerm_network_security_perimeter_profile.storage.id &&
      azurerm_network_security_perimeter_access_rule.storage_public.network_security_perimeter_profile_id == azurerm_network_security_perimeter_profile.storage.id &&
      alltrue([
        for service, endpoint in azurerm_private_endpoint.storage :
        endpoint.subnet_id == azurerm_subnet.storage_private_endpoints.id &&
        one(endpoint.private_service_connection).private_connection_resource_id == azapi_resource.data_storage.id &&
        one(one(endpoint.private_service_connection).subresource_names) == service &&
        one(one(endpoint.private_dns_zone_group).private_dns_zone_ids) == azurerm_private_dns_zone.storage[service].id &&
        azurerm_private_dns_zone_virtual_network_link.storage[service].virtual_network_id == azurerm_virtual_network.this.id
      ])
    )
    error_message = "The data container, scoped managed-identity RBAC, perimeter and both private endpoints with VNet-linked DNS must reference the new data account."
  }
}

run "customized_environment" {
  command = plan

  variables {
    location                      = "eastus2"
    workspace_name                = "databricks-custom"
    resource_group_name           = "azure-databricks-custom"
    managed_resource_group_name   = "azure-databricks-custom-managed"
    virtual_network_name          = "databricks-custom-vnet"
    sku                           = "standard"
    virtual_network_address_space = "10.60.0.0/16"
    subnet_address_prefixes = {
      public  = "10.60.1.0/24"
      private = "10.60.2.0/24"
    }
    nat_idle_timeout_in_minutes            = 20
    storage_account_name_prefix            = "stcustom"
    storage_container_name                 = "custom-data"
    storage_replication_type               = "ZRS"
    storage_private_endpoint_subnet_prefix = "10.60.3.0/24"
    storage_perimeter_allowed_cidrs        = ["203.0.113.10/32"]
    storage_data_access_principal_ids      = ["33333333-3333-3333-3333-333333333333"]
    tags = {
      environment = "custom"
    }
  }

  assert {
    condition = (
      azurerm_databricks_workspace.this.name == "databricks-custom" &&
      azurerm_databricks_workspace.this.resource_group_name == "azure-databricks-custom" &&
      azurerm_databricks_workspace.this.managed_resource_group_name == "azure-databricks-custom-managed" &&
      azurerm_databricks_workspace.this.location == "eastus2" &&
      azurerm_databricks_workspace.this.sku == "standard" &&
      !azurerm_databricks_workspace.this.infrastructure_encryption_enabled &&
      azurerm_virtual_network.this.name == "databricks-custom-vnet" &&
      one(azurerm_virtual_network.this.address_space) == "10.60.0.0/16" &&
      one(azurerm_subnet.this["public"].address_prefixes) == "10.60.1.0/24" &&
      one(azurerm_subnet.this["private"].address_prefixes) == "10.60.2.0/24" &&
      azurerm_subnet.this["public"].name == "databricks-custom-public" &&
      azurerm_subnet.this["private"].name == "databricks-custom-private" &&
      azurerm_nat_gateway.this.name == "databricks-custom-nat" &&
      azurerm_nat_gateway.this.idle_timeout_in_minutes == 20 &&
      azurerm_public_ip.nat.name == "databricks-custom-nat-pip" &&
      azurerm_network_security_group.this["public"].name == "databricks-custom-public-nsg" &&
      azurerm_databricks_workspace.this.tags["environment"] == "custom"
    )
    error_message = "Configurable values must propagate to the workspace and its network without retaining development-specific settings."
  }

  assert {
    condition = (
      azapi_resource.data_storage.body.sku.name == "Standard_ZRS" &&
      startswith(azapi_resource.data_storage.name, "stcustom") &&
      azurerm_storage_container.data.name == "custom-data" &&
      one(azurerm_subnet.storage_private_endpoints.address_prefixes) == "10.60.3.0/24" &&
      one(azurerm_network_security_perimeter_access_rule.storage_public.address_prefixes) == "203.0.113.10/32" &&
      azurerm_role_assignment.storage_data_access["33333333-3333-3333-3333-333333333333"].principal_id == "33333333-3333-3333-3333-333333333333"
    )
    error_message = "Storage account settings, network CIDRs and optional operator grants must honor customized inputs."
  }
}

run "data_storage_security" {
  command = plan

  assert {
    condition = (
      azapi_resource.data_storage.body.kind == "StorageV2" &&
      azapi_resource.data_storage.body.properties.isHnsEnabled &&
      !azapi_resource.data_storage.body.properties.allowBlobPublicAccess &&
      !azapi_resource.data_storage.body.properties.allowSharedKeyAccess &&
      azapi_resource.data_storage.body.properties.defaultToOAuthAuthentication &&
      azapi_resource.data_storage.body.properties.supportsHttpsTrafficOnly &&
      azapi_resource.data_storage.body.properties.minimumTlsVersion == "TLS1_2" &&
      azapi_resource.data_storage.body.properties.publicNetworkAccess == "SecuredByPerimeter" &&
      azapi_resource.data_storage.body.properties.networkAcls.defaultAction == "Deny" &&
      azurerm_storage_container.data.container_access_type == "private" &&
      azurerm_network_security_perimeter_association.storage.access_mode == "Enforced" &&
      one(azurerm_network_security_perimeter_access_rule.storage_public.address_prefixes) == "0.0.0.0/0"
    )
    error_message = "ADLS Gen2 must use keyless authenticated HTTPS access, private containers and an enforced perimeter matching policy."
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.storage) == 2 &&
      azurerm_private_dns_zone.storage["blob"].name == "privatelink.blob.core.windows.net" &&
      azurerm_private_dns_zone.storage["dfs"].name == "privatelink.dfs.core.windows.net" &&
      length(azurerm_subnet.storage_private_endpoints.delegation) == 0 &&
      !azurerm_subnet.storage_private_endpoints.default_outbound_access_enabled &&
      azurerm_databricks_access_connector.storage.identity[0].type == "SystemAssigned" &&
      azurerm_role_assignment.databricks_storage.role_definition_name == "Storage Blob Data Contributor" &&
      length(azurerm_role_assignment.storage_data_access) == 0
    )
    error_message = "Storage endpoints must use a separate undelegated subnet and both private DNS zones, with a managed Access Connector and no implicit user grants."
  }
}
