#!/usr/bin/env bash
set -euo pipefail

EXAMPLES_ROOT="${EXAMPLES_ROOT:-examples}"
EXAMPLE=""
VERIFY_NAMESPACE="${VERIFY_NAMESPACE:-}"
VERIFY=true
DRY_RUN=false
PATCH_NODEPORT=false
CHECK_ACTIVE=true
ASSUME_YES=false
HOSTNAME="${HOSTNAME:-echo.localtest.me}"
LOCAL_URL="${LOCAL_URL:-http://localhost:8080}"

log() {
  echo "[apply-example] $*"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/apply-example.sh <example-name-or-path> [options]

Examples:
  ./scripts/apply-example.sh 00-ingress-nginx-baseline
  ./scripts/apply-example.sh 01-basic-http-route
  ./scripts/apply-example.sh 02-routing-rules
  ./scripts/apply-example.sh examples/02-routing-rules

Options:
  -n, --namespace <namespace>   Show verification output for a specific namespace after apply.
  --all-namespaces             Show verification output across all namespaces after apply. This is the default.
  --no-verify                  Skip suggested verification output.
  --dry-run                    Show what kubectl would apply without applying resources.
  --patch-nodeport             Run ./scripts/patch-gateway-nodeport.sh after applying resources.
  --skip-active-check          Skip warning about currently active Ingress/Gateway/HTTPRoute resources.
  -y, --yes                    Continue automatically when active routing resources are detected.
  --hostname <hostname>        Host header used in the suggested curl command. Default: echo.localtest.me
  --url <url>                  URL used in the suggested curl command. Default: http://localhost:8080
  -h, --help                   Show this help message.

Environment variables:
  EXAMPLES_ROOT                Examples root directory. Default: examples
  VERIFY_NAMESPACE             Namespace used for verification when --namespace is not provided.
  HOSTNAME                     Host header used in suggested curl command.
  LOCAL_URL                    URL used in suggested curl command.

Notes:
  - The script applies Kubernetes resources from one example directory.
  - If kustomization.yaml is present, it runs kubectl apply -k <example-dir>.
  - Otherwise, it applies YAML/YML manifests recursively with kubectl apply -f <example-dir> -R.
  - The script does not assume a fixed namespace such as echo.
  - Use --patch-nodeport for local kind labs that expose the Gateway through localhost:8080.
  - By default, the script warns when another lab appears to have active routing resources.
  - Lab 00 requires ingress-nginx. Install it with: ./scripts/install-controller.sh ingress-nginx
  - Gateway API labs using --patch-nodeport require NodePort 30080 to be free.
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but was not found in PATH." >&2
    exit 1
  fi
}

resolve_example_dir() {
  local input="$1"

  if [ -d "${input}" ]; then
    printf '%s\n' "${input%/}"
    return 0
  fi

  if [ -d "${EXAMPLES_ROOT}/${input}" ]; then
    printf '%s\n' "${EXAMPLES_ROOT}/${input}"
    return 0
  fi

  return 1
}

has_yaml_manifests() {
  local dir="$1"
  find "${dir}" -type f \( -name '*.yaml' -o -name '*.yml' \) -print -quit | grep -q .
}

show_available_examples() {
  echo "Available examples:"
  find "${EXAMPLES_ROOT}" -maxdepth 1 -mindepth 1 -type d -print 2>/dev/null | sort | sed 's#^#  #'
}

example_basename() {
  basename "${EXAMPLE_DIR}"
}

is_ingress_baseline_lab() {
  [ "$(example_basename)" = "00-ingress-nginx-baseline" ]
}

is_gateway_api_lab() {
  case "$(example_basename)" in
    00-ingress-nginx-baseline)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

check_ingress_nginx_required() {
  if ! is_ingress_baseline_lab; then
    return 0
  fi

  log "Checking Lab 00 prerequisite: ingress-nginx controller"

  if kubectl get svc -n ingress-nginx ingress-nginx-controller >/dev/null 2>&1; then
    log "ingress-nginx controller service found."
    return 0
  fi

  echo "Error: Lab 00 requires ingress-nginx, but ingress-nginx-controller was not found." >&2
  echo >&2
  echo "Install the ingress baseline controller first:" >&2
  echo "  ./scripts/install-controller.sh ingress-nginx" >&2
  echo >&2
  echo "Then retry:" >&2
  echo "  ./scripts/apply-example.sh 00-ingress-nginx-baseline --namespace ${VERIFY_NAMESPACE:-echo}" >&2
  exit 1
}

check_ingress_nodeport_conflict_for_gateway_lab() {
  if ! is_gateway_api_lab; then
    return 0
  fi

  if [ "${PATCH_NODEPORT}" != "true" ]; then
    return 0
  fi

  local owner
  owner="$(kubectl get svc -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{" "}{range .spec.ports[*]}{.nodePort}{" "}{end}{"\n"}{end}' 2>/dev/null | awk '$0 ~ /(^| )30080( |$)/ {print $1; exit}')"

  if [ -z "${owner}" ]; then
    return 0
  fi

  case "${owner}" in
    */echo-gateway-nginx)
      log "NodePort 30080 is already owned by ${owner}; this may be the same Gateway lab entrypoint."
      return 0
      ;;
    ingress-nginx/ingress-nginx-controller)
      echo "Error: NodePort 30080 is currently owned by ${owner}." >&2
      echo >&2
      echo "This usually means the Lab 00 ingress-nginx baseline is still holding localhost:8080." >&2
      echo "Before running Gateway API labs with --patch-nodeport, release the ingress entrypoint:" >&2
      echo >&2
      echo "  kubectl -n ingress-nginx patch svc ingress-nginx-controller -p '{\"spec\":{\"type\":\"ClusterIP\"}}'" >&2
      echo >&2
      echo "Then retry:" >&2
      echo "  ./scripts/apply-example.sh $(example_basename) --namespace ${VERIFY_NAMESPACE:-echo} --patch-nodeport" >&2
      exit 1
      ;;
    *)
      echo "Error: NodePort 30080 is currently owned by ${owner}." >&2
      echo >&2
      echo "Only one service can use NodePort 30080 for localhost:8080 in this lab cluster." >&2
      echo "Free that service first, or run without --patch-nodeport if local port testing is not required." >&2
      exit 1
      ;;
  esac
}

show_active_routing_resources() {
  local found=false

  log "Checking for active routing resources before applying this lab."

  if kubectl get ingress -A >/dev/null 2>&1; then
    local ingress_output
    ingress_output="$(kubectl get ingress -A --no-headers 2>/dev/null || true)"
    if [ -n "${ingress_output}" ]; then
      found=true
      echo
      echo "Active Ingress resources:"
      kubectl get ingress -A
    fi
  fi

  if kubectl get gateway -A >/dev/null 2>&1; then
    local gateway_output
    gateway_output="$(kubectl get gateway -A --no-headers 2>/dev/null || true)"
    if [ -n "${gateway_output}" ]; then
      found=true
      echo
      echo "Active Gateway resources:"
      kubectl get gateway -A
    fi
  fi

  if kubectl get httproute -A >/dev/null 2>&1; then
    local httproute_output
    httproute_output="$(kubectl get httproute -A --no-headers 2>/dev/null || true)"
    if [ -n "${httproute_output}" ]; then
      found=true
      echo
      echo "Active HTTPRoute resources:"
      kubectl get httproute -A
    fi
  fi

  if [ "${found}" = "true" ]; then
    echo
    echo "Warning: active routing resources already exist in the cluster."
    echo "If they use the same hostname, listener, Gateway, or NodePort as this lab, traffic may continue to match an older lab."
    echo
    echo "Recommended before switching labs:"
    echo "  ./scripts/delete-example.sh <previous-lab> --namespace <namespace>"
    echo
    echo "If you are re-applying the same lab, it is usually safe to continue."
    return 0
  fi

  log "No active Ingress/Gateway/HTTPRoute resources found."
  return 1
}

confirm_continue_after_active_check() {
  if [ "${ASSUME_YES}" = "true" ]; then
    log "Continuing because --yes was provided."
    return 0
  fi

  if [ ! -t 0 ]; then
    echo "Error: active routing resources were detected and this is not an interactive shell." >&2
    echo "Re-run with --yes to continue, or delete the previous lab first." >&2
    exit 1
  fi

  printf "Continue applying this lab anyway? [y/N] "
  local reply
  read -r reply
  case "${reply}" in
    y|Y|yes|YES)
      log "Continuing after user confirmation."
      ;;
    *)
      echo "Aborted. Delete the previous lab first, then re-run apply-example.sh."
      exit 1
      ;;
  esac
}

verify_after_apply() {
  if [ "${VERIFY}" != "true" ]; then
    return 0
  fi

  log "Suggested verification commands:"
  echo "  kubectl get ns"

  if [ -n "${VERIFY_NAMESPACE}" ]; then
    echo "  kubectl -n ${VERIFY_NAMESPACE} get pods,svc,ingress,gateway,httproute,grpcroute,tlsroute,tcproute,udproute 2>/dev/null || true"
  else
    echo "  kubectl get pods,svc,ingress,gateway,httproute,grpcroute,tlsroute,tcproute,udproute -A 2>/dev/null || true"
  fi

  echo "  kubectl get gatewayclass 2>/dev/null || true"

  if [ -n "${HOSTNAME}" ] && [ -n "${LOCAL_URL}" ]; then
    echo "  curl -H \"Host: ${HOSTNAME}\" ${LOCAL_URL}"
  fi
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
      VERIFY_NAMESPACE="$2"
      shift 2
      ;;
    --all-namespaces)
      VERIFY_NAMESPACE=""
      shift
      ;;
    --no-verify)
      VERIFY=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --patch-nodeport)
      PATCH_NODEPORT=true
      shift
      ;;
    --skip-active-check)
      CHECK_ACTIVE=false
      shift
      ;;
    -y|--yes)
      ASSUME_YES=true
      shift
      ;;
    --hostname)
      if [ -z "${2:-}" ]; then
        echo "Error: --hostname requires a value." >&2
        exit 1
      fi
      HOSTNAME="$2"
      shift 2
      ;;
    --url)
      if [ -z "${2:-}" ]; then
        echo "Error: --url requires a value." >&2
        exit 1
      fi
      LOCAL_URL="$2"
      shift 2
      ;;
    --*)
      echo "Error: unknown option: $1" >&2
      echo
      usage
      exit 1
      ;;
    *)
      if [ -n "${EXAMPLE}" ]; then
        echo "Error: only one example name or path can be provided." >&2
        exit 1
      fi
      EXAMPLE="$1"
      shift
      ;;
  esac
done

if [ -z "${EXAMPLE}" ]; then
  usage
  exit 1
fi

require_command kubectl

if ! EXAMPLE_DIR="$(resolve_example_dir "${EXAMPLE}")"; then
  echo "Error: example not found: ${EXAMPLE}" >&2
  echo
  show_available_examples
  exit 1
fi

check_ingress_nginx_required
check_ingress_nodeport_conflict_for_gateway_lab

if [ "${CHECK_ACTIVE}" = "true" ]; then
  if show_active_routing_resources; then
    confirm_continue_after_active_check
  fi
fi

KUBECTL_APPLY_ARGS=()
if [ "${DRY_RUN}" = "true" ]; then
  KUBECTL_APPLY_ARGS+=(--dry-run=client)
fi

log "Applying example: ${EXAMPLE}"
log "Example directory: ${EXAMPLE_DIR}"

if [ "${DRY_RUN}" = "true" ]; then
  log "Dry run enabled. No resources will be applied."
fi

if [ -f "${EXAMPLE_DIR}/kustomization.yaml" ] || [ -f "${EXAMPLE_DIR}/kustomization.yml" ]; then
  log "Detected Kustomize example. Applying with: kubectl apply -k ${EXAMPLE_DIR}"
  kubectl apply -k "${EXAMPLE_DIR}" "${KUBECTL_APPLY_ARGS[@]}"
elif has_yaml_manifests "${EXAMPLE_DIR}"; then
  log "No kustomization.yaml found. Applying YAML/YML manifests recursively with: kubectl apply -f ${EXAMPLE_DIR} -R"
  kubectl apply -f "${EXAMPLE_DIR}" -R "${KUBECTL_APPLY_ARGS[@]}"
else
  echo "Error: no YAML/YML manifests found in ${EXAMPLE_DIR}" >&2
  echo "This is expected for placeholder lab directories that only contain README.md." >&2
  exit 1
fi

if [ "${PATCH_NODEPORT}" = "true" ]; then
  if [ "${DRY_RUN}" = "true" ]; then
    log "Skipping NodePort patch because dry run is enabled."
  elif [ -x "./scripts/patch-gateway-nodeport.sh" ]; then
    log "Patching Gateway service NodePort for local access."
    ./scripts/patch-gateway-nodeport.sh
  else
    echo "Error: --patch-nodeport was requested but ./scripts/patch-gateway-nodeport.sh is missing or not executable." >&2
    exit 1
  fi
fi

if [ "${DRY_RUN}" = "true" ]; then
  log "Dry run completed: ${EXAMPLE}"
else
  log "Applied example: ${EXAMPLE}"
fi

verify_after_apply
