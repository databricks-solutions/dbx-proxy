locals {
  dbx_proxy_max_connections_by_cpu = 2 * 4000         # assumes rather conservative 4000 connections per vCPU
  dbx_proxy_max_connections_by_mem = floor(4096 * 50) # assumes 1MiB / 50 ~= 20 KB per connection
  dbx_proxy_max_connections = var.dbx_proxy_max_connections != null ? var.dbx_proxy_max_connections : max(
    2000,
    min(local.dbx_proxy_max_connections_by_cpu, local.dbx_proxy_max_connections_by_mem),
  ) # floor at 2000 to avoid tiny defaults at small instances

  cloud_config = {
    write_files = [
      {
        path        = "/dbx-proxy/conf/dbx-proxy.cfg"
        owner       = "root:root"
        permissions = "0644"
        content     = module.common.dbx_proxy_cfg
      },
      {
        path        = "/dbx-proxy/docker-compose.yaml"
        owner       = "root:root"
        permissions = "0644"
        content     = module.common.docker_compose
      },
      {
        path        = "/etc/systemd/system/dbx-proxy.service"
        owner       = "root:root"
        permissions = "0644"
        content     = <<-EOT
        [Unit]
        Description=dbx-proxy (docker compose)
        Requires=docker.service
        After=docker.service network-online.target
        Wants=network-online.target

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        WorkingDirectory=/dbx-proxy
        ExecStart=/usr/bin/docker compose --file /dbx-proxy/docker-compose.yaml up --detach
        ExecStop=/usr/bin/docker compose --file /dbx-proxy/docker-compose.yaml down
        TimeoutStartSec=0

        [Install]
        WantedBy=multi-user.target
        EOT
      },
    ]
    runcmd = [
      [
        "bash",
        "-c",
        "set -euxo pipefail; sudo dnf update -y || sudo yum update -y || sudo apt-get update -y",
      ],
      [
        "bash",
        "-c",
        "set -euxo pipefail; (sudo dnf install -y docker || sudo yum install -y docker || sudo apt-get install -y docker.io)",
      ],
      [
        "bash",
        "-c",
        "set -euxo pipefail; sudo systemctl enable docker; sudo systemctl start docker",
      ],
      [
        "bash",
        "-c",
        "set -euxo pipefail; sudo mkdir -p /usr/libexec/docker/cli-plugins; sudo curl -sSL \"https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)\" -o /usr/libexec/docker/cli-plugins/docker-compose; sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose; sudo systemctl restart docker",
      ],
      [
        "bash",
        "-c",
        "set -euxo pipefail; sudo systemctl daemon-reload; sudo systemctl enable --now dbx-proxy.service",
      ],
    ]
  }
}
