#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-echo}"
CONTROLLER="${CONTROLLER:-nginx-gateway-fabric}"
SKIP_CLUSTER=false
SKIP_CONTROLLER=false
SKIP_NAMESPACE=false
VERIFY=true

log() {
  echo "[create-lab] $*"
}

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/create-lab.sh [options]

Options:
  -n, --namespace <namespace>   Shared lab namespace to create. Default: echo
  -c, --controller <controller>  Gateway/Ingress controller to install. Default: nginx-gateway-fabric
  --skip-cluster                Do not run scripts/create-cluster.sh
  --skip-controller             Do not run scripts/install-controller.sh
  --skip-namespace              Do not create the shared namespace
  --no-verify                   Skip post-setup verification
  -h, --help                    Show this help message

Environment variables:
  NAMESPACE                     Shared lab namespace. Default: echo
  CONTROLLER                    Controller to install. Default: nginx-gateway-fabric

Purpose:
  Prepare the common local lab environment once.

This script is intentionally separate from apply-example.sh.

create-lab.sh:
  Creates or verifies the shared lab environment.

apply-example.sh:
  Applies one independent lab.

delete-example.sh:
  Deletes one independent lab.

delete-cluster.sh:
  Destroys the whole local cluster.
USAGE
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but was not found in PATH." >&2
    exit 1
  fi
}

run_if_exists() {
  local script="$1"
  shift || true

  if [ ! -x "${script}" ]; then
    echo "Error: required script is missing or not executable: ${script}" >&2
    echo "Fix with: chmod +x ${script}" >&2
    exit 1
  fi

  "${script}" "$@"
}

verify_lab() {
  if [ "${VERIFY}" != "true" ]; then
    return 0
  fi

  log "Verifying lab environment"

  echo
  echo "Namespaces:"
  kubectl get ns

  echo
  echo "GatewayClasses:"
  kubectl get gatewayclass 2>/dev/null || true

  echo
  echo "Gateway API CRDs:"
  kubectl get crd 2>/dev/null | grep 'gateway.networking.k8s.io' || true

  echo
  echo "Controller pods:"
  kubectl get pods -A | grep -E 'nginx-gateway|gateway|traefik|envoy|cilium' || true

  echo
  echo "Shared namespace resources:"
  kubectl -n "${NAMESPACE}" get all,gateway,httproute 2>/dev/null || true
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -n|--namespace)
      if [ -z "${2:-}" ]; then
        echo "Error: --namespace requires a value." >&2
        exit 1
      fi
      NAMESPACE="$2"
      shift 2
      ;;
    -c|--controller)
      if [ -z "${2:-}" ]; then
        echo "Error: --controller requires a value." >&2
        exit 1
      fi
      CONTROLLER="$2"
      shift 2
      ;;
    --skip-cluster)
      SKIP_CLUSTER=true
      shift
      ;;
    --skip-controller)
      SKIP_CONTROLLER=true
      shift
      ;;
    --skip-namespace)
      SKIP_NAMESPACE=true
      shift
      ;;
    --no-verify)
      VERIFY=false
      shift
      ;;
    --*)
      echo "Error: unknown option: $1" >&2
      echo
      usage
      exit 1
      ;;
    *)
      echo "Error: unexpected argument: $1" >&2
      echo
      usage
      exit 1
      ;;
  esac
done

require_command kubectl

log "Preparing Gateway API lab environment"
log "Shared namespace: ${NAMESPACE}"
log "Controller: ${CONTROLLER}"

if [ "${SKIP_CLUSTER}" != "true" ]; then
  log "Creating or verifying local cluster"
  run_if_exists "./scripts/create-cluster.sh"
else
  log "Skipping cluster creation"
fi

if [ "${SKIP_CONTROLLER}" != "true" ]; then
  log "Installing or verifying controller: ${CONTROLLER}"
  run_if_exists "./scripts/install-controller.sh" "${CONTROLLER}"
else
  log "Skipping controller installation"
fi

if [ "${SKIP_NAMESPACE}" != "true" ]; then
  log "Creating shared namespace if missing: ${NAMESPACE}"
  kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
  log "Shared namespace is managed by create-lab.sh, not by individual examples."
else
  log "Skipping namespace creation"
fi

verify_lab

log "Lab environment is ready"