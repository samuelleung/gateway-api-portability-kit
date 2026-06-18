#!/usr/bin/env bash
set -euo pipefail

EXAMPLE="${1:-}"
EXAMPLES_ROOT="${EXAMPLES_ROOT:-examples}"

log() {
  echo "[apply-example] $*"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/apply-example.sh <example-name>

Examples:
  ./scripts/apply-example.sh 00-ingress-nginx-baseline
  ./scripts/apply-example.sh 01-basic-http-route
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but was not found in PATH." >&2
    exit 1
  fi
}

if [ -z "${EXAMPLE}" ]; then
  usage
  exit 1
fi

require_command kubectl

EXAMPLE_DIR="${EXAMPLES_ROOT}/${EXAMPLE}"

if [ ! -d "${EXAMPLE_DIR}" ]; then
  echo "Error: example not found: ${EXAMPLE_DIR}" >&2
  echo
  echo "Available examples:"
  find "${EXAMPLES_ROOT}" -maxdepth 1 -mindepth 1 -type d -print 2>/dev/null | sort | sed 's#^#  #'
  exit 1
fi

log "Applying example: ${EXAMPLE}"
log "Example directory: ${EXAMPLE_DIR}"

if find "${EXAMPLE_DIR}" -maxdepth 1 -name '*.yaml' -print -quit | grep -q .; then
  kubectl apply -f "${EXAMPLE_DIR}"
elif find "${EXAMPLE_DIR}" -maxdepth 1 -name '*.yml' -print -quit | grep -q .; then
  kubectl apply -f "${EXAMPLE_DIR}"
else
  echo "Error: no YAML manifests found in ${EXAMPLE_DIR}" >&2
  exit 1
fi

log "Applied example: ${EXAMPLE}"

log "Suggested verification commands:"
echo "  kubectl get ns"
echo "  kubectl -n echo get pods,svc,ingress,httproute,gateway 2>/dev/null || true"
echo "  curl -H \"Host: echo.localtest.me\" http://localhost:8080"
