services:
  dbx-proxy:
    image: "ghcr.io/dnks0/dbx-proxy/proxy:${dbx_proxy_image_version}"
    container_name: "dbx-proxy"
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - DBX_PROXY_HEALTH_PORT=${dbx_proxy_health_port}
    ports:
      - "${dbx_proxy_health_port}:${dbx_proxy_health_port}"
%{ for listener in dbx_proxy_listener ~}
      - "${listener.port}:${listener.port}"
%{ endfor ~}
    volumes:
      - /dbx-proxy/conf:/dbx-proxy/conf:rw
      - dbx-proxy-run:/dbx-proxy/run

    restart: unless-stopped

volumes:
    dbx-proxy-run: {}
