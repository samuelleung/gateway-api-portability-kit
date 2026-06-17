#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gateway-api-lab}"

echo "Creating kind cluster: ${CLUSTER_NAME}"

cat <<KIND_CONFIG | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 8080
        protocol: TCP
      - containerPort: 30443
        hostPort: 8443
        protocol: TCP
KIND_CONFIG

echo "Cluster created."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
