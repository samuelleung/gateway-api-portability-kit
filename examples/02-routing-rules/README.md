# 02 - Routing Rules

This lab demonstrates common hostname and path-based routing with Gateway API.

It builds on:

- `00-ingress-nginx-baseline`
- `01-basic-http-route`

The goal is to show how a familiar Ingress routing pattern maps to Gateway API, while also explaining why Gateway API is more suitable for enterprise platform, DevOps, and security operating models.

## Scenario

A single hostname routes traffic to different backend services by path:

| Request | Backend service | Purpose |
|---|---|---|
| `http://echo.localtest.me/` | `echo-v1` | Default application route |
| `http://echo.localtest.me/v2` | `echo-v2` | Versioned application route |
| `http://echo.localtest.me/admin` | `echo-admin` | Admin route example |

This is intentionally simple and portable. More advanced matching, such as headers, methods, query parameters, rewrites, and traffic splitting, is covered in later chapters.

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

Lab 02 extends Lab 01 from one route to multiple path rules behind the same hostname.

## What this lab demonstrates

- HTTPRoute hostname matching
- Path prefix matching
- Multiple backend services behind one hostname
- Separation between platform-owned Gateway and application-owned routing intent
- How Gateway API improves enterprise governance compared with classic Ingress

## What this lab creates

| Resource | Name | Purpose |
|---|---|---|
| Deployment | `echo-v1` | Runs the default backend application. |
| Deployment | `echo-v2` | Runs the versioned backend application. |
| Deployment | `echo-admin` | Runs the admin backend application. |
| Service | `echo-v1` | Exposes the default backend inside the cluster. |
| Service | `echo-v2` | Exposes the versioned backend inside the cluster. |
| Service | `echo-admin` | Exposes the admin backend inside the cluster. |
| Gateway | `echo-gateway` | Defines the HTTP entry point. |
| HTTPRoute | `echo-routing-rules` | Routes `/`, `/v2`, and `/admin` to different backend Services. |
| Generated Service | `echo-gateway-nginx` | Created by NGINX Gateway Fabric for the Gateway data plane. |

The shared `echo` namespace is created by `scripts/create-lab.sh`, not by this lab. This keeps namespace lifecycle separate from individual examples.

## Files in this lab

| File | Purpose |
|---|---|
| `kustomization.yaml` | Makes the lab GitOps/Kustomize friendly. |
| `app.yaml` | Creates the `echo-v1`, `echo-v2`, and `echo-admin` Deployments and Services. |
| `gateway.yaml` | Creates the Gateway API `Gateway`. |
| `httproute.yaml` | Creates the Gateway API `HTTPRoute` with multiple path rules. |

This lab should not include or manage `namespace.yaml`. The shared namespace is owned by `create-lab.sh`.

## Ingress vs Gateway API

Classic Ingress usually combines the public entry point and application routing rules in one resource:

```text
Ingress
  ├─ hostname
  ├─ path rules
  ├─ backend services
  ├─ TLS settings
  └─ controller-specific annotations
```

Gateway API separates these concerns:

```text
GatewayClass
  └─ selected Gateway API controller

Gateway
  ├─ listener
  ├─ hostname / port / protocol
  └─ platform-owned traffic entry point

HTTPRoute
  ├─ hostname
  ├─ path matches
  ├─ backendRefs
  └─ application routing intent
```

For simple host/path routing, Ingress and Gateway API can produce the same traffic result. The enterprise benefit comes from the separation of responsibility.

## Enterprise operating model

In real enterprises, application teams may not directly operate Kubernetes or manually write Gateway API YAML.

A more realistic model is:

```text
Application team
  declares routing intent

DevOps / platform automation
  validates the request
  generates HTTPRoute
  applies it through GitOps or CI/CD
  checks route status

Platform team
  owns GatewayClass, Gateway, listeners, TLS, controller, and shared infrastructure

Security team
  owns guardrails, allowed namespaces, hostname policy, auth, WAF, rate limits, and audit requirements
```

So the application team may only submit a simple request like:

```yaml
route:
  host: echo.localtest.me
  path: /v2
  service: echo-v2
  port: 80
```

The platform system then generates the actual `HTTPRoute`.

Gateway API is therefore not always the developer-facing interface. In enterprises, it is often the platform-facing control model behind GitOps pipelines, Helm charts, Terraform modules, Backstage portals, or internal developer platforms.

## DevOps benefits

Gateway API helps DevOps teams because it creates a clearer and more automatable resource model.

| Area | Benefit |
|---|---|
| GitOps | Gateway and HTTPRoute can live in separate repositories or folders. |
| Environment promotion | The same route pattern can attach to dev, staging, or production Gateways. |
| CI/CD validation | Pipelines can check `Accepted`, `ResolvedRefs`, and `Programmed` status. |
| Reusable templates | Platform teams can provide standard route templates for common patterns. |
| Troubleshooting | Status conditions make route attachment and backend reference issues easier to identify. |

Example validation idea:

```bash
kubectl wait httproute echo-routing-rules \
  -n echo \
  --for=condition=Accepted=True \
  --timeout=60s
```

## Security benefits

Gateway API also gives security teams a better control point.

| Area | Benefit |
|---|---|
| Public exposure | App teams do not need permission to create public load balancers directly. |
| Namespace control | Gateways can restrict which namespaces may attach routes. |
| Hostname governance | Platform teams can control approved listener hostnames. |
| Cross-namespace access | Cross-namespace references can require explicit permission. |
| Policy attachment | Auth, WAF, rate limit, TLS, telemetry, and future AI/MCP guardrails can be layered consistently. |
| Audit | Teams can query Gateways, HTTPRoutes, ReferenceGrants, and route status across the cluster. |

The key security idea is:

```text
Application teams own routing intent.
Platform and security teams own exposure, attachment, and guardrails.
```

## Cloud Kubernetes note

On managed cloud Kubernetes, the separation is even more important because a `Gateway` may provision real cloud infrastructure such as:

- cloud load balancers
- public or private IPs
- DNS records
- certificates
- WAF or security policies
- cloud logging and monitoring resources

That means every application team should not create its own Gateway by default.

A better cloud operating model is:

```text
Use a small number of shared Gateways.
Allow application routes to attach through controlled HTTPRoutes.
Use automation and policy to validate route intent before deployment.
```

This controls cost and reduces operational sprawl.

## Cost and operational model

Gateway API does not automatically reduce cost. If every application creates its own Gateway, cloud load balancer, policy stack, and controller-specific configuration, cost and operational effort may increase.

Recommended enterprise principle:

```text
Compare many controllers in the lab.
Adopt a small number in production.
Use shared Gateways where possible.
Create separate Gateways only for clear isolation, compliance, lifecycle, or security reasons.
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

If you just finished Lab 01, delete the Lab 01 resources first:

```bash
./scripts/delete-example.sh 01-basic-http-route --namespace echo
```

Lab 01 and Lab 02 use the same hostname and Gateway name. Keeping both active can cause traffic to continue matching the older basic route.

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
./scripts/apply-example.sh 02-routing-rules --namespace echo --patch-nodeport
```

Because this lab includes `kustomization.yaml`, the script applies it with:

```bash
kubectl apply -k examples/02-routing-rules
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

After patching, the Service should expose port `80` through NodePort `30080`.

Describe the route:

```bash
kubectl -n echo describe httproute echo-routing-rules
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

## Test

```bash
curl -s -H "Host: echo.localtest.me" http://localhost:8080/ | jq -r '.environment.HOSTNAME'
curl -s -H "Host: echo.localtest.me" http://localhost:8080/v2 | jq -r '.environment.HOSTNAME'
curl -s -H "Host: echo.localtest.me" http://localhost:8080/admin | jq -r '.environment.HOSTNAME'
```

If `jq` is not installed, use:

```bash
curl -s -H "Host: echo.localtest.me" http://localhost:8080/ | grep -o '"HOSTNAME":"[^"]*"'
curl -s -H "Host: echo.localtest.me" http://localhost:8080/v2 | grep -o '"HOSTNAME":"[^"]*"'
curl -s -H "Host: echo.localtest.me" http://localhost:8080/admin | grep -o '"HOSTNAME":"[^"]*"'
```

Expected behaviour:

| Command | Expected backend pod name prefix |
|---|---|
| `/` | `echo-v1-...` |
| `/v2` | `echo-v2-...` |
| `/admin` | `echo-admin-...` |

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
HTTPRoute: echo-routing-rules
  ├─ /admin -> Service: echo-admin
  ├─ /v2    -> Service: echo-v2
  └─ /      -> Service: echo-v1
```

Path rule order matters in this lab. More specific prefixes such as `/admin` and `/v2` should be listed before the catch-all `/` route.

## Troubleshooting

### The namespace is missing

The shared `echo` namespace should be created by `create-lab.sh`.

Recreate the shared lab environment without recreating the whole cluster:

```bash
./scripts/create-lab.sh --skip-cluster --skip-controller
```

Then retry:

```bash
./scripts/apply-example.sh 02-routing-rules --namespace echo --patch-nodeport
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
./scripts/apply-example.sh 02-routing-rules --namespace echo --patch-nodeport
```

### Traffic still goes to echo-v1 for every path

Lab 01 may still be active and matching the same hostname.

Delete Lab 01 first:

```bash
./scripts/delete-example.sh 01-basic-http-route --namespace echo
```

Then reapply Lab 02:

```bash
./scripts/apply-example.sh 02-routing-rules --namespace echo --patch-nodeport
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

Then test again.

## Cleanup

Delete this lab's resources:

```bash
./scripts/delete-example.sh 02-routing-rules --namespace echo
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

This chapter should stay focused on portable hostname and path routing.

The following topics are covered later:

| Topic | Chapter |
|---|---|
| Traffic splitting | `03-traffic-splitting` |
| Header routing | `04-advanced-http-routing` |
| Method or query matching | `04-advanced-http-routing` |
| URL rewrite | `04-advanced-http-routing` |
| Request or response header modification | `04-advanced-http-routing` |
| Cross-namespace route attachment | `05-shared-gateway-governance` |
| TLS termination | `07-tls-termination` |
| Backend TLS, GRPCRoute, TCPRoute, UDPRoute | `08-backend-tls-and-protocols` |
| AI Gateway and MCP Gateway | `12-ai-gateway-basics` |

## Key takeaway

Ingress can perform basic host and path routing, but it mixes public entry point configuration with application routing rules.

Gateway API separates the platform-owned Gateway from application routing intent represented by HTTPRoute. In enterprises, this enables stronger GitOps workflows, clearer RBAC, better security governance, safer cloud infrastructure usage, and a cleaner path toward AI Gateway and MCP Gateway patterns.
