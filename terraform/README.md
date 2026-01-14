## Terraform module: `dbx-proxy` (multi-cloud)

This repository provides a **Terraform module** for deploying `dbx-proxy` across multiple clouds.

- **AWS**: implemented today (`terraform/aws`)
- **Azure**: planned (not implemented yet)

`dbx-proxy` is commonly used as the customer-side component for Databricks Serverless **private connectivity to resources in your VPC/VNet**. In the Databricks AWS guide, this corresponds to provisioning the **internal NLB frontend** (and the endpoint service). See [Configure private connectivity to resources in your VPC](https://docs.databricks.com/aws/en/security/network/serverless-network-security/pl-to-internal-network).

---

### AWS architecture (what gets deployed)

**Always deployed (AWS implementation):**
- **Compute**: EC2 Launch Template + Auto Scaling Group (ASG) running `dbx-proxy`
- **Load balancing**: internal **Network Load Balancer (NLB)**
- **Private connectivity**: **VPC Endpoint Service (PrivateLink)** backed by the NLB
- **Networking & security**: Security Group, IAM Role + Instance Profile

**Conditionally deployed:**
- VPC, private subnets
- Optional IGW + public subnet + NAT gateway (internet connectivity needed to pull images, etc.!)
- Route tables + associations

---

### Architecture diagram (AWS)

(to be added)

---

### Quick start (AWS)

In your existing Terraform stack, add:

```hcl
module "dbx_proxy" {
  source = "github.com/dnks0/dbx-proxy//terraform/aws?ref=v0.1.0"

  # AWS config
  region = "eu-central-1"
  tags   = {}
  ...

  # dbx-proxy config
  dbx_proxy_image_version = "0.1.0"
  dbx_proxy_health_port   = 8080
  dbx_proxy_listener      = []
}
```

Then run:

```bash
terraform init
terraform apply
```

After apply, use the output `vpc_endpoint_service_name` when creating Databricks private endpoint rules (see Databricks guide linked above).
Also, make sure to add a domain of your choice as private endpoint rule on your NCC that you could use for [troubleshooting](../README.md#troubleshooting) purposes.

---

### Configuration variables

This module separates **common variables** (used by the config renderer) from **cloud-specific variables** (provisioning details for a specific cloud).

#### Common variables (all clouds)

These variables define what the proxy should do (listeners, health port, image tag).

| Variable | Type | Default | Description |
|---|---:|---:|---|
| `dbx_proxy_image_version` | `string` | `"0.1.0"` | Docker image tag/version of `dbx-proxy` to deploy. |
| `dbx_proxy_health_port` | `number` | `8080` | Health port exposed by `dbx-proxy` (HTTP `GET /status`). Also used for NLB target group health checks. |
| `dbx_proxy_listener` | `list(object)` | `[]` | Listener configuration (ports/modes/routes/destinations). See **Listener configuration** below. |

#### AWS-specific variables (`terraform/aws`)

| Variable | Type | Default | Description |
|---|---:|---:|---|
| `region` | `string` | (required) | AWS region to deploy to. |
| `prefix` | `string` | `null` | Optional naming prefix. A randomized suffix is always appended to avoid collisions. |
| `tags` | `map(string)` | `{}` | Extra tags applied to AWS resources (also used as provider default tags). |
| `instance_type` | `string` | `"t3.medium"` | EC2 instance type for proxy nodes. |
| `vpc_id` | `string` | `null` | Existing VPC ID. If `null`, the module bootstraps a VPC. |
| `subnet_ids` | `list(string)` | `[]` | Existing private subnet IDs for the NLB + ASG. If empty, subnets are created. |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC CIDR (only used when creating a VPC). |
| `subnet_cidrs` | `list(string)` | `["10.0.1.0/24","10.0.2.0/24"]` | Private subnet CIDRs (only used when creating subnets). |
| `enable_nat_gateway` | `bool` | `true` | Whether to create NAT (and related IGW/public subnet) for outbound internet access (only when creating networking). |
| `public_subnet_cidr` | `string` | `"10.0.0.0/24"` | Public subnet CIDR for the NAT gateway (only used when creating networking). |

---

### Outputs (AWS)

- `nlb_arn`: ARN of the internal NLB
- `vpc_endpoint_service_name`: **input** for Databricks private endpoint rules
- `vpc_endpoint_service_arn`: ARN of the endpoint service
- `nlb_dns_name`: internal NLB DNS name
- `nlb_zone_id`: Route53 hosted zone id for NLB aliases
- `autoscaling_group_name`: ASG name
- `security_group_id`: Security group ID attached to the proxy instances
- `target_group_arns`: listener target groups keyed by listener name

---

### Listener configuration (deep dive)

`dbx_proxy_listener` is a list of listener objects:

```hcl
dbx_proxy_listener = [
  {
    name  = string
    mode  = string # "tcp" or "http"
    port  = number
    routes = [
      {
        name    = string
        domains = list(string)
        destinations = [
          { name = string, host = string, port = number }
        ]
      }
    ]
  }
]
```

#### Listener fields

- **`name`**: stable identifier (used for naming resources like target groups)
- **`mode`**:
  - `"tcp"`: L4 forwarding
  - `"http"`: L7 (HTTP) behavior in the proxy configuration; the AWS NLB still uses TCP listeners
- **`port`**: frontend port exposed by the NLB and `dbx-proxy`
- **`routes`**: list of routing rules (domains + destinations)

#### Route fields

- **`name`**: route identifier
- **`domains`**: list of domains that should match this route (used for SNI/host-based routing depending on mode)
  - Databricks private endpoint rules have limits (for example max domain count per rule). Follow Databricks’ documented constraints.
- **`destinations`**: list of upstream targets (`host` + `port`)

#### Common patterns

**1) TCP database traffic (e.g. Postgres, L4):**

```hcl
dbx_proxy_listener = [
  {
    name  = "postgres-5432"
    mode  = "tcp"
    port  = 5432
    routes = [
      {
        name    = "postgres"
        domains = ["postgres.database.domain"]
        destinations = [
          { name = "postgres-1", host = "10.0.1.10", port = 5432 },
        ]
      }
    ]
  }
]
```

**2) HTTPS with SNI-based forwarding (multiple backends):**

```hcl
dbx_proxy_listener = [
  {
    name  = "https-443"
    mode  = "http"
    port  = 443
    routes = [
      {
        name    = "app-a"
        domains = ["app-a.application.domain"]
        destinations = [
          { name = "app-a-1", host = "10.0.2.20", port = 443 },
        ]
      },
      {
        name    = "app-b"
        domains = ["app-b.application.domain"]
        destinations = [
          { name = "app-b-1", host = "app-b-server-1.app-b.application.domain", port = 443 },
        ]
      }
    ]
  }
]
```

#### Health checks

- `dbx-proxy` health endpoint is `GET /status` on `dbx_proxy_health_port` (default `8080`).
- AWS NLB target groups use the health port for health checks.
- The AWS implementation also creates an **optional NLB listener** on `dbx_proxy_health_port` so the health endpoint can be reached through the NLB/PrivateLink (unless the health port is already used as a normal listener port).

---

### Limitations & tradeoffs of the current implementation

This module is intentionally minimal right now. The following limitations are important for production planning:

- **Single instance / no horizontal scaling by default**
  - The AWS ASG is configured as `min=desired=max=1`, so you get **one EC2 instance** running `dbx-proxy`.
  - **Mitigation**: increase `max_size` / `desired_capacity` (requires module changes today) and consider multi-AZ designs.

- **Planned downtime during updates**
  - The ASG uses `instance_refresh` with `min_healthy_percentage = 0` to ensure launch template updates roll out even with a single instance.
  - This implies **downtime during replacement** on apply (terminate -> relaunch).
  - **Mitigation**: run at least 2 instances and set `min_healthy_percentage` accordingly (requires module changes today).
  - On changes to `dbx_proxy_listener`, `terraform apply` updates the EC2 launch template `user_data`, and the ASG replaces the instance (short downtime) so the new config is applied via cloud-init.

- **Outbound internet dependency (when bootstrapping)**
  - If you let the module create networking and keep `enable_nat_gateway = true`, instances use NAT for outbound access.
  - Cloud-init installs Docker and downloads the Docker Compose plugin from GitHub, so **egress to the internet is required** (or you must customize the bootstrap/AMI).

- **AWS-only**
  - The module is structured for multi-cloud, but **only AWS is implemented** right now.

- **Databricks serverless private connectivity constraints apply**
  - Databricks enforces limits around NCCs, private endpoints, and private endpoint rules (including limits on the number of domain names per rule).
  - Treat these as **external constraints** that influence how you model `dbx_proxy_listener`.
  - Reference: [Configure private connectivity to resources in your VPC](https://docs.databricks.com/aws/en/security/network/serverless-network-security/pl-to-internal-network).
