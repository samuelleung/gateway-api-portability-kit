

# 00 - ingress-nginx baseline

This example creates the starting point for the Gateway API migration lab.

It uses the familiar Kubernetes `Ingress` resource with the `ingress-nginx` controller. Later examples will convert the same routing behaviour into Gateway API resources such as `Gateway` and `HTTPRoute`.

## Purpose

This baseline answers one simple question:

```text
How does the application work today with classic Ingress and ingress-nginx?
```

After this baseline works, the next step is to migrate the same route to Gateway API and compare the behaviour.

## What this example creates

| Resource | Name | Purpose |
|---|---|---|
| Namespace | `echo` | Isolates the demo application. |
| Deployment | `echo-v1` | Runs the backend echo application. |
| Service | `echo-v1` | Exposes the backend inside the cluster. |
| Ingress | `echo-ingress` | Routes external HTTP traffic to the backend service. |

## Request flow

```text
curl localhost:8080
  ↓
ingress-nginx controller
  ↓
Ingress: echo-ingress
  ↓
Service: echo-v1
  ↓
Pod: echo-v1
```

## Hostname

This example uses:

```text
echo.localtest.me
```

`localtest.me` resolves to `127.0.0.1`, which makes it useful for local Kubernetes labs.

You can test either with the hostname directly:

```bash
curl http://echo.localtest.me:8080
```

or by setting the `Host` header manually:

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080
```

## Prerequisites

Create the kind cluster:

```bash
./scripts/create-cluster.sh
```

Install the ingress-nginx baseline controller:

```bash
./scripts/install-controller.sh ingress-nginx
```

## Apply this example

From the repository root:

```bash
kubectl apply -f examples/00-ingress-nginx-baseline/
```

## Verify resources

Check the application:

```bash
kubectl -n echo get pods
kubectl -n echo get svc
kubectl -n echo get ingress
```

Check the Ingress details:

```bash
kubectl -n echo describe ingress echo-ingress
```

## Test the route

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080
```

Expected result: a response from the `echo-v1` backend.

You can also test with:

```bash
curl http://echo.localtest.me:8080
```

## Ingress to Gateway API migration mapping

This baseline will later be migrated as follows:

| ingress-nginx baseline | Gateway API equivalent |
|---|---|
| `IngressClass` | `GatewayClass` |
| `Ingress` | `Gateway` + `HTTPRoute` |
| `spec.rules.host` | `HTTPRoute.spec.hostnames` |
| `spec.rules.http.paths` | `HTTPRoute.rules.matches.path` |
| `backend.service.name` | `HTTPRoute.rules.backendRefs.name` |
| `backend.service.port.number` | `HTTPRoute.rules.backendRefs.port` |

## Notes

This example intentionally keeps the Ingress simple. It does not use rewrite annotations, TLS, authentication, rate limiting, or other controller-specific features yet.

Those behaviours will be added later as separate labs so the migration and portability impact can be compared clearly.

## Cleanup

Delete this example:

```bash
kubectl delete -f examples/00-ingress-nginx-baseline/
```

Or delete the whole namespace:

```bash
kubectl delete namespace echo
```