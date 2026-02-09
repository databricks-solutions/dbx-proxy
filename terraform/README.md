## Terraform module: dbx-proxy (multi-cloud)

This repository provides Terraform modules for deploying `dbx-proxy` on multiple clouds.

- [AWS](./aws/README.md)
- **[Azure](./azure/README.md)**

`dbx-proxy` is commonly used as the customer-side component for Databricks Serverless **private connectivity to resources in your VPC/VNet**. It creates a private entry point (internal load balancer + private link service) that forwards traffic to `dbx-proxy`, which then routes to your backend destinations.

---



### Deployment mode behavior

The module supports two modes:

- **`bootstrap`** (default)
  - Creates and configures an internal load balancer, a private endpoint service and the proxy compute.
  - If networking (VPC/Vnet & subnets **are provided**, the module uses existing networking.
  - If network IDs are **not provided**, the module creates the necessary networking resources.

- **`proxy-only`**
  - Requires existing networking, an existing load balancer and private endpoint service
  - Configures the existing load balancer and deploys the proxy compute only.

---

### Configuration variables (common)

These variables define overall configuration of dbx-proxy:

| Variable | Type | Default | Description |
|---|---:|---:|---|
| `deployment_mode` | `string` | `"bootstrap"` | Controls whether the module bootstraps networking/load balancer (`bootstrap`) or attaches to existing infrastructure (`proxy-only`). |
| `prefix` | `string` | `null` | Optional naming prefix. A randomized suffix is always appended. |
| `tags` | `map(string)` | `{}` | Extra tags applied to Azure resources. |
| `instance_type` | `string` | Azure: `"Standard_D2ps_v6"`, AWS: `"t4g.medium"` | VM size for proxy instances. |
| `min_capacity` | `number` | `1` | Minimum number of dbx-proxy instances. |
| `max_capacity` | `number` | `1` | Maximum number of dbx-proxy instances. |
| `enable_nat_gateway` | `bool` | `true` | Whether to create IGW + NAT for outbound internet access (only when creating networking in `bootstrap` mode). |
| `dbx_proxy_image_version` | `string` | `"0.1.5"` | Docker image tag/version of `dbx-proxy` to deploy. |
| `dbx_proxy_health_port` | `number` | `8080` | Health port exposed by `dbx-proxy` (HTTP `GET /status`). Also used for load balancer health checks. |
| `dbx_proxy_max_connections` | `number` | `null` | Optional HAProxy `maxconn` override. If unset, the module derives a value from vCPU and memory of the selected instance type (see cloud specific input variables). |
| `dbx_proxy_listener` | `list(object)` | `[]` | Listener configuration (ports/modes/routes/destinations). See **Listener configuration** below. |

Cloud-specific variables are documented for each module individually.

---

### Configuration

`dbx_proxy_listener` is a list of listener objects that defines how and what traffic gets forwarded by `dbx-proxy`. Each listener object defines a port that the cloud load-balancer and `dbx-proxy` will listen on. This will be the port to use from Databricks serverless compute when connecting to a specific resource. Routes are defining the actual destinations that traffic should be routed to, where each route can have multiple destination servers.
A routes' domains should match the domains entered for a [private endpoint rule in your NCC](https://docs.databricks.com/aws/en/security/network/serverless-network-security/pl-to-internal-network#step-4-create-an-aws-interface-vpc-endpoint) in the Databricks account console.

Please note, that Databricks NCCs have limitations, e.g. the number of Private Endpoint rules allowed, etc. Follow Databricks’ documented constraints and align your configuration!



```hcl
dbx_proxy_listener = [
  {
    name  = string
    mode  = string
    port  = number
    routes = [
      {
        name    = string
        domains = list(string)
        destinations = [
          {
            name = string,
            host = string,
            port = number
          }
        ]
      }
    ]
  }
]
```

#### Listener fields

- **`name`**: stable identifier (used for naming resources)
- **`mode`**:
  - `"tcp"`: L4 forwarding using IP/Port only
  - `"http"`: L7 (HTTP/S) forwarding using SNI-Header
- **`port`**: frontend port exposed by the cloud load balancer and `dbx-proxy`
- **`routes`**: list of routing rules (domains + destinations) for a listener

#### Route fields

- **`name`**: route identifier
- **`domains`**: list of domains that should match this route (used for SNI/host-based routing depending on mode). not relevant in `tcp` mode.
- **`destinations`**: list of upstream targets (`name`, `host` + `port`)
  - **`name`**: the destination identifier
  - **`host`**: can be either a (static) IP or a FQDN (requires DNS!)
  - **`port`**: the port to use on the destination

#### Listener Configuration Patterns

**1) Plain TCP/L4 traffic, e.g. database connectivity (e.g. Postgres, etc.):**

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
          {
            name = "postgres-1",
            host = "10.0.1.10",
            port = 5432},
        ]
      }
    ]
  }
]
```

**2) HTTPS traffic using L7 SNI-based forwarding (supports multiple backends/routes for a listener):**

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
          {
            name = "app-a-1",
            host = "10.0.2.20",
            port = 443
          },
        ]
      },
      {
        name    = "app-b"
        domains = ["app-b.application.domain"]
        destinations = [
          {
            name = "app-b-1",
            host = "app-b-server-1.app-b.application.domain",
            port = 443
          },
        ]
      }
    ]
  }
]
```

With your NCC configured accordingly, the above sample configuration would allow you to connect from Databricks serverless compute to application "app-b" using domain "app-b.application.domain" and port 443:
```bash
%sh

curl -sS -w '\nHTTP %{http_code}\n' https://app-b.application.domain
```

#### Health checks

- `dbx-proxy` health endpoint is `GET /status` on `dbx_proxy_health_port` (default `8080`).
- The module configures the cloud load balancer to probe the health port.
- The module will error out if the health port is also defined as a listener port.

---

### Outputs (all clouds)

All modules expose the same top-level output groups:

- `networking`
- `load_balancer`
- `proxy`

Field details vary by cloud; see the cloud modules' README.

---

### Limitations & tradeoffs of the current implementation

This module is intentionally minimal right now. The following limitations are important for production planning:

- **Single instance by default**
  - By default `min_capacity=1` and `max_capacity=1`, so you get **one instance** running a single `dbx-proxy`.
  - **Mitigation**: set `max_capacity` (and typically `min_capacity`) to `>= 2` and use multiple availability zones across subnets where supported.

- **Planned downtime during updates**
  - The module prefers a full replacement of instances to ensure integrity and config changes are picked up immediately.
  - **Mitigation**: run at least 2 instances and use availability-zone aware placement as the module is configured to perform a rolling update, keeping at least one instance at a time.

- **Outbound internet dependency (when bootstrapping)**
  - If you let the module create networking and keep `enable_nat_gateway = true`, instances use NAT for outbound access.
  - Cloud-init installs Docker and downloads the Docker Compose plugin from GitHub, as well as pulls the dbx-proxy docker image from GHCR, so **egress to the internet is required!**
  - In bootstrap mode, `enable_nat_gateway = true` will deploy necessary resources to enable outbound connectivity. Set to `false` if you provide your own networking with internet access already configured
  - In proxy-only mode, `enable_nat_gateway` is ignored

- **Databricks serverless private connectivity constraints apply**
  - Databricks enforces limits around NCCs, private endpoints, and private endpoint rules (including limits on the number of domain names per rule).
  - Treat these as **external constraints** that influence how you model `dbx_proxy_listener`.
  - Reference: [Configure private connectivity to resources in your VPC](https://docs.databricks.com/aws/en/security/network/serverless-network-security/pl-to-internal-network).
