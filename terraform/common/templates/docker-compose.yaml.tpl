services:
  dbx-proxy:
    image: "ghcr.io/dnks0/dbx-proxy/proxy:${dbx_proxy_image_version}"
    container_name: "dbx-proxy"
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - DBX_PROXY_HEALTH_PORT=${dbx_proxy_health_port}
    volumes:
      - /dbx-proxy/conf:/dbx-proxy/conf:rw
      - dbx-proxy-run:/dbx-proxy/run
    network_mode: "host"
    restart: unless-stopped

volumes:
    dbx-proxy-run: {}
