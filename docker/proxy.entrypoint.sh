#!/bin/sh
set -eu

CONFIG="/dbx-proxy/conf/dbx-proxy.cfg"
CANDIDATE_CONFIG="${CONFIG}.next"
DEFAULT_CONFIG="/dbx-proxy/etc/default.cfg"
PID="/dbx-proxy/run/dbx-proxy.pid"

STOPPED=0

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
  haproxy -Ws -f "${CONFIG}" -p "${PID}" &
}

reload_proxy() {
  if [ ! -f "${PID}" ]; then
    log "WARNING" "pid file ${PID} missing during reload, starting dbx-proxy ..."
    mv "${CANDIDATE_CONFIG}" "${CONFIG}"
    haproxy -Ws -f "${CONFIG}" -p "${PID}" &
    return
  fi

  OLD_PID="$(cat "${PID}")"
  log "INFO" "reloading dbx-proxy with new configuration (old pid=${OLD_PID}) ..."
  mv "${CANDIDATE_CONFIG}" "${CONFIG}"
  haproxy -Ws -f "${CONFIG}" -p "${PID}" -sf "${OLD_PID}" &
}

# Use initial default configuration if none exists.
if [ ! -f "${CONFIG}" ]; then
  log "INFO" "no configuration at ${CONFIG}, using fallback ${DEFAULT_CONFIG} ..."
  cp "${DEFAULT_CONFIG}" "${CONFIG}"
fi

log "INFO" "validating initial configuration at ${CONFIG} ..."
haproxy -c -f "${CONFIG}"

# Main supervisor loop (PID 1) that manages the HAProxy lifecycle.
last_mtime=""

start_proxy

log "INFO" "starting supervisor (candidate=${CANDIDATE_CONFIG}) ..."

while [ "${STOPPED}" -eq 0 ]; do
  if [ -f "${CANDIDATE_CONFIG}" ]; then
    mtime="$(stat -c %Y "${CANDIDATE_CONFIG}" 2>/dev/null || echo "")"

    if [ -n "${mtime}" ] && [ "${mtime}" != "${last_mtime}" ]; then
      last_mtime="${mtime}"

      log "INFO" "detected new candidate configuration at ${CANDIDATE_CONFIG}, validating ..."

      if ! haproxy -c -f "${CANDIDATE_CONFIG}"; then
        log "WARNING" "invalid candidate configuration, reload aborted"
        sleep 1
        continue
      fi

      reload_proxy
    fi
  fi

  sleep 1
done
