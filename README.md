# Gateway API Portability Kit

A hands-on Kubernetes lab for migrating from **ingress-nginx** to **Gateway API**, then extending the journey into **AI Gateway**, **MCP Gateway**, external backend, policy, telemetry, and controller portability patterns.

## Overview

Many Kubernetes users start with `ingress-nginx` because it is familiar, widely adopted, and easy to run locally. Gateway API is the newer Kubernetes-native traffic-management API, but unlike the way many users treat `ingress-nginx` in the Ingress world, Gateway API has **no single default controller**.

This project also treats **AI Gateway** as a first-class direction. Gateway API is increasingly relevant to model traffic, inference routing, MCP server access, external AI services, egress control, policy attachment, telemetry, and security. The project therefore starts with classic Ingress migration, then grows toward AI Gateway, MCP Gateway, platform-governance, and controller-portability patterns.

This project uses a practical migration story:

```text
ingress-nginx baseline
  ↓
Gateway API equivalent
  ↓
AI Gateway, MCP Gateway, and controller portability comparison
```

The goal is to help platform engineers, DevOps engineers, SREs, and Kubernetes users understand:

- how common Ingress patterns map to Gateway API,
- which parts of Gateway API are portable across controllers,
- which behaviours still depend on the selected controller,
- how different controllers report status and failure conditions,
- and what to consider before adopting Gateway API in production.

## Why this project exists

Classic Kubernetes Ingress is simple and widely used, but real-world usage often depends heavily on controller-specific annotations. This makes migration, standardisation, and multi-controller portability difficult.

Gateway API provides a more expressive and role-oriented model for Kubernetes traffic management. It separates infrastructure ownership from application routing more clearly than classic Ingress.

This kit starts from a familiar `ingress-nginx` baseline and gradually converts each scenario into Gateway API resources such as `GatewayClass`, `Gateway`, and `HTTPRoute`. The same Gateway API examples can then be tested against different implementations.

```text
Start from what users know.
Migrate to Gateway API.
Compare what actually stays portable.
```

## Project goals

- Provide a clear migration path from `ingress-nginx` to Gateway API.
- Show side-by-side examples of Ingress and Gateway API resources.
- Compare multiple Gateway API controllers using the same scenarios.
- Add an AI Gateway track covering model traffic, inference routing, MCP Gateway patterns, external AI backends, egress risk, and policy/security controls.
- Separate standard Gateway API resources from controller-specific configuration.
- Document portability notes, limitations, status conditions, and implementation differences.
- Keep the examples simple enough to run locally with `kind` first, with `k3d` support as a future option.

## Target audience

This project is for:

- platform engineers evaluating Gateway API,
- DevOps engineers migrating from Ingress,
- SREs comparing Gateway API controller behaviour,
- Kubernetes administrators standardising traffic management,
- solutions architects explaining Ingress-to-Gateway migration,
- and developers who want a practical local lab.

## Controller strategy

This project does not assume there is one default Gateway API controller.

Instead, it uses `ingress-nginx` as the familiar baseline, then compares Gateway API implementations.

The main learning path uses **NGINX Gateway Fabric** as the reference Gateway API controller for Chapters 01-11. This keeps the migration journey focused for users coming from `ingress-nginx`. Other Gateway API controllers are introduced later in the portability chapter.

| Stage | Controller / implementation | Purpose |
|---|---|---|
| Baseline | ingress-nginx | Show the familiar Ingress pattern many users already know. |
| First Gateway API target | NGINX Gateway Fabric | Natural migration path for users coming from NGINX / ingress-nginx. |
| Platform networking target | Cilium Gateway API | Modern Kubernetes networking, security, observability, and eBPF story. |
| Developer-friendly target | Traefik Gateway API | Lightweight local lab and simple developer experience. |
| Envoy-based target | Envoy Gateway | Envoy data-plane architecture and Gateway API implementation comparison. |

## Learning path

The project is organised as a guided adoption journey rather than a long feature checklist.

```text
Part A - Core migration path
  00 -> 01 -> 02 -> 03

Part B - Platform engineering path
  04 -> 05 -> 06 -> 07

Part C - Production ecosystem path
  08 -> 09 -> 10 -> 11

Part D - AI Gateway and emerging Gateway API path
  12 -> 13 -> 14

Part E - Controller portability path
  15
```

This keeps the first path approachable while still leaving room for deeper platform, security, observability, and architecture topics.

AI Gateway is treated as a required roadmap area, not an optional appendix. The project should still start with stable, runnable Gateway API fundamentals first, but the advanced path must connect those fundamentals to model-serving, inference routing, external AI APIs, policy, telemetry, and egress-security scenarios.

### Part A - Core migration path

These examples are the main runnable path for users migrating from `ingress-nginx` to Gateway API.

| Chapter | Example | Topic | Purpose |
|---|---|---|---|
| 00 | `00-ingress-nginx-baseline` | Classic Ingress with ingress-nginx | Establish the known Ingress behaviour before migration. |
| 01 | `01-basic-http-route` | Basic Gateway + HTTPRoute | Build the first Gateway API equivalent. |
| 02 | `02-routing-rules` | Hostname and path routing | Consolidate common Ingress host/path migration patterns. |
| 03 | `03-traffic-splitting` | Weighted backend routing | Show the first clear Gateway API value-add for canary-style routing. |

### Part B - Platform engineering path

These examples show why Gateway API matters beyond simple routing syntax.

| Chapter | Example | Topic | Purpose |
|---|---|---|---|
| 04 | `04-advanced-http-routing` | Header, method, query, and modifier-based routing | Show richer L7 routing without relying only on controller-specific Ingress annotations. |
| 05 | `05-shared-gateway-governance` | Shared Gateway, RBAC alignment, route attachment, and ReferenceGrant | Demonstrate platform-owned Gateways and application-owned Routes. |
| 06 | `06-failure-behaviour` | Invalid backends, rejected routes, and status conditions | Show operational safety and troubleshooting visibility. |
| 07 | `07-tls-termination` | HTTPS listener and TLS Secret reference | Compare Ingress TLS with Gateway listener TLS and certificate ownership. |

### Part C - Production ecosystem path

These chapters separate Gateway API itself from the ecosystem tools usually needed in production.

| Chapter | Example / topic | Topic | Purpose |
|---|---|---|---|
| 08 | `08-backend-tls-and-protocols` | BackendTLSPolicy, TLSRoute, GRPCRoute, TCPRoute, and UDPRoute | Show advanced transport and protocol capabilities. |
| 09 | `09-observability-integrations` | Status, metrics, logs, Prometheus, Grafana, and OpenTelemetry | Explain what Gateway API exposes natively and what controllers/tools add. |
| 10 | `10-security-integrations` | WAF, authentication, rate limiting, and policy engines | Clarify what Gateway API does not provide alone and where third-party tools fit. |
| 11 | `11-multi-cluster-patterns` | DNS, global load balancers, mesh, GitOps, and multi-cluster patterns | Show Gateway API as a building block, not a full global traffic system by itself. |

### Part D - AI Gateway and emerging Gateway API path

These chapters track areas that are very close to the current Gateway API direction, especially AI Gateway, Backend/XBackend, inference routing, egress, policy, telemetry, and conformance.

| Chapter | Example / topic | Topic | Purpose |
|---|---|---|---|
| 12 | `12-ai-gateway-basics` | AI Gateway, MCP Gateway, model traffic, and inference routing | Show how Gateway API concepts can front AI services, MCP servers, agent-to-tool traffic, and model-serving traffic. |
| 13 | `13-egress-and-external-backends` | External AI APIs, external/internal MCP servers, egress Gateway patterns, ExternalHostname/XBackend concepts, and open-relay risk | Explore safe outbound traffic patterns and security concerns around AI API and MCP server access. |
| 14 | `14-policy-telemetry-and-conformance` | Policy attachment, TelemetryPolicy, MCP tool governance, session persistence, regex portability, and conformance testing | Track emerging Gateway API features that affect portability, AI/MCP security, and production readiness. |

### Part E - Controller portability path

| Chapter | Example / topic | Topic | Purpose |
|---|---|---|---|
| 15 | `15-controller-portability` | NGINX Gateway Fabric, Cilium, Traefik, and Envoy Gateway comparison | Test selected chapters against other controllers and document what is portable, extended, or controller-specific. |

## Target repository structure

The structure below shows the intended project layout. The completed work currently covers `00-ingress-nginx-baseline`, `01-basic-http-route`, the ingress-nginx installer, the NGINX Gateway Fabric installer, and the core apply/delete/local-kind helper scripts. Later chapters, controller notes, reports, advanced helper scripts, and additional controller implementations will be added as the roadmap progresses.

```text
gateway-api-portability-kit/
  README.md
  LICENSE

  docs/
    00-project-story.md              # planned
    01-ingress-to-gateway-api.md     # planned
    02-controller-comparison.md      # planned
    03-migration-checklist.md        # planned
    04-failure-behaviour.md          # planned
    portability-rules.md             # planned
    controller-picker.md             # planned
    ai-gateway-roadmap.md            # planned
    mcp-gateway-notes.md             # planned
    out-of-scope.md                  # planned

  controllers/
    ingress-nginx/
      install.sh
      notes.md                     # planned

    nginx-gateway-fabric/
      install.sh
      notes.md                     # planned
      limitations.md               # planned

    cilium/                        # planned
      install.sh                   # planned
      notes.md                     # planned
      limitations.md               # planned

    traefik/                       # planned
      install.sh                   # planned
      notes.md                     # planned
      limitations.md               # planned

    envoy-gateway/                 # planned
      install.sh                   # planned
      notes.md                     # planned
      limitations.md               # planned

  examples/
    00-ingress-nginx-baseline/
    01-basic-http-route/
    02-routing-rules/              # planned
    03-traffic-splitting/          # planned
    04-advanced-http-routing/      # planned
    05-shared-gateway-governance/  # planned
    06-failure-behaviour/          # planned
    07-tls-termination/            # planned
    08-backend-tls-and-protocols/  # planned
    09-observability-integrations/ # planned
    10-security-integrations/      # planned
    11-multi-cluster-patterns/     # planned
    12-ai-gateway-basics/          # planned
    13-egress-and-external-backends/ # planned
    14-policy-telemetry-and-conformance/ # planned
    15-controller-portability/     # planned

  apps/                            # planned
    echo-v1/                       # planned
    echo-v2/                       # planned
    echo-admin/                    # planned
    mock-ai-service/               # planned
    mock-mcp-server/               # planned

  scripts/
    create-cluster.sh
    delete-cluster.sh        # planned
    install-controller.sh
    apply-example.sh
    delete-example.sh
    patch-gateway-nodeport.sh
    test-routes.sh           # planned
    generate-report.sh       # planned

  reports/
    nginx-gateway-fabric.md          # planned
    cilium.md                        # planned
    traefik.md                       # planned
    envoy-gateway.md                 # planned
```

## Ingress to Gateway API mapping

| Ingress concept | Gateway API concept |
|---|---|
| `IngressClass` | `GatewayClass` |
| `Ingress` | `Gateway` + `HTTPRoute` |
| `rules.host` | `HTTPRoute.spec.hostnames` |
| `paths.path` | `HTTPRoute.rules.matches.path` |
| `backend.service` | `HTTPRoute.rules.backendRefs` |
| `tls.secretName` | `Gateway.listeners.tls.certificateRefs` |
| Controller annotations | Standard Gateway API fields or controller-specific policy resources |

Classic Ingress usually combines infrastructure entry point and application routing in one resource. Gateway API separates these concerns more clearly:

```text
Platform team:
  GatewayClass
  Gateway
  Listener

Application team:
  HTTPRoute
  Backend Service
```

## Core Gateway API model

A basic Gateway API flow looks like this:

```text
Client
  ↓
Gateway
  ↓
HTTPRoute
  ↓
Kubernetes Service
  ↓
Pod
```

Key resources:

| Resource | Purpose |
|---|---|
| `GatewayClass` | Defines the class of Gateway handled by a controller. |
| `Gateway` | Defines where traffic enters the cluster. |
| `Listener` | Defines protocol, port, hostname, and TLS settings on a Gateway. |
| `HTTPRoute` | Defines HTTP routing rules and backend targets. |
| `Service` | Provides the Kubernetes backend target for traffic. |

## Portability model

This project treats portability as something to test, not something to assume.

Future chapters should separate standard Gateway API resources from controller-specific setup where possible:

```text
base/
  Standard Gateway API manifests

overlays/
  nginx-gateway-fabric/
  cilium/
  traefik/
  envoy-gateway/
```

The main learning path uses NGINX Gateway Fabric first. Later, the portability chapter can re-run selected scenarios against other controllers.

Portability ratings used by this project:

| Rating | Meaning |
|---|---|
| P0 | Portable core Gateway API behaviour. |
| P1 | Standard Gateway API behaviour, but support may vary by controller. |
| P2 | Standard resource, but status, behaviour, or operational details differ by controller. |
| P3 | Controller-specific or third-party integration. |
| P4 | Architecture pattern rather than a directly portable manifest. |

Chapter 15 should not blindly retest everything. It should compare a selected portability matrix and document what works, what changes, and what remains implementation-specific.

## Scope and roadmap

The project separates Gateway API adoption into three levels.

### Core runnable path

The first path is designed to be small, practical, and easy to complete:

```text
00-ingress-nginx-baseline
01-basic-http-route
02-routing-rules
03-traffic-splitting
```

This path answers the first migration questions:

- Can we reproduce basic Ingress behaviour with Gateway API?
- Can we migrate common host and path routing patterns?
- Can we show one clear Gateway API value-add with weighted traffic splitting?

### Platform engineering path

The next path shows why Gateway API matters to platform teams:

```text
04-advanced-http-routing
05-shared-gateway-governance
06-failure-behaviour
07-tls-termination
```

This path covers richer HTTP routing, platform/application ownership separation, RBAC alignment, route attachment, ReferenceGrant, failure visibility, and edge TLS.

### Production ecosystem path

The later path explains where Gateway API ends and the wider ecosystem begins:

```text
08-backend-tls-and-protocols
09-observability-integrations
10-security-integrations
11-multi-cluster-patterns
12-ai-gateway-basics
13-egress-and-external-backends
14-policy-telemetry-and-conformance
15-controller-portability
```

These chapters cover advanced protocols, backend TLS, observability, WAF/auth/rate limiting integrations, multi-cluster architecture patterns, AI Gateway, MCP Gateway, egress and external backend patterns, emerging policy/telemetry/conformance topics, and cross-controller portability.

NGINX Gateway Fabric is used as the reference Gateway API implementation for Chapters 01-14 where practical. Chapter 15 introduces Cilium, Traefik, and Envoy Gateway for portability comparison.

## AI Gateway roadmap

AI Gateway is a required part of this project because Gateway API is moving closer to AI, inference, model traffic, MCP server access, external backends, and egress use cases.

Planned AI Gateway topics:

| Area | Planned treatment |
|---|---|
| AI service front door | Route traffic to simple local AI/mock model services through Gateway + HTTPRoute. |
| Inference routing | Document how Gateway API Inference Extension, inference pools, and model-serving concepts relate to this project. |
| MCP Gateway | Route and govern agent-to-tool traffic through MCP servers, including auth, tool filtering, audit, and policy controls. |
| External AI APIs and MCP servers | Explore safe patterns for routing to external AI services and MCP servers without creating open-relay or uncontrolled tool-access risk. |
| Backend/XBackend concepts | Track emerging Backend and XBackend direction without pretending the API is fully stable. |
| Egress Gateway | Treat egress as experimental/emerging and focus on security, separation of roles, and implementation differences. |
| Policy controls | Show how auth, rate limiting, WAF, API-key protection, tool filtering, and namespace boundaries may be layered around AI and MCP traffic. |
| Telemetry | Show AI and MCP traffic observability needs such as latency, errors, route status, tool calls, and controller metrics. |
| Conformance and portability | Compare which AI-related patterns are standard, experimental, controller-specific, or only architecture guidance. |

The AI Gateway track should avoid overclaiming. The first implementation can use mock model services, mock MCP servers, and documented architecture patterns before attempting real model-serving or production MCP integrations.

## Topics close to our plan

The Gateway API community topics that are closest to this project are:

| Community topic | Fit with this project | Planned action |
|---|---|---|
| TCPRoute and UDPRoute | Already close to Chapter 08. | Keep under backend TLS and protocol expansion. |
| Backend / XBackend | Strongly related to AI Gateway and external backend work. | Add to Chapters 12 and 13 as emerging concepts. |
| Gateway API Inference Extension / llm-d | Directly related to AI Gateway. | Track in Chapter 12, initially as architecture notes and mock labs. |
| MCP Gateway | Strongly related to AI Gateway, agentic traffic, and tool governance. | Add under Chapters 12, 13, and 14 as an AI Gateway sub-track. |
| Egress Gateway | Very close to AI API access and external backend risk. | Add Chapter 13 with explicit security warnings. |
| Policy attachment | Already close to governance and security chapters. | Cover in Chapters 05, 10, and 14. |
| Cross-namespace policy attachment | Close to shared Gateway governance and security. | Mention as emerging/advanced, not basic path. |
| TelemetryPolicy | Close to observability. | Add to Chapter 14 as emerging topic. |
| Session persistence | Close to traffic management and Backend policy. | Track in Chapter 14; avoid making it core until stable. |
| Regex path rewrite portability | Close to migration from ingress-nginx annotations. | Cover under advanced routing and conformance. |
| Conformance binary / portable tests | Very close to controller portability. | Use to strengthen Chapter 15 later. |
| ListenerSet / shared Gateway merging | Related to shared Gateway governance. | Mention in Chapter 05/14, but do not make it a first runnable lab yet. |
| Mesh / GAMMA east-west routing | Related, but broad. | Keep as architecture guidance unless a simple runnable scenario is added later. |

## Not in current plan

Some Gateway API-adjacent topics are important but should not be part of the first implementation wave:

| Topic | Why not now | Possible future treatment |
|---|---|---|
| Building a new Gateway API controller | Too large and not aligned with portability-kit positioning. | Only compare existing controllers. |
| Full API management platform | Gateway API can integrate with API management, but this project should not become Kong/Apigee/MuleSoft. | Cover integration points only. |
| Production-grade WAF product | WAF belongs to security integrations, not this repo's core implementation. | Show examples and architecture notes. |
| Full service mesh implementation | Mesh/GAMMA is a large area with its own APIs and controllers. | Keep focused examples only. |
| Full multi-cluster/global traffic controller | Gateway API is a building block, not a complete global traffic product. | Provide architecture pattern notes. |
| Real LLM hosting platform | Running real model infrastructure adds GPU, model-serving, cost, and ops complexity. | Start with mock models; add optional real integrations later. |
| Full MCP platform / registry | MCP gateway patterns are important, but building a complete MCP registry, marketplace, or enterprise control plane is beyond the first implementation wave. | Start with mock MCP servers and gateway/security patterns. |
| Vendor-specific cloud Gateway deep dives | Useful, but would expand scope too early. | Add later as controller reports or appendices. |
| Enterprise compliance product | Important for buyers, but beyond the lab scope. | Mention security/compliance checks as future opportunities. |

## Quick start

Prerequisites:

- Docker
- kubectl
- kind
- Helm

This project intentionally tests Lab 00 and Lab 01 as clean migration steps.

Both labs use the same hostname and local URL:

```text
Host: echo.localtest.me
URL:  http://localhost:8080
```

### Lab 00 - ingress-nginx baseline

Start from a clean local cluster:

```bash
kind delete cluster --name gateway-api-lab 2>/dev/null || true
./scripts/create-cluster.sh
```

Install ingress-nginx:

```bash
./scripts/install-controller.sh ingress-nginx
```

Apply the baseline Ingress example:

```bash
./scripts/apply-example.sh 00-ingress-nginx-baseline
```

Test the route:

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080
```

### Lab 01 - Gateway API equivalent of the ingress-nginx baseline

Recreate the cluster so only one traffic controller owns the local test path:

```bash
kind delete cluster --name gateway-api-lab
./scripts/create-cluster.sh
```

Install NGINX Gateway Fabric:

```bash
./scripts/install-controller.sh nginx-gateway-fabric
```

Apply the Gateway API equivalent:

```bash
./scripts/apply-example.sh 01-basic-http-route
```

NGINX Gateway Fabric creates a Gateway-specific NGINX data plane Service. For local `kind` testing, patch that generated Service to the fixed NodePort used by `scripts/create-cluster.sh`:

```bash
./scripts/patch-gateway-nodeport.sh
```

Test the same route again:

```bash
curl -H "Host: echo.localtest.me" http://localhost:8080
```

This confirms that the same application and hostname work through both models:

```text
Lab 00: localhost:8080 -> ingress-nginx -> Ingress -> echo-v1
Lab 01: localhost:8080 -> NGINX Gateway Fabric -> Gateway + HTTPRoute -> echo-v1
```

## Portability comparison

Chapter 15 compares selected scenarios across Gateway API controllers.

The goal is not to prove that every feature works identically everywhere. The goal is to show which parts are portable, which parts are extended, and which parts depend on the selected implementation.

Recommended portability matrix for Chapter 15:

| Scenario | Expected portability | NGINX Gateway Fabric | Cilium | Traefik | Envoy Gateway |
|---|---|---|---|---|---|
| Basic HTTPRoute | P0 | completed | planned | planned | planned |
| Routing rules | P0/P1 | planned | planned | planned | planned |
| Traffic splitting | P1 | planned | planned | planned | planned |
| Advanced HTTP routing | P1/P2 | planned | planned | planned | planned |
| Shared Gateway governance | P1/P2 | planned | planned | planned | planned |
| Failure behaviour | P2 | planned | planned | planned | planned |
| TLS termination | P1/P2 | planned | planned | planned | planned |
| Backend TLS and protocol expansion | P1/P2/P3 | planned | planned | planned | planned |
| Observability integrations | P3 | planned | planned | planned | planned |
| Security integrations | P3 | planned | planned | planned | planned |
| Multi-cluster patterns | P4 | planned | planned | planned | planned |
| AI Gateway basics | P2/P3/P4 | planned | planned | planned | planned |
| MCP Gateway basics | P2/P3/P4 | planned | planned | planned | planned |
| Egress and external backends | P2/P3/P4 | planned | planned | planned | planned |
| Policy, telemetry, and conformance | P2/P3 | planned | planned | planned | planned |

Each controller report should document:

- installation steps,
- required GatewayClass and Gateway differences,
- Service exposure behaviour,
- supported scenarios,
- required manifest changes,
- status condition behaviour,
- observability notes,
- security integration options,
- limitations,
- and operational trade-offs.

## Controller picker

A simple starting point for choosing a controller:

| Requirement | Possible controllers |
|---|---|
| Migration from ingress-nginx / NGINX familiarity | NGINX Gateway Fabric |
| eBPF networking, security, and observability | Cilium |
| Lightweight local Gateway API lab | Traefik |
| Envoy-based gateway architecture | Envoy Gateway |
| Service mesh and east-west routing | Istio, Cilium |
| API management features | Kong-style platforms |
| Cloud-managed Kubernetes | Cloud provider Gateway API controllers |

Exact feature support depends on the controller version, Gateway API version, and supported conformance profile.

## Portability rules

This project follows these rules:

1. Start with a working `ingress-nginx` baseline where relevant.
2. Express the equivalent behaviour using standard Gateway API resources.
3. Prefer standard Gateway API fields over controller-specific configuration.
4. Keep shared examples controller-neutral where possible.
5. Put controller-specific setup and notes under `controllers/<controller-name>/`.
6. Document required changes when an example is not fully portable.
7. Record status conditions and failure behaviour, not only successful routing.
8. Avoid hiding controller differences behind overly complex scripts.

## Migration checklist

Before migrating an Ingress to Gateway API, review:

- IngressClass usage
- hosts and paths
- TLS secrets
- backend services and ports
- rewrite rules
- rate limiting
- authentication
- CORS
- request and response header manipulation
- body size limits
- timeouts
- cert-manager integration
- external-dns integration
- WAF or security integrations
- controller-specific annotations

Not every annotation maps directly to a standard Gateway API field. Some behaviours may require controller-specific policy resources.

## Status

This project is in early development, but the first migration path is now working and tested locally.

Completed milestones:

```text
v0.1.0 - ingress-nginx baseline with classic Ingress
v0.2.0 - NGINX Gateway Fabric basic Gateway + HTTPRoute equivalent of the ingress-nginx baseline
```

Current working flow:

```text
00-ingress-nginx-baseline
  localhost:8080 -> ingress-nginx -> Ingress -> echo-v1

01-basic-http-route
  localhost:8080 -> NGINX Gateway Fabric -> Gateway + HTTPRoute -> echo-v1
```

Planned milestones:

```text
v0.3.0 - Add routing rules: hostname and path routing
v0.4.0 - Add traffic splitting
v0.5.0 - Add advanced HTTP routing
v0.6.0 - Add shared Gateway governance and failure behaviour
v0.7.0 - Add TLS termination
v0.8.0 - Add backend TLS and protocol expansion notes
v0.9.0 - Add observability and security integration chapters
v1.0.0 - Add AI Gateway, MCP Gateway, and egress/external backend architecture notes
v1.1.0 - Add policy, telemetry, conformance, and controller portability comparison
```

## Project tagline

```text
From ingress-nginx to Gateway API to AI/MCP Gateway: migrate once, compare everywhere.
```

## License

This project is licensed under the Apache License 2.0.

See the `LICENSE` file for details.