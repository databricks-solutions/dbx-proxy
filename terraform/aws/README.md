## AWS Terraform module: `dbx-proxy`

This module deploys `dbx-proxy` on AWS, using an internal Network Load Balancer (NLB) and a VPC Endpoint Service (PrivateLink) for Databricks Serverless private connectivity.

For common concepts (listener config, deployment modes, overall limitations), see the global module documentation in `terraform/README.md`.

---

### Quick start

In your existing Terraform stack, add:

```hcl
module "dbx_proxy" {
  source = "github.com/dnks0/dbx-proxy//terraform/aws?ref=v<release>"

  # AWS config
  region = "eu-central-1"
  tags   = {}

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

After apply, use the output `load_balancer.vpc_endpoint_service_name` when creating Databricks private endpoint rules in your NCC. Also, add a domain of your choice as private endpoint rule on your NCC that you can use for troubleshooting.

---

### AWS-specific variables

| Variable | Type | Default | Description |
|---|---:|---:|---|
| `region` | `string` | (required) | AWS region to deploy to. |
| `vpc_id` | `string` | `null` | Existing VPC ID. Required for `proxy-only` mode. If `null`, a VPC can be bootstrapped in `bootstrap` mode. |
| `subnet_ids` | `list(string)` | `[]` | Existing private subnet IDs for the NLB + ASG. Required for `proxy-only` mode. If empty, subnets can be created in `bootstrap` mode. |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC CIDR (only used when creating a VPC in `bootstrap`). |
| `subnet_cidrs` | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | Private subnet CIDRs (only used when creating subnets in `bootstrap` mode). |
| `nat_subnet_cidr` | `string` | `"10.0.0.0/24"` | Public subnet CIDR for the NAT gateway (only used when creating networking in `bootstrap` mode). |
| `nlb_arn` | `string` | `null` | Existing NLB ARN to attach listeners/target groups to in `proxy-only` mode. |

Common variables are documented in `terraform/README.md`.

---

### Outputs

- `networking`: object with
  - `vpc_id`
  - `vpc_cidr`
  - `subnet_ids`
  - `subnet_cidrs`
  - `nat_gateway_id`
  - `nat_subnet_id`
  - `nat_subnet_cidr`
  - `internet_gateway_id`

- `load_balancer`: object with
  - `nlb_arn`
  - `nlb_dns_name`
  - `nlb_target_group_arns`
  - `nlb_security_group_ids`
  - `vpc_endpoint_service_arn`
  - `vpc_endpoint_service_name`

- `proxy`: object with
  - `iam_role_name`
  - `iam_role_arn`
  - `instance_profile_name`
  - `instance_profile_arn`
  - `security_group_id`
  - `autoscaling_group_name`
  - `launch_template_name`
  - `dbx_proxy_cfg`

---
### Notes for AWS users

- Multi availability-zone resilience can be achieved by providing subnets across multiple availability-zones. By default, the autoscaling-group tries to spread dbx-proxy instances across subnets eavenly. In `proxy-only` mode, you are responsible to configure subnets accordingly. In `bootstrap` mode, default subnets are created across multiple availaiblity-zones in the selected region.
