locals {
  prefix = var.prefix == null ? "dbx-proxy-${random_string.this.result}" : "${var.prefix}-dbx-proxy-${random_string.this.result}"

  tags = merge(
    {
      "Component" = local.prefix
      "ManagedBy" = "terraform"
    },
    var.tags,
  )

  vpc_id             = var.vpc_id != null ? var.vpc_id : aws_vpc.this[0].id
  subnet_ids         = length(var.subnet_ids) > 0 ? var.subnet_ids : [for s in aws_subnet.this : s.id]
  subnet_cidr_blocks = length(var.subnet_ids) > 0 ? [for s in values(data.aws_subnet.this) : s.cidr_block] : [for s in aws_subnet.this : s.cidr_block]

  allowed_principals = [
    "arn:aws:iam::565502421330:role/private-connectivity-role-${var.region}"
  ]

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
