# 00 - ingress-nginx baseline

This lab creates the starting point for the Gateway API migration journey.

It uses the familiar Kubernetes `Ingress` resource with the `ingress-nginx` controller. Later labs convert the same user-facing route into Gateway API resources such as `Gateway` and `HTTPRoute`.

## Purpose

This baseline answers one simple question:

```text
How does the application work today with classic Ingress and ingress-nginx?
```

After this baseline works, the next lab migrates the same hostname and backend service to Gateway API so the behaviour can be compared directly.

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

Lab 00 is the classic Ingress baseline. Lab 01 is the Gateway API equivalent.

## What this lab creates

| Resource | Name | Purpose |
|---|---|---|
| Deployment | `echo-v1` | Runs the backend echo application. |
| Service | `echo-v1` | Exposes the backend inside the cluster. |
| Ingress | `echo-ingress` | Routes external HTTP traffic to the backend service. |

The shared `echo` namespace is created by `scripts/create-lab.sh`, not by this lab. This keeps namespace lifecycle separate from individual examples.

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

This lab uses:

```text
echo.localtest.me
```

`localtest.me` resolves to `127.0.0.1`, which makes it useful for local Kubernetes labs.

You can test either with the hostname directly:

```bash
curl http://echo.localtest.me:8080/
```

or by setting the `Host` header manually:

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080/
```

## Prerequisites

Prepare the common lab environment first:

```bash
./scripts/create-lab.sh
```

Lab 00 specifically requires the `ingress-nginx` baseline controller:

```bash
./scripts/install-controller.sh ingress-nginx
```

Why this extra step is needed:

```text
create-lab.sh prepares the common Gateway API lab environment.
Lab 00 intentionally uses ingress-nginx as the migration baseline.
```

## Apply this lab

From the repository root:

```bash
./scripts/apply-example.sh 00-ingress-nginx-baseline --namespace echo
```

If `ingress-nginx` is missing, `apply-example.sh` will stop and ask you to install it first:

```bash
./scripts/install-controller.sh ingress-nginx
```

## Verify resources

Check the application resources:

```bash
kubectl -n echo get pods
kubectl -n echo get svc
kubectl -n echo get ingress
```

Check the Ingress details:

```bash
kubectl -n echo describe ingress echo-ingress
```

Check the ingress-nginx controller Service:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

For the local `kind` lab, ingress-nginx should expose traffic through the local NodePort path used by `localhost:8080`.

## Test the route

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080/
```

Expected result: a response from the `echo-v1` backend.

If `jq` is installed, you can confirm the backend pod name:

```bash
curl -s -H "Host: echo.localtest.me" http://localhost:8080/ | jq -r '.environment.HOSTNAME'
```

Expected pod name prefix:

```text
echo-v1-...
```

You can also test with:

```bash
curl http://echo.localtest.me:8080/
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

## Important local NodePort note

Lab 00 uses `ingress-nginx` as the local entrypoint for `localhost:8080`.

Gateway API labs, such as Lab 01 and Lab 02, use the generated NGINX Gateway Fabric data-plane Service as the local entrypoint instead.

Only one Service can own NodePort `30080` at a time. After deleting Lab 00 and before moving to Gateway API labs, release the local NodePort from `ingress-nginx`:

```bash
kubectl -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec":{"type":"ClusterIP"}}'
```

Confirm that NodePort `30080` is free:

```bash
kubectl get svc -A -o wide | grep 30080 || true
```

Then apply Lab 01:

```bash
./scripts/apply-example.sh 01-basic-http-route --namespace echo --patch-nodeport
```

## Cleanup

Delete this lab's resources:

```bash
./scripts/delete-example.sh 00-ingress-nginx-baseline --namespace echo
```

This deletes the example application and Ingress resources, but it does not uninstall `ingress-nginx` because the controller is a platform-level component installed by `install-controller.sh`.

If you are moving to Gateway API labs, also release the local NodePort from `ingress-nginx`:

```bash
kubectl -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec":{"type":"ClusterIP"}}'
```

Do not delete the shared `echo` namespace as part of normal per-lab cleanup. The namespace is managed by `scripts/create-lab.sh` and may be reused by later labs.

To destroy everything, delete the whole local cluster instead:

```bash
./scripts/delete-cluster.sh
```

## Notes

This lab intentionally keeps the Ingress simple. It does not use rewrite annotations, TLS, authentication, rate limiting, or other controller-specific features yet.

Those behaviours will be added later as separate labs so the migration and portability impact can be compared clearly.