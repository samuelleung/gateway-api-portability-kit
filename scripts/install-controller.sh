#!/usr/bin/env bash
set -euo pipefail

CONTROLLER="${1:-}"

if [ -z "${CONTROLLER}" ]; then
  echo "Usage: ./scripts/install-controller.sh <controller>"
  echo
  echo "Available controllers:"
  echo "  traefik"
  echo "  envoy-gateway    # not implemented yet"
  echo "  nginx-gateway-fabric # not implemented yet"
  exit 1
fi

case "${CONTROLLER}" in
  traefik)
    ./controllers/traefik/install.sh
    ;;
  envoy-gateway)
    echo "Envoy Gateway installer is not implemented yet."
    exit 1
    ;;
  nginx-gateway-fabric)
    echo "NGINX Gateway Fabric installer is not implemented yet."
    exit 1
    ;;
  *)
    echo "Unknown controller: ${CONTROLLER}"
    exit 1
    ;;
esac
