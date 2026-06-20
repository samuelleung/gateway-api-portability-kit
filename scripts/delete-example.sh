#!/usr/bin/env bash
set -euo pipefail

EXAMPLES_ROOT="${EXAMPLES_ROOT:-examples}"
EXAMPLE=""
VERIFY_NAMESPACE="${VERIFY_NAMESPACE:-}"
VERIFY=true
DRY_RUN=false

log() {
  echo "[delete-example] $*"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/delete-example.sh <example-name-or-path> [options]

Examples:
  ./scripts/delete-example.sh 00-ingress-nginx-baseline
  ./scripts/delete-example.sh 01-basic-http-route
  ./scripts/delete-example.sh 02-routing-rules
  ./scripts/delete-example.sh examples/02-routing-rules

Options:
  -n, --namespace <namespace>   Show verification output for a specific namespace after deletion.
  --all-namespaces             Show verification output across all namespaces after deletion. This is the default.
  --no-verify                  Skip suggested verification output.
  --dry-run                    Show what kubectl would delete without deleting resources.
  -h, --help                   Show this help message.

Environment variables:
  EXAMPLES_ROOT                Examples root directory. Default: examples
  VERIFY_NAMESPACE             Namespace used for verification when --namespace is not provided.

Notes:
  - The script deletes Kubernetes resources from one example directory.
  - If kustomization.yaml is present, it runs kubectl delete -k <example-dir>.
  - Otherwise, it deletes YAML/YML manifests recursively with kubectl delete -f <example-dir> -R.
  - The script does not assume a fixed namespace such as echo.
  - Shared namespaces are not deleted unless a lab explicitly includes a Namespace manifest.
  - Deleting Lab 00 does not uninstall ingress-nginx; release NodePort 30080 before Gateway API labs if needed.
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

warn_after_ingress_baseline_delete() {
  if ! is_ingress_baseline_lab; then
    return 0
  fi

  echo
  echo "Note: Lab 00 resources were deleted, but the ingress-nginx controller was not removed."
  echo "ingress-nginx is a platform component installed by install-controller.sh, not an example resource."
  echo
  echo "If you are moving from Lab 00 to Gateway API labs, ingress-nginx may still hold NodePort 30080."
  echo "Release localhost:8080 from ingress-nginx before applying Gateway API labs with --patch-nodeport:"
  echo
  echo "  kubectl -n ingress-nginx patch svc ingress-nginx-controller -p '{\"spec\":{\"type\":\"ClusterIP\"}}'"
  echo
}

verify_after_delete() {
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

KUBECTL_DELETE_ARGS=(--ignore-not-found=true)
if [ "${DRY_RUN}" = "true" ]; then
  KUBECTL_DELETE_ARGS+=(--dry-run=client)
fi

log "Deleting example: ${EXAMPLE}"
log "Example directory: ${EXAMPLE_DIR}"

if [ "${DRY_RUN}" = "true" ]; then
  log "Dry run enabled. No resources will be deleted."
fi

if [ -f "${EXAMPLE_DIR}/kustomization.yaml" ] || [ -f "${EXAMPLE_DIR}/kustomization.yml" ]; then
  log "Detected Kustomize example. Deleting with: kubectl delete -k ${EXAMPLE_DIR}"
  kubectl delete -k "${EXAMPLE_DIR}" "${KUBECTL_DELETE_ARGS[@]}"
elif has_yaml_manifests "${EXAMPLE_DIR}"; then
  log "No kustomization.yaml found. Deleting YAML/YML manifests recursively with: kubectl delete -f ${EXAMPLE_DIR} -R"
  kubectl delete -f "${EXAMPLE_DIR}" -R "${KUBECTL_DELETE_ARGS[@]}"
else
  echo "Error: no YAML/YML manifests found in ${EXAMPLE_DIR}" >&2
  echo "This is expected for placeholder lab directories that only contain README.md." >&2
  exit 1
fi

if [ "${DRY_RUN}" = "true" ]; then
  log "Dry run completed: ${EXAMPLE}"
else
  log "Deleted example: ${EXAMPLE}"
  warn_after_ingress_baseline_delete
fi

verify_after_delete
