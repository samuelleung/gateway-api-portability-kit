

# Lab 01: Basic HTTPRoute

This lab validates the simplest Gateway API HTTP routing flow using Traefik as the first reference controller.

The goal is to keep the application and routing manifests based on standard Gateway API resources, while keeping Traefik-specific setup in the controller installation script.

## What this lab demonstrates

This lab routes an HTTP request through:

```text
Gateway
  -> HTTPRoute
  -> Kubernetes Service
  -> Pod
```

The backend application is `traefik/whoami`.

## Files in this lab

| File | Purpose |
|---|---|
| `app.yaml` | Creates the `demo` namespace, `whoami` Deployment, and `whoami` Service. |
| `gateway.yaml` | Creates the `GatewayClass` and `Gateway`. |
| `httproute.yaml` | Creates the `HTTPRoute` that routes traffic to the `whoami` Service. |

## Prerequisites

From the repository root, create the local kind cluster and install Traefik first:

```bash
./scripts/create-cluster.sh
./scripts/install-controller.sh traefik
```

The Traefik install flow handles:

```text
Gateway API CRDs
Traefik Helm installation
Gateway API RBAC for Traefik
Traefik pod recreation
```

## Run the lab

From the repository root:

```bash
./scripts/apply-example.sh 01-basic-http-route
./scripts/test-routes.sh
```

Expected response:

```text
HTTP/1.1 200 OK
Hostname: whoami-...
```

## Validate Gateway API status

```bash
kubectl get gatewayclass
kubectl get gateway -n demo
kubectl get httproute -n demo
```

Expected status:

```text
GatewayClass ACCEPTED=True
Gateway      PROGRAMMED=True
HTTPRoute    created
```

## Request flow

The local test URL is:

```text
http://localhost:8080
```

The request path is:

```text
localhost:8080
  -> kind host-port mapping
  -> Traefik NodePort 30080
  -> Traefik web entryPoint
  -> Gateway listener port 8000
  -> HTTPRoute
  -> demo/whoami service
  -> whoami pod
```

## Key Gateway API resources

### GatewayClass

`GatewayClass` tells Kubernetes which Gateway API controller should handle this Gateway.

For this lab, the controller is Traefik:

```text
traefik.io/gateway-controller
```

### Gateway

`Gateway` defines the traffic entry point.

For this lab, the Gateway listener uses:

```text
protocol: HTTP
port: 8000
```

Port `8000` matches Traefik's internal `web` entryPoint in the Helm deployment.

### HTTPRoute

`HTTPRoute` attaches to the Gateway and forwards requests to the `whoami` Service.

This is the core portable routing object in the lab.

## Portability notes

The application, Gateway, and HTTPRoute model are based on Gateway API concepts and should remain as portable as possible.

Traefik-specific behaviour is handled outside this lab by:

```text
controllers/traefik/install.sh
```

Current Traefik-specific details include:

```text
Gateway API experimental CRDs
additional Gateway API RBAC
NodePort exposure
Gateway listener port 8000
Traefik pod recreation after applying resources
```

When this lab is tested against another controller, the shared routing goal should stay the same, but controller setup and listener port mapping may differ.

## Troubleshooting

### The route returns 404

Check Gateway API status:

```bash
kubectl get gatewayclass
kubectl get gateway -n demo
kubectl get httproute -n demo
```

If the Gateway is not `PROGRAMMED=True`, check Traefik logs:

```bash
kubectl -n traefik logs deploy/traefik --tail=200
```

### The first curl fails but the next one works

Traefik may need a few seconds after the pod becomes ready to finish loading Gateway API configuration.

The test script includes retry logic for this reason.

### The route still does not work

Recreate the Traefik pod and test again:

```bash
kubectl delete pod -n traefik -l app.kubernetes.io/name=traefik
kubectl rollout status deployment/traefik -n traefik --timeout=180s
./scripts/test-routes.sh
```

## Clean up

Delete the full local cluster:

```bash
./scripts/delete-cluster.sh
```