
#!/usr/bin/env bash
set -euo pipefail

CONTROLLER="${1:-}"

log() {
  echo "[install-controller] $*"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install-controller.sh <controller>

Available controllers:
  ingress-nginx           Install the ingress-nginx baseline controller
  nginx-gateway-fabric    Install NGINX Gateway Fabric as the first Gateway API target
  traefik                 Install Traefik Gateway API controller
  cilium                  Install Cilium Gateway API controller
  envoy-gateway           Install Envoy Gateway controller

Examples:
  ./scripts/install-controller.sh ingress-nginx
  ./scripts/install-controller.sh nginx-gateway-fabric
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but was not found in PATH." >&2
    exit 1
  fi
}

run_installer() {
  local controller="$1"
  local installer="./controllers/${controller}/install.sh"

  if [ ! -f "${installer}" ]; then
    echo "Error: installer not found: ${installer}" >&2
    echo
    echo "Create this file first, or choose one of the implemented controllers."
    exit 1
  fi

  if [ ! -x "${installer}" ]; then
    log "Making installer executable: ${installer}"
    chmod +x "${installer}"
  fi

  log "Installing controller: ${controller}"
  "${installer}"
  log "Controller installation completed: ${controller}"
}

if [ -z "${CONTROLLER}" ]; then
  usage
  exit 1
fi

require_command kubectl

case "${CONTROLLER}" in
  ingress-nginx)
    run_installer "ingress-nginx"
    ;;
  nginx-gateway-fabric)
    run_installer "nginx-gateway-fabric"
    ;;
  traefik)
    run_installer "traefik"
    ;;
  cilium)
    run_installer "cilium"
    ;;
  envoy-gateway)
    run_installer "envoy-gateway"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Error: unknown controller: ${CONTROLLER}" >&2
    echo
    usage
    exit 1
    ;;
esac
