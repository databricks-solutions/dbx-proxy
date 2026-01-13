prefix="dnks"
region="eu-central-1"
tags={}

# AWS resources
instance_type="t3.small"
min_instances=2
desired_capacity=2
max_instances=2

# dbx-proxy configuration
dbx_proxy_health_port=8080
dbx_proxy_http_port=8000
dbx_proxy_broadcast_port=50000
dbx_proxy_broadcast_heartbeat_interval=2
dbx_proxy_broadcast_suspect_timeout=5
dbx_proxy_broadcast_dead_timeout=15
dbx_proxy_broadcast_ping_timeout=1
dbx_proxy_listeners=[]
