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

log "INFO" "validating initial configuration at ${CONFIG} ..."
haproxy -c -f "${CONFIG}"

log "INFO" "starting dbx-proxy ..."
exec haproxy -Ws -db -f "${CONFIG}" -p "${PID}"
