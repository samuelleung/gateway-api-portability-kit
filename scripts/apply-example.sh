#!/usr/bin/env bash
set -euo pipefail

EXAMPLE="${1:-}"

if [ -z "$EXAMPLE" ]; then
  echo "Usage: ./scripts/apply-example.sh <example-name>"
  echo "Example: ./scripts/apply-example.sh 01-basic-http-route"
  exit 1
fi

EXAMPLE_DIR="examples/${EXAMPLE}"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "Example not found: ${EXAMPLE_DIR}"
  exit 1
fi

echo "Applying example: ${EXAMPLE}"

kubectl apply -f "${EXAMPLE_DIR}/app.yaml"
kubectl apply -f "${EXAMPLE_DIR}/gateway.yaml"
kubectl apply -f "${EXAMPLE_DIR}/httproute.yaml"

echo "Recreating Traefik pod so Gateway API resources are picked up..."
kubectl delete pod -n traefik -l app.kubernetes.io/name=traefik --ignore-not-found=true
kubectl rollout status deployment/traefik -n traefik --timeout=180s

echo "Applied example: ${EXAMPLE}"
