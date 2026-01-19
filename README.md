## dbx-proxy

`dbx-proxy` is a lightweight **HAProxy-based load balancer** that enables **private network connectivity** from **Databricks Serverless** compute to **resources in your own VPC/VNet** (for example: databases, applications, etc).

### What problem it solves

Many enterprise resources live in private networks and are not reachable from serverless compute by default. `dbx-proxy` provides a controlled entry point for [private connectivity to resources in your VPC/Vnet](https://docs.databricks.com/aws/en/security/network/serverless-network-security/pl-to-internal-network).

![](resources/img/overview.png)

Connectivity to your custom resources can be configured via a dedicated Private Endpoint that is connected to a Network Load Balancer (AWS) in your network. From there on you can route traffic accordingly to targets. However, this approach comes with certain limiations for routing of network traffic due to limitations of cloud-provider offerings, e.g. a NLB on AWS does only operate on Layer 4 of the TCP/IP stack, allowing traffic to be routed only by IP/Port. `dbx-proxy` solves this problem by introducing an additional component which receives all traffic from your NLB and takes over the routing logic for individual targets based on your configuration. It is able to operate on Layer 4 & 7 providing greater flexibility for reaching your targets from Databricks Serverless compute.


### What you get

- **Forwarding of L4 & L7 network traffic** based on your configuration
  - L4 (TCP): forwarding of plain TCP traffic, e.g. for databases
  - L7 (HTTP) forwarding of HTTP(s) traffic with **SNI-based routing**, e.g. for applications/APIS
- **Terraform module** ready to use (currently **AWS only**)
- No TLS termination, only passthrough!

### High availability (overview)

`dbx-proxy` is placed behind an AWS Network Load Balancer, which spreads connections across the instances in the Auto Scaling Group. Availability depends on how many instances you run and whether your subnets span multiple AZs. See the Terraform module details for configuration and behavior: [High availability (AWS)](terraform/README.md#high-availability-aws).

### Deployment (Terraform) / How to use

`dbx-proxy` essentially provides Steps 1 and 2 when following the official Databricks documentation for private connectivity to resources in your own networks:
- [(AWS) Configure private connectivity to resources in your VPC](https://docs.databricks.com/aws/en/security/network/serverless-network-security/pl-to-internal-network)


Include the module in your Terraform stack:
```hcl
module "dbx_proxy" {

  source = "github.com/dnks0/dbx-proxy//terraform/aws?ref=v<release>"

  # aws config
  region    = "eu-central-1"
  tags      = {}
  ...

  # dbx-proxy config
  dbx_proxy_image_version = "<release>"
  dbx_proxy_health_port   = 8080

  # Example: forward TCP/443 to a private target in your VPC
  dbx_proxy_listener = [
    {
      name  = "http-443"
      mode  = "http"
      port  = 443
      routes = [
        {
          name    = "example"
          domains = ["example.internal"]
          destinations = [
            { name = "example-server-1", host = "10.0.1.10", port = 443 },
          ]
        }
      ]
    }
  ]
}
```

More details about the Terraform module and configurations can be found [here](terraform/README.md).

You will still need to configure the Databricks-side objects like NCC, private endpoint rules and accept the connection on your endpoint-service.

By default the module runs in `deployment_mode = "bootstrap"` and can create networking and the NLB/endpoint service. If you already have networking use `deployment_mode = "bootstrap"` and provide `vpc_id`, and `subnet_ids`. If you already have networking/NLB, set `deployment_mode = "proxy-only"` and provide `vpc_id`, `subnet_ids`, and `nlb_arn` (see Terraform docs for details).

### Troubleshooting

To validate that the proxy is up and reachable,run the following from a serverless notebook:

```bash
%sh

curl -sS -w '\nHTTP %{http_code}\n' http://<ncc-endpoint-rule-domain>:8080/status
```

### Limitations / Trade-Offs
Before going to production, please review the following [limitations & trade-offs](terraform/README.md#limitations--tradeoffs-of-the-current-implementation).