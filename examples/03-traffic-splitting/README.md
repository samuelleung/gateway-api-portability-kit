# 03 - Traffic Splitting

This lab demonstrates weighted traffic splitting with Gateway API.

It builds on:

- `00-ingress-nginx-baseline`
- `01-basic-http-route`
- `02-routing-rules`

Lab 02 showed how one hostname can route to different backend services by path. Lab 03 shows how one hostname and one path can split traffic across multiple backend versions.

## Scenario

A single hostname and path routes traffic to two backend versions:

| Request | Backend service | Weight | Purpose |
|---|---|---:|---|
| `http://echo.localtest.me/` | `echo-v1` | 80 | Stable version |
| `http://echo.localtest.me/` | `echo-v2` | 20 | Canary version |

```text
80% traffic -> echo-v1
20% traffic -> echo-v2
```

This represents a simple canary rollout pattern.

## Lab position

```text
create-lab.sh
  ↓
00-ingress-nginx-baseline
  ↓
01-basic-http-route
  ↓
02-routing-rules
  ↓
03-traffic-splitting
```

Lab 03 introduces weighted `backendRefs` in `HTTPRoute`.

## What this lab demonstrates

- Weighted traffic splitting
- Canary release pattern
- Multiple `backendRefs` in one `HTTPRoute` rule
- Same hostname and path routed to multiple backend services
- Progressive delivery behaviour without controller-specific Ingress annotations

## What this lab creates

| Resource | Name | Purpose |
|---|---|---|
| Deployment | `echo-v1` | Stable backend version. |
| Deployment | `echo-v2` | Canary backend version. |
| Service | `echo-v1` | Exposes the stable backend inside the cluster. |
| Service | `echo-v2` | Exposes the canary backend inside the cluster. |
| Gateway | `echo-gateway` | Defines the HTTP entry point. |
| HTTPRoute | `echo-traffic-split` | Splits traffic between `echo-v1` and `echo-v2`. |
| Generated Service | `echo-gateway-nginx` | Created by NGINX Gateway Fabric for the Gateway data plane. |

The shared `echo` namespace is created by `scripts/create-lab.sh`, not by this lab. This keeps namespace lifecycle separate from individual examples.

## Files in this lab

| File | Purpose |
|---|---|
| `kustomization.yaml` | Makes the lab GitOps/Kustomize friendly. |
| `app.yaml` | Creates the `echo-v1` and `echo-v2` Deployments and Services. |
| `gateway.yaml` | Creates the Gateway API `Gateway`. |
| `httproute.yaml` | Creates the weighted traffic splitting `HTTPRoute`. |

This lab should not include or manage `namespace.yaml`. The shared namespace is owned by `create-lab.sh`.

## Gateway API traffic splitting model

In Gateway API, traffic splitting is expressed using multiple `backendRefs` with weights:

```yaml
backendRefs:
  - name: echo-v1
    port: 80
    weight: 80
  - name: echo-v2
    port: 80
    weight: 20
```

This means traffic should be distributed approximately as:

```text
echo-v1: 80%
echo-v2: 20%
```

The split is statistical. A small number of test requests may not show exactly 80/20, but a larger sample should trend toward the configured weights.

## Traffic splitting patterns

There are several practical traffic splitting patterns in platform engineering.

| Pattern | Example | Gateway API fit | Lab scope |
|---|---|---|---|
| Weighted canary | `80% -> v1`, `20% -> v2` | Native `backendRefs.weight` | Covered in this lab |
| Blue-green switch | `100% -> blue`, then `100% -> green` | Can be modelled with `100/0` then `0/100` weights | Mentioned in this lab |
| A/B testing | `50% -> A`, `50% -> B` | Basic split uses weights; true experiments often need stickiness or user identity | Mentioned in this lab |
| Header or cookie-based split | Beta users with `X-User-Type: beta` go to v2 | Uses HTTPRoute match rules, not just weights | Covered later in `04-advanced-http-routing` |
| Progressive delivery | `95/5 -> 90/10 -> 80/20 -> 50/50 -> 0/100` | Weights can be changed over time by GitOps or release automation | Covered conceptually in this lab |

This lab focuses on the most portable and foundational pattern: weighted `backendRefs`.

Header, cookie, method, query, and other request-matching based splits are intentionally left for `04-advanced-http-routing`.

## Enterprise use case

Weighted traffic splitting is commonly used for:

| Use case | Description |
|---|---|
| Canary release | Send a small percentage of users to a new version. |
| Gradual rollout | Move from 90/10 to 50/50 to 0/100 over time. |
| Fast rollback | Change weights back to 100/0 if the new version is unhealthy. |
| Basic A/B comparison | Compare two versions of a service without advanced stickiness. |
| Progressive delivery | Combine routing weights with metrics, alerts, and automation. |

A realistic progressive delivery flow may look like:

```text
Deploy v2
  ↓
Send 5% traffic to v2
  ↓
Check error rate, latency, business metrics
  ↓
Increase to 20%
  ↓
Increase to 50%
  ↓
Promote v2 to 100%
```

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

If you just finished Lab 02, delete the Lab 02 resources first:

```bash
./scripts/delete-example.sh 02-routing-rules --namespace echo
```

Lab 02 and Lab 03 use the same hostname and Gateway name. Keeping both active can cause traffic to continue matching the older route.

If you previously ran Lab 00 and `ingress-nginx` still owns NodePort `30080`, release it before applying this lab:

```bash
kubectl -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec":{"type":"ClusterIP"}}'
```

Confirm that NodePort `30080` is free or already owned by the Gateway data-plane Service:

```bash
kubectl get svc -A -o wide | grep 30080 || true
```

## Apply this lab

From the repository root:

```bash
./scripts/apply-example.sh 03-traffic-splitting --namespace echo --patch-nodeport
```

Because this lab includes `kustomization.yaml`, the script applies it with:

```bash
kubectl apply -k examples/03-traffic-splitting
```

The `--patch-nodeport` option patches the Gateway-generated Service to the fixed NodePort used by the local `kind` cluster.

## Verify resources

Check the application resources:

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

Describe the route:

```bash
kubectl -n echo describe httproute echo-traffic-split
```

Expected status should include:

```text
Gateway:
  Programmed=True

HTTPRoute:
  Accepted=True
  ResolvedRefs=True
```

Exact condition output may vary by controller.

## Test the traffic split

Run one request:

```bash
curl -s -H "Host: echo.localtest.me" http://localhost:8080/ | jq -r '.environment.HOSTNAME'
```

You should see either:

```text
echo-v1-...
```

or:

```text
echo-v2-...
```

To test the approximate split, run multiple requests:

```bash
for i in $(seq 1 50); do
  curl -s -H "Host: echo.localtest.me" http://localhost:8080/ \
    | jq -r '.environment.HOSTNAME' \
    | sed 's/-[a-z0-9].*//'
done | sort | uniq -c
```

Expected result should trend toward:

```text
echo-v1: higher count
echo-v2: lower count
```

For example, with 50 requests, a rough result may look like:

```text
40 echo-v1
10 echo-v2
```

The exact number does not need to be perfect.

## Change the split

To simulate a stronger canary rollout, edit `httproute.yaml`:

```yaml
backendRefs:
  - name: echo-v1
    port: 80
    weight: 50
  - name: echo-v2
    port: 80
    weight: 50
```

Then reapply:

```bash
./scripts/apply-example.sh 03-traffic-splitting --namespace echo --patch-nodeport
```

To promote v2 fully:

```yaml
backendRefs:
  - name: echo-v1
    port: 80
    weight: 0
  - name: echo-v2
    port: 80
    weight: 100
```

To roll back fully:

```yaml
backendRefs:
  - name: echo-v1
    port: 80
    weight: 100
  - name: echo-v2
    port: 80
    weight: 0
```

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
HTTPRoute: echo-traffic-split
  ├─ weight 80 -> Service: echo-v1
  └─ weight 20 -> Service: echo-v2
```

## Troubleshooting

### The namespace is missing

The shared `echo` namespace should be created by `create-lab.sh`.

Recreate the shared lab environment without recreating the whole cluster:

```bash
./scripts/create-lab.sh --skip-cluster --skip-controller
```

Then retry:

```bash
./scripts/apply-example.sh 03-traffic-splitting --namespace echo --patch-nodeport
```

### NodePort 30080 is already allocated

Only one Service can own NodePort `30080` at a time.

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
./scripts/apply-example.sh 03-traffic-splitting --namespace echo --patch-nodeport
```

### Traffic always goes to one version

A small number of requests may not show the configured distribution clearly.

Try a larger sample:

```bash
for i in $(seq 1 100); do
  curl -s -H "Host: echo.localtest.me" http://localhost:8080/ \
    | jq -r '.environment.HOSTNAME' \
    | sed 's/-[a-z0-9].*//'
done | sort | uniq -c
```

Also confirm the route weights:

```bash
kubectl -n echo get httproute echo-traffic-split -o yaml
```

### Traffic still follows Lab 02 path rules

Lab 02 may still be active and matching the same hostname.

Delete Lab 02 first:

```bash
./scripts/delete-example.sh 02-routing-rules --namespace echo
```

Then reapply Lab 03:

```bash
./scripts/apply-example.sh 03-traffic-splitting --namespace echo --patch-nodeport
```

## Cleanup

Delete this lab's resources:

```bash
./scripts/delete-example.sh 03-traffic-splitting --namespace echo
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

## What is intentionally not covered here

This chapter should stay focused on portable weighted traffic splitting.

The following topics are covered later:

| Topic | Chapter |
|---|---|
| Header routing | `04-advanced-http-routing` |
| Method or query matching | `04-advanced-http-routing` |
| URL rewrite | `04-advanced-http-routing` |
| Request or response header modification | `04-advanced-http-routing` |
| Cross-namespace route attachment | `05-shared-gateway-governance` |
| TLS termination | `07-tls-termination` |
| Backend TLS, GRPCRoute, TCPRoute, UDPRoute | `08-backend-tls-and-protocols` |
| AI Gateway and MCP Gateway | `12-ai-gateway-basics` |

## Key takeaway

Gateway API can express canary and progressive delivery routing using standard weighted `backendRefs`.

This makes traffic splitting more portable and easier to automate than relying on controller-specific Ingress annotations.