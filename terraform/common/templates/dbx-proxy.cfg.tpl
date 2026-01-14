global
    log stdout format raw local0 info
    stats socket /dbx-proxy/run/admin.sock user haproxy group dbx-proxy mode 660 level admin expose-fd listeners
    stats timeout 30s
    maxconn 8192

defaults
    log     global
    mode    tcp
    option  tcplog
    timeout connect 5s
    timeout client  30s
    timeout server  30s
    default-server init-addr last,libc,none


#
# default health-check listener
#
frontend health
    bind *:${dbx_proxy_health_port}
    mode http
    option http-keep-alive
    http-request return status 404 unless { path -i /status }
    http-request return status 200 content-type application/json string '{"detail":"HEALTHY"}'


%{ for listener in dbx_proxy_listener ~}
%{   if lower(listener.mode) == "http" ~}
#
# listener ${listener.name} (mode=http, tls passthrough + sni routing)
#
frontend ${listener.name}_fe
    bind *:${listener.port}
    mode tcp

    # inspect the tls clienthello to extract sni
    tcp-request inspect-delay 5s
    tcp-request content accept if { req_ssl_hello_type 1 }

    # route based on sni hostname
%{     for route in listener.routes ~}
%{       for dom in route.domains ~}
    acl sni_${listener.name}_${route.name} req_ssl_sni -i ${dom}
%{       endfor ~}
%{     endfor ~}

%{     for route in listener.routes ~}
    use_backend ${listener.name}_${route.name}_be if sni_${listener.name}_${route.name}
%{     endfor ~}
    default_backend default_be

%{     for route in listener.routes ~}
backend ${listener.name}_${route.name}_be
    mode tcp
%{       for d_idx in range(length(route.destinations)) ~}
    server %{ if route.destinations[d_idx].name != "" }${route.destinations[d_idx].name}%{ else }${listener.name}_${route.name}_${d_idx + 1}%{ endif } ${route.destinations[d_idx].host}:${route.destinations[d_idx].port}
%{       endfor ~}

%{     endfor ~}

%{   else ~}
#
# listener ${listener.name} (mode=tcp)
#
frontend ${listener.name}_fe
    bind *:${listener.port}
    mode tcp
    default_backend ${listener.name}_be

backend ${listener.name}_be
    mode tcp
%{     for r_idx in range(length(listener.routes)) ~}
%{       for d_idx in range(length(listener.routes[r_idx].destinations)) ~}
    # ensure unique server names even if route names repeat
    server %{ if listener.routes[r_idx].destinations[d_idx].name != "" }${listener.routes[r_idx].destinations[d_idx].name}%{ else }${listener.name}_${r_idx + 1}_${d_idx + 1}%{ endif } ${listener.routes[r_idx].destinations[d_idx].host}:${listener.routes[r_idx].destinations[d_idx].port}
%{       endfor ~}
%{     endfor ~}

%{   endif ~}
%{ endfor ~}

#
# default blackhole backend used as fallback for http listener
#
backend default_be
    mode tcp
    server blackhole 127.0.0.1:9 disabled

