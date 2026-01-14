ARG HAPROXY_VERSION=3.3.0
FROM haproxy:$HAPROXY_VERSION

# go root to copy files, create the necessary directories
# and then switch back to non-root.
USER root

RUN groupadd -r -g 2000 dbx-proxy \
    && usermod -a -G dbx-proxy haproxy

RUN apt-get update --fix-missing \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker/proxy.entrypoint.sh /dbx-proxy/entrypoint.sh
COPY ./docker/default.cfg /dbx-proxy/conf/default.cfg

RUN mkdir -p /dbx-proxy/conf /dbx-proxy/run /dbx-proxy/log /dbx-proxy/etc \
    && chown -R haproxy:dbx-proxy /dbx-proxy

USER haproxy

WORKDIR /dbx-proxy

ENTRYPOINT ["sh", "entrypoint.sh"]
