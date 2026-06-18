

#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-ingress-nginx}"
RELEASE_NAME="${RELEASE_NAME:-ingress-nginx}"
CHART_REPO_NAME="${CHART_REPO_NAME:-ingress-nginx}"
CHART_REPO_URL="${CHART_REPO_URL:-https://kubernetes.github.io/ingress-nginx}"
HTTP_NODE_PORT="${HTTP_NODE_PORT:-30080}"
HTTPS_NODE_PORT="${HTTPS_NODE_PORT:-30443}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180s}"

log() {
  echo "[ingress-nginx] $*"
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but was not found in PATH." >&2
    exit 1
  fi
}

require_command kubectl
require_command helm

log "Installing ingress-nginx baseline controller"
log "Namespace: ${NAMESPACE}"
log "HTTP NodePort: ${HTTP_NODE_PORT}"
log "HTTPS NodePort: ${HTTPS_NODE_PORT}"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm repo add "${CHART_REPO_NAME}" "${CHART_REPO_URL}" >/dev/null
helm repo update "${CHART_REPO_NAME}" >/dev/null

helm upgrade --install "${RELEASE_NAME}" "${CHART_REPO_NAME}/ingress-nginx" \
  --namespace "${NAMESPACE}" \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.enabled=true \
  --set controller.ingressClassResource.default=false \
  --set controller.ingressClass=nginx \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http="${HTTP_NODE_PORT}" \
  --set controller.service.nodePorts.https="${HTTPS_NODE_PORT}" \
  --set controller.watchIngressWithoutClass=false

log "Waiting for ingress-nginx controller rollout"
kubectl -n "${NAMESPACE}" rollout status deployment/"${RELEASE_NAME}-controller" --timeout="${WAIT_TIMEOUT}"

log "Controller pods:"
kubectl -n "${NAMESPACE}" get pods -o wide

log "Controller service:"
kubectl -n "${NAMESPACE}" get svc "${RELEASE_NAME}-controller"

log "IngressClass:"
kubectl get ingressclass nginx || true

log "ingress-nginx baseline is ready."
log "Local test ports depend on scripts/create-cluster.sh mapping:"
echo "  http://localhost:8080  -> node:${HTTP_NODE_PORT}"
echo "  https://localhost:8443 -> node:${HTTPS_NODE_PORT}"