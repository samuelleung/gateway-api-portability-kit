

#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-nginx-gateway}"
RELEASE_NAME="${RELEASE_NAME:-ngf}"
CHART_REF="${CHART_REF:-oci://ghcr.io/nginx/charts/nginx-gateway-fabric}"
GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.3.0}"
GATEWAY_API_CRD_URL="${GATEWAY_API_CRD_URL:-https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180s}"

log() {
  echo "[nginx-gateway-fabric] $*"
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

log "Installing NGINX Gateway Fabric"
log "Namespace: ${NAMESPACE}"
log "Release: ${RELEASE_NAME}"
log "Chart: ${CHART_REF}"
log "Gateway API CRDs: ${GATEWAY_API_CRD_URL}"

log "Installing Gateway API standard CRDs first"
kubectl apply -f "${GATEWAY_API_CRD_URL}"

log "Waiting for Gateway API CRDs to be established"
kubectl wait --for=condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout="${WAIT_TIMEOUT}"
kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io --timeout="${WAIT_TIMEOUT}"
kubectl wait --for=condition=Established crd/httproutes.gateway.networking.k8s.io --timeout="${WAIT_TIMEOUT}"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install "${RELEASE_NAME}" "${CHART_REF}" \
  --namespace "${NAMESPACE}" \
  --wait \
  --timeout "${WAIT_TIMEOUT}"

log "Waiting for NGINX Gateway Fabric controller deployment"
if kubectl -n "${NAMESPACE}" get deployment "${RELEASE_NAME}-nginx-gateway-fabric" >/dev/null 2>&1; then
  kubectl -n "${NAMESPACE}" rollout status deployment/"${RELEASE_NAME}-nginx-gateway-fabric" --timeout="${WAIT_TIMEOUT}"
elif kubectl -n "${NAMESPACE}" get deployment nginx-gateway >/dev/null 2>&1; then
  kubectl -n "${NAMESPACE}" rollout status deployment/nginx-gateway --timeout="${WAIT_TIMEOUT}"
else
  log "Controller deployment name was not recognised. Showing deployments for inspection:"
  kubectl -n "${NAMESPACE}" get deployment
fi

log "Controller pods:"
kubectl -n "${NAMESPACE}" get pods -o wide

log "Gateway API CRDs:"
kubectl get crd gateways.gateway.networking.k8s.io httproutes.gateway.networking.k8s.io gatewayclasses.gateway.networking.k8s.io

log "GatewayClass resources:"
kubectl get gatewayclass || true

log "NGINX Gateway Fabric installation completed."
log "Next steps:"
echo "  ./scripts/apply-example.sh 01-basic-http-route"
echo "  kubectl -n echo get gateway,httproute"
echo "  kubectl get gatewayclass"