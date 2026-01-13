set -eu

PID="/dbx-proxy/run/dbx-proxy.pid"
CONFIG="/dbx-proxy/etc/default.cfg"

log() {
  # 2025-12-20 13:30:01,123 | LEVEL | message
  ts="$(date +"%Y-%m-%d %H:%M:%S,%3N")"
  lvl="$1"
  msg="$2"
  echo "$ts | $lvl | $msg"
}

graceful_stop() {
  STOPPED=1
  log "INFO" "received termination signal, stopping dbx-proxy ..."
  if [ -f "$PID" ]; then
    kill -TERM "$(cat "$PID")" 2>/dev/null || true
  fi
}

trap graceful_stop TERM INT

start_proxy() {
  if [ -f "${PID}" ]; then
    # Assume proxy is already running; do not start another instance.
    return
  fi
  log "INFO" "starting dbx-proxy ..."
  haproxy -Ws -db -f "${CONFIG}" -p "${PID}" &
}

log "INFO" "validating initial configuration at ${CONFIG} ..."
haproxy -c -f "${CONFIG}"

start_proxy
