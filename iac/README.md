# Azure Databricks development infrastructure

Terraform configuration is in [src](./src). It creates new resources; it does
not import or modify the repository's existing development workspace.

## Resources

- Resource group: `azure-databricks-dev`.
- Premium workspace: `databricks-dev`, in `westus` by default.
- VNet: `databricks-dev-vnet`, in the same resource group and region as the
  workspace, with address space `10.42.0.0/16`.
- Dedicated host/public subnet `10.42.1.0/24` and container/private subnet
  `10.42.2.0/24`, both delegated to `Microsoft.Databricks/workspaces`, each
  associated with its own NSG. Databricks manages the required NSG rules.
- Standard NAT Gateway with a static public IP, associated with both subnets
  for explicit outbound connectivity. Default outbound access is disabled.
- Separate service-managed resource group: `azure-databricks-dev-managed`.
  Azure Databricks creates and manages it; do not put custom resources in it.
- Separate ADLS Gen2 Storage Account: `stdatabricksdev` plus a persistent
  six-character random suffix, Standard LRS by default, with private container
  `data` in the resource group you manage.
- Storage private endpoints for both `blob` and `dfs`, using a dedicated
  `10.42.3.0/24` subnet and private DNS zones linked to the Databricks VNet.
- Network Security Perimeter (NSP) in Enforced mode for public storage access.
- Databricks Access Connector with a system-assigned identity and Storage Blob
  Data Contributor scoped to the data container, plus Storage Blob Delegator
  on the account for Unity Catalog user-delegation support.

The VNet contains the classic compute plane, not the Databricks control plane.
Secure cluster connectivity disables public IPs on classic cluster nodes.
The workspace UI/API remain publicly accessible by design; this is **not**
a Private Link deployment. Serverless compute does not use this injected VNet.
No clusters, jobs, notebooks or Unity Catalog resources are created.

## Files

| File | Responsibility |
| --- | --- |
| [versions.tf](./src/versions.tf) | Terraform and AzureRM provider constraints |
| [providers.tf](./src/providers.tf) | AzureRM authentication configuration |
| [variables.tf](./src/variables.tf) | Configurable inputs and validation |
| [terraform.tfvars](./src/terraform.tfvars) | Local configuration, ignored by Git |
| [terraform.tfvars.example](./src/terraform.tfvars.example) | Versioned configuration template |
| [resource_group.tf](./src/resource_group.tf) | Resource group |
| [network.tf](./src/network.tf) | VNet, delegated subnets and NSGs |
| [nat_gateway.tf](./src/nat_gateway.tf) | Explicit outbound connectivity |
| [databricks.tf](./src/databricks.tf) | VNet-injected workspace |
| [storage.tf](./src/storage.tf) | ADLS Gen2 account, stable random suffix and private data container |
| [storage_network.tf](./src/storage_network.tf) | Dedicated subnet, storage private endpoints and DNS |
| [storage_perimeter.tf](./src/storage_perimeter.tf) | Enforced NSP and configured public CIDR rule |
| [storage_access.tf](./src/storage_access.tf) | Access Connector and container-scoped data permissions |
| [outputs.tf](./src/outputs.tf) | Workspace URL, resource IDs and outbound IP |

## Local validation

Requires Terraform >= 1.7 and < 2.0. These commands download the AzureRM
provider and validate locally, without Azure sign-in or provisioning:

```powershell
Set-Location .\iac\src
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
```

Tests use mocked AzureRM, AzAPI and Random providers. They do not prove Azure permissions,
regional availability, policy compliance or successful cluster startup.
Commit `.terraform.lock.hcl` to keep provider selection reproducible.

## Configuration

A local `src/terraform.tfvars` file is provided and ignored by Git. On a fresh
clone, create it from the versioned template:

```powershell
Copy-Item .\terraform.tfvars.example .\terraform.tfvars
```

Run this from `iac/src` only if the local file does not already exist. Edit
`terraform.tfvars` to set the approved subscription ID and adjust names, region,
SKU, VNet/subnet CIDRs, NAT idle timeout and tags. Terraform loads this file
automatically. The subscription placeholder deliberately fails validation until
replaced with a real, approved subscription ID. Mock tests supply their own
inputs and do not require a real ID or this local file.

Subnet, NSG, NAT Gateway and public IP names derive from `workspace_name`.
Infrastructure encryption is enabled for Premium; Standard does not support
this option. Public UI/API access, secure cluster connectivity, NSG rules and
explicit NAT egress remain intentional architecture settings in the resources.
Changing names, region or network settings can replace existing resources;
always inspect a plan before applying.

`public_ip_tags` configures Public IP service tags, not ordinary resource tags.
The development configuration explicitly declares `FirstPartyUsage =
"/Unprivileged"` to match the effective governance policy. That policy appends
the service tag when omitted; because AzureRM treats changes to `ip_tags` as
replacement, omitting it can cause repeated Public IP replacement plans.
Do not suppress this with `ignore_changes`. Recreate saved plans after changing
configuration, and review them before applying; existing plans are not updated
by editing Terraform files.

## Data storage

The new account is for your data, not a replacement for the service-managed
Databricks root account. Azure Databricks still creates its internal storage.
Creating the new account does not automatically redirect existing tables,
catalogs or DBFS paths to it.

Storage configuration lives in `terraform.tfvars`:

- `storage_account_name_prefix`: up to 18 lowercase alphanumeric characters;
  the suffix is generated once and retained in Terraform state, not regenerated
  on every plan. Preserve state to preserve the account name.
- `storage_container_name` and `storage_replication_type`: data container and
  Standard account replication.
- `storage_private_endpoint_subnet_prefix`: a dedicated undelegated subnet
  inside the VNet, not overlapping either Databricks subnet.
- `storage_perimeter_allowed_cidrs`: public IPv4 CIDRs permitted by the NSP.
- `storage_data_access_principal_ids`: optional Entra object IDs granted Storage
  Blob Data Contributor on the container. Add your user/group object ID here
  if you do not already have suitable data-plane permissions. The example is
  empty and does not implicitly grant anyone access.

The account uses hierarchical namespace, HTTPS, TLS 1.2 minimum, Entra
authentication, no Shared Key authorization and no anonymous blob access.
The container is created through ARM using `storage_account_id`; Terraform
does not need storage keys or data-plane network access for container creation.
AzAPI owns the account because the AzureRM boolean public-network-access
setting cannot express `SecuredByPerimeter`. No overlapping AzureRM storage
account resource or `ignore_changes` workaround is used.

The effective storage governance policy permits `Disabled` or
`SecuredByPerimeter`; it modifies other public-access settings to `Disabled`.
The configuration explicitly uses `SecuredByPerimeter` with an Enforced NSP.
The Databricks classic compute VNet reaches `blob` and `dfs` through private
endpoints, whose traffic is not restricted by the NSP. Public clients use
the NSP access rule. In Enforced mode, the perimeter takes precedence over
traditional storage subnet/firewall rules, so those rules are not used to
claim subnet isolation.

**The requested `0.0.0.0/0` rule allows every public IPv4 source**, not just your
computer. It does not grant anonymous access or bypass Entra/RBAC, but it does
remove source-IP restriction on public storage traffic. Prefer your specific
public IP with `/32` when possible. Network permission alone does not grant
permission to browse/upload data; Azure resource Owner/Contributor alone is
also not a storage data-plane role.

For use through Unity Catalog, configure a storage credential using the
`storage_access_connector_id` output, then an external location pointing to
`storage_abfss_url`. Create external tables/volumes there, or explicitly
configure a catalog/schema managed location to use that path. These
workspace/metastore objects are not provisioned here because their target and
permissions have not been selected. Do not mount with storage keys or embed
credentials in notebooks.

## Deployment (manual, after approval)

Follow [AGENTS.md](../AGENTS.md) and the local environment instructions before
remote actions. Verify the intended Azure identity, tenant and subscription;
do not assume that the current CLI session is correct. Select the subscription
explicitly and ensure the deploying identity can create resources and delegate
and join both subnets. Check for existing resource names and overlapping CIDRs
before deployment; use import if resources already exist.
Storage deployment also requires permission to create role assignments,
private endpoints, private DNS zones and NSP resources. Optional data-role
grants require the intended Entra object IDs. RBAC can take time to propagate.

Using an approved Azure CLI session, fill in `terraform.tfvars` and review a plan:

```powershell
terraform init
terraform plan "-out=dev.tfplan"
```

Only after explicit approval of the reviewed plan and its costs:

```powershell
terraform apply dev.tfplan
terraform output
```

NAT Gateway, its public IP, storage private endpoints and DNS can incur costs
even without running clusters; storage capacity and transactions are billed
separately.
The public IP is for outbound NAT only; it is not assigned to a cluster node.
After deployment, verify workspace health and both subnet delegations, NSGs
and NAT associations. Cluster connectivity requires a separate authorized
runtime test, which can incur compute costs.
For storage, separately verify private DNS resolution and authenticated
read/write from authorized classic compute, plus public access through the
NSP from an approved client. Local mock tests do not establish this connectivity.
Serverless networking is not covered by the VNet's private endpoints.

State is local by default. State, variable-value files, saved plans and provider
caches are ignored by Git. Protect state and plan files; configure an approved
remote backend with locking before shared/team use. No Databricks profile or
token is required: provisioning uses the AzureRM provider, not the Databricks
provider.

## References

- [Azure Databricks VNet injection](https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/vnet-inject)
- [AzureRM workspace resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace)
- [Storage Network Security Perimeter](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security-perimeter)
- [Storage private endpoints](https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints)
- [Storage account ARM schema](https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/2025-01-01/storageaccounts)
- [Unity Catalog managed identity permissions](https://learn.microsoft.com/en-us/azure/databricks/connect/unity-catalog/cloud-storage/azure-managed-identities)
