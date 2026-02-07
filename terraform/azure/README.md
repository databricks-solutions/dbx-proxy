## Azure Terraform module: `dbx-proxy`

This module deploys `dbx-proxy` on Azure, using an internal Standard Load Balancer and a Private Link Service for Databricks Serverless private connectivity.

For common concepts (listener config, deployment modes, overall limitations), see the global module documentation in `terraform/README.md`.

---

### Quick start

In your existing Terraform stack, add:

```hcl
module "dbx_proxy" {
  source = "github.com/dnks0/dbx-proxy//terraform/azure?ref=v<release>"

  # Azure config
  location       = "westeurope"
  resource_group = "rg-dbx-proxy"  # optional in bootstrap mode
  tags           = {}

  # dbx-proxy config
  dbx_proxy_image_version = "<release>"
  dbx_proxy_health_port   = 8080
  dbx_proxy_listener      = []
}
```

Make sure to replace `<release>` with the actual release version!

Then run:

```bash
terraform init
terraform apply
```

After apply, use the output `load_balancer.private_link_service_alias` when creating Databricks private endpoint rules in your NCC. Also, add a domain of your choice as private endpoint rule on your NCC that you can use for troubleshooting.

---

### Azure-specific variables

| Variable | Type | Default | Description |
|---|---:|---:|---|
| `location` | `string` | (required) | Azure region to deploy to. |
| `resource_group` | `string` | `null` | Resource group name. Required in `proxy-only` mode. If `null` in `bootstrap`, a new one is created. |
| `prefix` | `string` | `null` | Optional naming prefix. A randomized suffix is always appended. |
| `tags` | `map(string)` | `{}` | Extra tags applied to Azure resources. |
| `instance_type` | `string` | `"Standard_D2s_v5"` | VM size for proxy instances. |
| `min_capacity` | `number` | `1` | Minimum number of dbx-proxy instances. |
| `max_capacity` | `number` | `1` | Maximum number of dbx-proxy instances. |
| `vnet_name` | `string` | `null` | Existing VNet name. If `null` in `bootstrap`, a new VNet is created. |
| `subnet_names` | `list(string)` | `[]` | Existing subnet names. If empty in `bootstrap`, new subnets are created. |
| `vnet_cidr` | `string` | `"10.0.0.0/16"` | VNet CIDR (only used when bootstrapping). |
| `subnet_cidrs` | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | Subnet CIDRs (only used when bootstrapping). |
| `enable_nat_gateway` | `bool` | `true` | Whether to create a NAT Gateway (only when bootstrapping). |
| `slb_name` | `string` | `null` | Existing Load Balancer name. Required in `proxy-only` mode. |

Common variables are documented in `terraform/README.md`.

---

### Outputs

- `resource_group`: name of the resource group used

- `networking`: object with
  - `vnet_name`
  - `vnet_cidr`
  - `subnet_names`
  - `subnet_cidrs`
  - `nat_gateway_name`
  - `nat_gateway_id`

- `load_balancer`: object with
  - `slb_name`
  - `slb_id`
  - `slb_backend_pool_id`
  - `private_link_service_id`
  - `private_link_service_alias`

- `proxy`: object with
  - `nsg_id`
  - `vmss_name`
  - `vmss_id`
  - `dbx_proxy_cfg`

---

### Notes for Azure users

- If `resource_group` is provided, it must already exist. If `null` in `bootstrap` mode, a new one is created.
- The VM scale set uses a randomly generated password (not exposed) and is managed via cloud-init. No SSH access is configured.
- The VM scale set attaches to a single subnet (the first entry). For multi-AZ resilience, use zone-aware VM sizes.
