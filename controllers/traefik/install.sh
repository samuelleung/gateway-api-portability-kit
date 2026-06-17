#!/usr/bin/env bash
set -euo pipefail

echo "Installing Gateway API CRDs..."
kubectl apply --server-side --force-conflicts \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/experimental-install.yaml

echo "Adding Traefik Helm repo..."
helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
helm repo update

echo "Installing Traefik..."
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set providers.kubernetesGateway.enabled=true \
  --set gateway.enabled=false \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443

echo "Waiting for Traefik deployment..."
kubectl rollout status deployment/traefik -n traefik --timeout=180s

echo "Applying additional Gateway API status RBAC for Traefik..."
kubectl apply -f - <<'RBAC'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik-gateway-api-status
rules:
  - apiGroups:
      - gateway.networking.k8s.io
    resources:
      - gatewayclasses
      - gateways
      - httproutes
      - grpcroutes
      - tlsroutes
      - tcproutes
      - udproutes
      - referencegrants
      - backendtlspolicies
      - gatewayclasses/status
      - gateways/status
      - httproutes/status
      - grpcroutes/status
      - tlsroutes/status
      - tcproutes/status
      - udproutes/status
      - backendtlspolicies/status
    verbs:
      - get
      - list
      - watch
      - update
      - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-gateway-api-status
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-gateway-api-status
subjects:
  - kind: ServiceAccount
    name: traefik
    namespace: traefik
RBAC

echo "Recreating Traefik pod so CRDs/RBAC are picked up..."
kubectl delete pod -n traefik -l app.kubernetes.io/name=traefik --ignore-not-found=true
kubectl rollout status deployment/traefik -n traefik --timeout=180s

echo "Verifying Gateway API status RBAC..."
kubectl auth can-i update gatewayclasses/status \
  --as=system:serviceaccount:traefik:traefik

kubectl auth can-i update gateways/status \
  --as=system:serviceaccount:traefik:traefik \
  -n default

kubectl auth can-i update httproutes/status \
  --as=system:serviceaccount:traefik:traefik \
  -n default

echo "Traefik Gateway API controller installed."
