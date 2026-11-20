variable "subscription_id" {
  description = "Azure subscription ID explicitly selected for the new development resources."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Azure region shared by the resource group, workspace and network."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "location must not be empty."
  }
}

variable "workspace_name" {
  description = "Name of the Azure Databricks workspace and prefix for supporting resources."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Resource group containing the workspace and injected VNet."
  type        = string
  nullable    = false
}

variable "managed_resource_group_name" {
  description = "Separate resource group created and managed by Azure Databricks."
  type        = string
  nullable    = false
}

variable "virtual_network_name" {
  description = "Name of the injected virtual network."
  type        = string
  nullable    = false
}

variable "sku" {
  description = "Azure Databricks pricing tier."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "sku must be standard or premium."
  }
}

variable "virtual_network_address_space" {
  description = "IPv4 CIDR for the injected VNet, between /16 and /24."
  type        = string
  nullable    = false

  validation {
    condition     = can(cidrnetmask(var.virtual_network_address_space)) && can(regex("/(1[6-9]|2[0-4])$", var.virtual_network_address_space))
    error_message = "virtual_network_address_space must be a valid IPv4 CIDR between /16 and /24."
  }
}

variable "subnet_address_prefixes" {
  description = "Non-overlapping host/public and container/private IPv4 CIDRs inside the VNet, each /26 or larger."
  type = object({
    public  = string
    private = string
  })
  nullable = false

  validation {
    condition = alltrue([
      for prefix in values(var.subnet_address_prefixes) :
      can(cidrnetmask(prefix)) && can(regex("/([0-9]|1[0-9]|2[0-6])$", prefix))
    ])
    error_message = "Each subnet must be a valid IPv4 CIDR with a prefix length no greater than /26."
  }
}

variable "nat_idle_timeout_in_minutes" {
  description = "NAT Gateway TCP idle timeout in minutes."
  type        = number
  nullable    = false

  validation {
    condition = (
      var.nat_idle_timeout_in_minutes >= 4 &&
      var.nat_idle_timeout_in_minutes <= 120 &&
      floor(var.nat_idle_timeout_in_minutes) == var.nat_idle_timeout_in_minutes
    )
    error_message = "nat_idle_timeout_in_minutes must be an integer between 4 and 120."
  }
}

variable "public_ip_tags" {
  description = "Public IP service tags required by governance policies; distinct from ordinary Azure resource tags."
  type        = map(string)
  nullable    = false
}

variable "storage_account_name_prefix" {
  description = "Lowercase alphanumeric Storage Account prefix; a persistent six-character random suffix is appended."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{1,18}$", var.storage_account_name_prefix))
    error_message = "storage_account_name_prefix must contain 1 to 18 lowercase letters or digits, leaving room for the random suffix."
  }
}

variable "storage_container_name" {
  description = "Private container for application data, separate from Databricks-managed storage."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.storage_container_name) >= 3 &&
      length(var.storage_container_name) <= 63 &&
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.storage_container_name))
    )
    error_message = "storage_container_name must contain 3 to 63 lowercase letters, digits or single hyphens, starting and ending with a letter or digit."
  }
}

variable "storage_replication_type" {
  description = "Replication for the Standard StorageV2 data account."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "storage_replication_type must be LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  }
}

variable "storage_private_endpoint_subnet_prefix" {
  description = "Dedicated IPv4 CIDR inside the VNet for storage private endpoints; must not overlap the Databricks subnets."
  type        = string
  nullable    = false

  validation {
    condition     = can(cidrnetmask(var.storage_private_endpoint_subnet_prefix))
    error_message = "storage_private_endpoint_subnet_prefix must be a valid IPv4 CIDR."
  }
}

variable "storage_perimeter_allowed_cidrs" {
  description = "Public IPv4 CIDRs allowed by the storage Network Security Perimeter; 0.0.0.0/0 permits every public source and still requires Entra authorization."
  type        = list(string)
  nullable    = false

  validation {
    condition = (
      length(var.storage_perimeter_allowed_cidrs) > 0 &&
      alltrue([for prefix in var.storage_perimeter_allowed_cidrs : can(cidrnetmask(prefix))])
    )
    error_message = "storage_perimeter_allowed_cidrs must contain at least one valid IPv4 CIDR."
  }
}

variable "storage_data_access_principal_ids" {
  description = "Optional Entra object IDs granted Storage Blob Data Contributor on the data container, for example the operator's object ID."
  type        = set(string)
  nullable    = false

  validation {
    condition = alltrue([
      for principal_id in var.storage_data_access_principal_ids :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", principal_id))
    ])
    error_message = "Each storage_data_access_principal_ids entry must be an Entra object UUID, not an email address or application client ID."
  }
}

variable "tags" {
  description = "Tags applied to resources that support tags."
  type        = map(string)
  nullable    = false
}
