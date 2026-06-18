
#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gateway-api-lab}"
HTTP_PORT="${HTTP_PORT:-8080}"
HTTPS_PORT="${HTTPS_PORT:-8443}"
NODE_HTTP_PORT="${NODE_HTTP_PORT:-30080}"
NODE_HTTPS_PORT="${NODE_HTTPS_PORT:-30443}"

log() {
  echo "[create-cluster] $*"
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but was not found in PATH." >&2
    exit 1
  fi
}

require_command kind
require_command kubectl

if ! command -v docker >/dev/null 2>&1; then
  log "Warning: docker was not found in PATH. kind requires a working container runtime."
fi

if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  log "Cluster '${CLUSTER_NAME}' already exists."
  log "Using existing context: kind-${CLUSTER_NAME}"
  kubectl cluster-info --context "kind-${CLUSTER_NAME}"
  exit 0
fi

log "Creating kind cluster: ${CLUSTER_NAME}"
log "HTTP  will map localhost:${HTTP_PORT}  -> node:${NODE_HTTP_PORT}"
log "HTTPS will map localhost:${HTTPS_PORT} -> node:${NODE_HTTPS_PORT}"

cat <<KIND_CONFIG | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: ${NODE_HTTP_PORT}
        hostPort: ${HTTP_PORT}
        protocol: TCP
      - containerPort: ${NODE_HTTPS_PORT}
        hostPort: ${HTTPS_PORT}
        protocol: TCP
KIND_CONFIG

log "Cluster created."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

log "Current nodes:"
kubectl --context "kind-${CLUSTER_NAME}" get nodes -o wide

log "Next steps:"
echo "  ./scripts/install-controller.sh ingress-nginx"
echo "  ./scripts/apply-example.sh 00-ingress-nginx-baseline"
echo "  ./scripts/test-routes.sh"
