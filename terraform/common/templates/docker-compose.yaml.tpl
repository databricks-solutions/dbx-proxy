services:
  dbx-proxy:
    image: "ghcr.io/dnks0/dbx-proxy/dbx-proxy:0.1.0"
    container_name: "dbx-proxy"
    environment:
      - DBX_PROXY_HEALTH_PORT=${dbx_proxy_health_port}
    volumes:
      - /dbx-proxy/conf:/dbx-proxy/conf:rw
      - dbx-proxy-run:/dbx-proxy/run
    network_mode: "host"

volumes:
    dbx-proxy-run: {}
