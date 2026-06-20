# 01 - Basic HTTPRoute

This lab is the first Gateway API version of the `00-ingress-nginx-baseline` lab.

The goal is to migrate the same simple HTTP routing behaviour from classic Kubernetes `Ingress` to Gateway API resources.

```text
00-ingress-nginx-baseline
  IngressClass + Ingress

01-basic-http-route
  GatewayClass + Gateway + HTTPRoute
```

## Purpose

This lab answers one migration question:

```text
Can we route the same echo application using Gateway API instead of Ingress?
```

The application should stay conceptually the same:

```text
Client
  ↓
Gateway
  ↓
HTTPRoute
  ↓
Service: echo-v1
  ↓
Pod: echo-v1
```

## Transition from Lab 00

Lab 00 uses:

```text
ingress-nginx controller
IngressClass: nginx
Ingress: echo-ingress
Host: echo.localtest.me
Service: echo-v1
```

Lab 01 should use:

```text
NGINX Gateway Fabric controller
GatewayClass
Gateway
HTTPRoute
Host: echo.localtest.me
Service: echo-v1
```

The important point is that the backend application remains the same. The routing layer changes from `Ingress` to Gateway API.

## Recommended transition flow

For the cleanest local test, use one active traffic controller at a time.

Because the local kind cluster maps `localhost:8080` to node port `30080`, both ingress-nginx and the Gateway API controller should not try to own the same NodePort at the same time.

Recommended flow from a clean cluster:

```bash
./scripts/create-cluster.sh
./scripts/install-controller.sh nginx-gateway-fabric
./scripts/apply-example.sh 01-basic-http-route
./scripts/patch-gateway-nodeport.sh
```

Then test:

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080
```

If Lab 00 is already applied in the same cluster, remove it first:

```bash
./scripts/delete-example.sh 00-ingress-nginx-baseline
```

If ingress-nginx is also installed and owns NodePort `30080`, remove or recreate the cluster before testing NGINX Gateway Fabric:

```bash
kind delete cluster --name gateway-api-lab
./scripts/create-cluster.sh
./scripts/install-controller.sh nginx-gateway-fabric
./scripts/apply-example.sh 01-basic-http-route
./scripts/patch-gateway-nodeport.sh
```

## What this example creates

| Resource | Name | Purpose |
|---|---|---|
| Namespace | `echo` | Isolates the demo application. |
| Deployment | `echo-v1` | Runs the backend echo application. |
| Service | `echo-v1` | Exposes the backend inside the cluster. |
| Gateway | `echo-gateway` | Defines the HTTP entry point. |
| HTTPRoute | `echo-route` | Routes traffic from the Gateway to the backend Service. |
| Generated Service | `echo-gateway-nginx` | Created by NGINX Gateway Fabric for the Gateway data plane. |

NGINX Gateway Fabric creates the `GatewayClass` during controller installation. When the `Gateway` is applied, it also creates a Gateway-specific NGINX data plane Service named `echo-gateway-nginx`.

## Files in this lab

| File | Purpose |
|---|---|
| `kustomization.yaml` | Makes the lab GitOps/Kustomize friendly. |
| `namespace.yaml` | Creates the `echo` namespace. |
| `app.yaml` | Creates the `echo-v1` Deployment. |
| `service.yaml` | Creates the `echo-v1` Service. |
| `gateway.yaml` | Creates the Gateway API `Gateway`. |
| `httproute.yaml` | Creates the Gateway API `HTTPRoute`. |

## Prerequisites

From the repository root, create the local kind cluster:

```bash
./scripts/create-cluster.sh
```

Install the Gateway API controller:

```bash
./scripts/install-controller.sh nginx-gateway-fabric
```

The controller installer should handle:

```text
Gateway API CRDs
NGINX Gateway Fabric installation
GatewayClass availability
```

For local kind testing, this lab also patches the Gateway-generated Service to use the fixed NodePort expected by `scripts/create-cluster.sh`:

```bash
./scripts/patch-gateway-nodeport.sh
```

## Apply this example

From the repository root:

```bash
./scripts/apply-example.sh 01-basic-http-route
```

Because this lab includes `kustomization.yaml`, the script applies it with:

```bash
kubectl apply -k examples/01-basic-http-route/
```

NGINX Gateway Fabric then creates a Gateway-specific data plane Service. Patch that generated Service to the fixed NodePort used by the kind cluster:

```bash
./scripts/patch-gateway-nodeport.sh
```

## Verify resources

Check the application:

```bash
kubectl -n echo get pods
kubectl -n echo get svc
```

Check Gateway API resources:

```bash
kubectl get gatewayclass
kubectl -n echo get gateway
kubectl -n echo get httproute
```

Check the Gateway-generated data plane Service:

```bash
kubectl -n echo get svc echo-gateway-nginx
```

After patching, the Service should expose port `80` through NodePort `30080`.

Describe the route if needed:

```bash
kubectl -n echo describe httproute echo-route
```

## Test the route

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080
```

Expected result: a response from the `echo-v1` backend.

## Ingress to Gateway API mapping

| Lab 00 Ingress baseline | Lab 01 Gateway API equivalent |
|---|---|
| `IngressClass` | `GatewayClass` |
| `Ingress` | `Gateway` + `HTTPRoute` |
| `spec.ingressClassName: nginx` | `spec.gatewayClassName` on `Gateway` |
| `spec.rules.host` | `HTTPRoute.spec.hostnames` |
| `spec.rules.http.paths` | `HTTPRoute.rules.matches.path` |
| `backend.service.name` | `HTTPRoute.rules.backendRefs.name` |
| `backend.service.port.number` | `HTTPRoute.rules.backendRefs.port` |

## Request flow

```text
curl localhost:8080 with Host: echo.localtest.me
  ↓
kind host-port mapping: localhost:8080 -> node:30080
  ↓
Gateway-generated Service: echo-gateway-nginx
  ↓
NGINX Gateway Fabric data plane Pod: echo-gateway-nginx-...
  ↓
Gateway listener: echo-gateway / HTTP port 80
  ↓
HTTPRoute: echo-route
  ↓
Service: echo-v1
  ↓
Pod: echo-v1
```

## Portability notes

This lab should keep application routing as standard Gateway API as much as possible.

Controller-specific setup should stay in:

```text
controllers/nginx-gateway-fabric/install.sh
scripts/patch-gateway-nodeport.sh
```

The example manifests should avoid controller-specific annotations unless a later lab is specifically testing controller-specific behaviour.

## Troubleshooting

### The route does not respond

Check whether the Gateway API controller is installed and running:

```bash
kubectl get ns
kubectl get gatewayclass
kubectl -n nginx-gateway get pods,svc,deploy 2>/dev/null || true
```

Check the Gateway-generated data plane resources:

```bash
kubectl -n echo get pods,svc
kubectl -n echo get svc echo-gateway-nginx
```

Check the application endpoints:

```bash
kubectl -n echo get endpointslice
kubectl -n echo get endpoints echo-v1
```

Check Gateway and HTTPRoute status:

```bash
kubectl -n echo describe gateway echo-gateway
kubectl -n echo describe httproute echo-route
```

### The port is already in use

If ingress-nginx is still installed and owns NodePort `30080`, the Gateway API controller may not be able to expose traffic on the same local port.

For a clean migration test, recreate the cluster:

```bash
kind delete cluster --name gateway-api-lab
./scripts/create-cluster.sh
./scripts/install-controller.sh nginx-gateway-fabric
./scripts/apply-example.sh 01-basic-http-route
./scripts/patch-gateway-nodeport.sh
```

### Localhost still does not work

The Gateway may be programmed correctly even if `localhost:8080` does not work yet.

Check which NodePort the generated Service is using:

```bash
kubectl -n echo get svc echo-gateway-nginx
```

If it is not using NodePort `30080`, run:

```bash
./scripts/patch-gateway-nodeport.sh
```

Then test again:

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080
```

## Cleanup

Delete this example:

```bash
./scripts/delete-example.sh 01-basic-http-route
```

Or delete the full local cluster:

```bash
kind delete cluster --name gateway-api-lab
```
# 01 - Basic HTTPRoute

This lab is the first Gateway API version of the `00-ingress-nginx-baseline` lab.

The goal is to migrate the same simple HTTP routing behaviour from classic Kubernetes `Ingress` to Gateway API resources.

```text
00-ingress-nginx-baseline
  IngressClass + Ingress

01-basic-http-route
  GatewayClass + Gateway + HTTPRoute
```

## Purpose

This lab answers one migration question:

```text
Can we route the same echo application using Gateway API instead of Ingress?
```

The application stays conceptually the same. The routing layer changes from Ingress to Gateway API.

```text
Client
  ↓
Gateway
  ↓
HTTPRoute
  ↓
Service: echo-v1
  ↓
Pod: echo-v1
```

## Lab position

```text
create-lab.sh
  ↓
00-ingress-nginx-baseline
  ↓
01-basic-http-route
  ↓
02-routing-rules
```

Lab 01 is the Gateway API equivalent of Lab 00. It should prove that the same hostname and backend can work through `Gateway` and `HTTPRoute` instead of `Ingress`.

## Transition from Lab 00

Lab 00 uses:

```text
ingress-nginx controller
IngressClass: nginx
Ingress: echo-ingress
Host: echo.localtest.me
Service: echo-v1
```

Lab 01 uses:

```text
NGINX Gateway Fabric controller
GatewayClass: nginx
Gateway: echo-gateway
HTTPRoute: echo-route
Host: echo.localtest.me
Service: echo-v1
```

The important point is that the backend application remains the same. Only the routing model changes.

## What this lab creates

| Resource | Name | Purpose |
|---|---|---|
| Deployment | `echo-v1` | Runs the backend echo application. |
| Service | `echo-v1` | Exposes the backend inside the cluster. |
| Gateway | `echo-gateway` | Defines the HTTP entry point. |
| HTTPRoute | `echo-route` | Routes traffic from the Gateway to the backend Service. |
| Generated Service | `echo-gateway-nginx` | Created by NGINX Gateway Fabric for the Gateway data plane. |

The shared `echo` namespace is created by `scripts/create-lab.sh`, not by this lab. This keeps namespace lifecycle separate from individual examples.

NGINX Gateway Fabric creates the `GatewayClass` during controller installation. When the `Gateway` is applied, it also creates a Gateway-specific NGINX data-plane Service named `echo-gateway-nginx`.

## Files in this lab

| File | Purpose |
|---|---|
| `kustomization.yaml` | Makes the lab GitOps/Kustomize friendly. |
| `app.yaml` | Creates the `echo-v1` Deployment. |
| `service.yaml` | Creates the `echo-v1` Service. |
| `gateway.yaml` | Creates the Gateway API `Gateway`. |
| `httproute.yaml` | Creates the Gateway API `HTTPRoute`. |

This lab should not include or manage `namespace.yaml`. The shared namespace is owned by `create-lab.sh`.

## Prerequisites

Prepare the common lab environment first:

```bash
./scripts/create-lab.sh
```

This prepares the local `kind` cluster, installs the default Gateway API controller used by the main lab path, and creates the shared `echo` namespace.

Check the shared environment:

```bash
kubectl get ns echo
kubectl get gatewayclass
```

If you just finished Lab 00, delete the Lab 00 resources first:

```bash
./scripts/delete-example.sh 00-ingress-nginx-baseline --namespace echo
```

Lab 00 uses `ingress-nginx` as the local entrypoint. Gateway API labs use the generated Gateway data-plane Service instead.

Only one Service can own NodePort `30080` at a time. If `ingress-nginx` is still holding the port, release it before applying this lab:

```bash
kubectl -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec":{"type":"ClusterIP"}}'
```

Confirm that NodePort `30080` is free:

```bash
kubectl get svc -A -o wide | grep 30080 || true
```

## Apply this lab

From the repository root:

```bash
./scripts/apply-example.sh 01-basic-http-route --namespace echo --patch-nodeport
```

Because this lab includes `kustomization.yaml`, the script applies it with:

```bash
kubectl apply -k examples/01-basic-http-route
```

The `--patch-nodeport` option patches the Gateway-generated Service to the fixed NodePort used by the local `kind` cluster.

## Verify resources

Check the application:

```bash
kubectl -n echo get pods
kubectl -n echo get svc
```

Check Gateway API resources:

```bash
kubectl get gatewayclass
kubectl -n echo get gateway
kubectl -n echo get httproute
```

Check the Gateway-generated data-plane Service:

```bash
kubectl -n echo get svc echo-gateway-nginx
```

After patching, the Service should expose port `80` through NodePort `30080`.

Describe the route:

```bash
kubectl -n echo describe httproute echo-route
```

Expected status should include:

```text
Accepted=True
ResolvedRefs=True
```

## Test the route

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080/
```

Expected result: a response from the `echo-v1` backend.

If `jq` is installed, confirm the backend pod name:

```bash
curl -s -H "Host: echo.localtest.me" http://localhost:8080/ | jq -r '.environment.HOSTNAME'
```

Expected pod name prefix:

```text
echo-v1-...
```

This confirms that the same application and hostname work through both models:

```text
Lab 00: localhost:8080 -> ingress-nginx -> Ingress -> echo-v1
Lab 01: localhost:8080 -> NGINX Gateway Fabric -> Gateway + HTTPRoute -> echo-v1
```

## Ingress to Gateway API mapping

| Lab 00 Ingress baseline | Lab 01 Gateway API equivalent |
|---|---|
| `IngressClass` | `GatewayClass` |
| `Ingress` | `Gateway` + `HTTPRoute` |
| `spec.ingressClassName: nginx` | `spec.gatewayClassName` on `Gateway` |
| `spec.rules.host` | `HTTPRoute.spec.hostnames` |
| `spec.rules.http.paths` | `HTTPRoute.rules.matches.path` |
| `backend.service.name` | `HTTPRoute.rules.backendRefs.name` |
| `backend.service.port.number` | `HTTPRoute.rules.backendRefs.port` |

## Request flow

```text
curl localhost:8080 with Host: echo.localtest.me
  ↓
kind host-port mapping: localhost:8080 -> node:30080
  ↓
Gateway-generated Service: echo-gateway-nginx
  ↓
NGINX Gateway Fabric data-plane Pod: echo-gateway-nginx-...
  ↓
Gateway listener: echo-gateway / HTTP port 80
  ↓
HTTPRoute: echo-route
  ↓
Service: echo-v1
  ↓
Pod: echo-v1
```

## Portability notes

This lab keeps application routing as standard Gateway API as much as possible.

Controller-specific setup should stay in:

```text
controllers/nginx-gateway-fabric/install.sh
scripts/patch-gateway-nodeport.sh
```

The example manifests should avoid controller-specific annotations unless a later lab is specifically testing controller-specific behaviour.

## Troubleshooting

### The route does not respond

Check whether the Gateway API controller is installed and running:

```bash
kubectl get gatewayclass
kubectl -n nginx-gateway get pods,svc,deploy 2>/dev/null || true
```

Check the Gateway-generated data-plane resources:

```bash
kubectl -n echo get pods,svc
kubectl -n echo get svc echo-gateway-nginx
```

Check the application endpoints:

```bash
kubectl -n echo get endpointslice
kubectl -n echo get endpoints echo-v1
```

Check Gateway and HTTPRoute status:

```bash
kubectl -n echo describe gateway echo-gateway
kubectl -n echo describe httproute echo-route
```

### The namespace is missing

The shared `echo` namespace should be created by `create-lab.sh`.

Recreate the shared lab environment without recreating the whole cluster:

```bash
./scripts/create-lab.sh --skip-cluster --skip-controller
```

Then retry:

```bash
./scripts/apply-example.sh 01-basic-http-route --namespace echo --patch-nodeport
```

### NodePort 30080 is already allocated

If `ingress-nginx` is still installed and owns NodePort `30080`, the Gateway API controller cannot expose traffic on the same local port.

Check who owns NodePort `30080`:

```bash
kubectl get svc -A -o wide | grep 30080 || true
```

If it is `ingress-nginx/ingress-nginx-controller`, release it:

```bash
kubectl -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec":{"type":"ClusterIP"}}'
```

Then retry:

```bash
./scripts/apply-example.sh 01-basic-http-route --namespace echo --patch-nodeport
```

### Localhost still does not work

The Gateway may be programmed correctly even if `localhost:8080` does not work yet.

Check which NodePort the generated Service is using:

```bash
kubectl -n echo get svc echo-gateway-nginx
```

If it is not using NodePort `30080`, run:

```bash
./scripts/patch-gateway-nodeport.sh
```

Then test again:

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080/
```

## Cleanup

Delete this lab's resources:

```bash
./scripts/delete-example.sh 01-basic-http-route --namespace echo
```

This deletes the example application, Gateway, and HTTPRoute resources. It should not delete the shared `echo` namespace.

To confirm the namespace still exists:

```bash
kubectl get ns echo
```

To destroy everything, delete the whole local cluster:

```bash
./scripts/delete-cluster.sh
```

## Notes

This lab intentionally keeps the Gateway API configuration simple. It does not test advanced matching, traffic splitting, TLS, policy attachment, security integrations, or observability yet.

Those behaviours are introduced in later labs.