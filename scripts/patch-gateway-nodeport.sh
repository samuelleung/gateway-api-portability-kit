

#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-echo}"
SERVICE_NAME="${2:-echo-gateway-nginx}"
NODE_PORT="${3:-30080}"
PORT_INDEX="${PORT_INDEX:-0}"

log() {
  echo "[patch-gateway-nodeport] $*"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/patch-gateway-nodeport.sh [namespace] [service-name] [node-port]

Defaults:
  namespace:    echo
  service-name: echo-gateway-nginx
  node-port:    30080

Examples:
  ./scripts/patch-gateway-nodeport.sh
  ./scripts/patch-gateway-nodeport.sh echo echo-gateway-nginx 30080
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but was not found in PATH." >&2
    exit 1
  fi
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "help" ]; then
  usage
  exit 0
fi

require_command kubectl

if ! [[ "${NODE_PORT}" =~ ^[0-9]+$ ]]; then
  echo "Error: node-port must be a number: ${NODE_PORT}" >&2
  exit 1
fi

if [ "${NODE_PORT}" -lt 30000 ] || [ "${NODE_PORT}" -gt 32767 ]; then
  echo "Error: node-port must be within the default Kubernetes NodePort range 30000-32767: ${NODE_PORT}" >&2
  exit 1
fi

log "Namespace: ${NAMESPACE}"
log "Service: ${SERVICE_NAME}"
log "Target NodePort: ${NODE_PORT}"

if ! kubectl -n "${NAMESPACE}" get svc "${SERVICE_NAME}" >/dev/null 2>&1; then
  echo "Error: service not found: ${NAMESPACE}/${SERVICE_NAME}" >&2
  echo
  echo "Available services in namespace '${NAMESPACE}':" >&2
  kubectl -n "${NAMESPACE}" get svc >&2 || true
  exit 1
fi

CURRENT_TYPE="$(kubectl -n "${NAMESPACE}" get svc "${SERVICE_NAME}" -o jsonpath='{.spec.type}')"
CURRENT_NODE_PORT="$(kubectl -n "${NAMESPACE}" get svc "${SERVICE_NAME}" -o jsonpath="{.spec.ports[${PORT_INDEX}].nodePort}" 2>/dev/null || true)"

log "Current service type: ${CURRENT_TYPE}"
if [ -n "${CURRENT_NODE_PORT}" ]; then
  log "Current NodePort: ${CURRENT_NODE_PORT}"
else
  log "Current NodePort: <none>"
fi

if [ "${CURRENT_TYPE}" != "NodePort" ] && [ "${CURRENT_TYPE}" != "LoadBalancer" ]; then
  log "Service is not NodePort/LoadBalancer. Patching type to NodePort first."
  kubectl -n "${NAMESPACE}" patch svc "${SERVICE_NAME}" \
    --type='json' \
    -p='[{"op":"replace","path":"/spec/type","value":"NodePort"}]'
fi

if [ "${CURRENT_NODE_PORT}" = "${NODE_PORT}" ]; then
  log "Service already uses NodePort ${NODE_PORT}. No patch needed."
else
  log "Patching service NodePort to ${NODE_PORT}"
  kubectl -n "${NAMESPACE}" patch svc "${SERVICE_NAME}" \
    --type='json' \
    -p="[{\"op\":\"replace\",\"path\":\"/spec/ports/${PORT_INDEX}/nodePort\",\"value\":${NODE_PORT}}]"
fi

log "Patched service:"
kubectl -n "${NAMESPACE}" get svc "${SERVICE_NAME}"

log "Test command:"
echo "  curl -H \"Host: echo.localtest.me\" http://localhost:8080"