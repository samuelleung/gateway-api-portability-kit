# Gateway API Portability Kit

A hands-on Kubernetes lab for migrating from **ingress-nginx** to **Gateway API**, then comparing portability across multiple Gateway API controllers.

## Overview

Many Kubernetes users start with `ingress-nginx` because it is familiar, widely adopted, and easy to run locally. Gateway API is the newer Kubernetes-native traffic-management API, but unlike the way many users treat `ingress-nginx` in the Ingress world, Gateway API has **no single default controller**.

This project uses a practical migration story:

```text
ingress-nginx baseline
  ↓
Gateway API equivalent
  ↓
Controller portability comparison
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
- Separate standard Gateway API resources from controller-specific configuration.
- Document portability notes, limitations, status conditions, and implementation differences.
- Keep the examples simple enough to run locally with `kind` or `k3d`.

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

| Stage | Controller / implementation | Purpose |
|---|---|---|
| Baseline | ingress-nginx | Show the familiar Ingress pattern many users already know. |
| First Gateway API target | NGINX Gateway Fabric | Natural migration path for users coming from NGINX / ingress-nginx. |
| Platform networking target | Cilium Gateway API | Modern Kubernetes networking, security, observability, and eBPF story. |
| Developer-friendly target | Traefik Gateway API | Lightweight local lab and simple developer experience. |
| Envoy-based target | Envoy Gateway | Envoy data-plane architecture and Gateway API implementation comparison. |

## Lab sequence

The project starts with an Ingress baseline, then migrates the same scenarios to Gateway API.

| Lab | Scenario | Purpose |
|---|---|---|
| `00-ingress-nginx-baseline` | Classic Ingress with ingress-nginx | Establish the known baseline. |
| `01-basic-http-route` | Basic Gateway + HTTPRoute | First Gateway API equivalent. |
| `02-hostname-routing` | Host-based routing | Compare Ingress host rules with HTTPRoute hostnames. |
| `03-path-routing` | Path-based routing | Compare Ingress paths with HTTPRoute path matches. |
| `04-weighted-traffic-splitting` | Weighted backends | Demonstrate traffic splitting and canary-style routing. |
| `05-header-routing` | Header-based routing | Show routing patterns that are cleaner in Gateway API. |
| `06-tls-termination` | HTTPS listener and certificate reference | Compare Ingress TLS with Gateway listener TLS. |
| `07-cross-namespace-routing` | Shared Gateway with app-owned routes | Demonstrate role separation and route attachment. |
| `08-failure-behaviour` | Invalid backend, invalid port, unattached route | Compare status conditions and failure visibility. |

## Repository structure

```text
gateway-api-portability-kit/
  README.md
  LICENSE

  docs/
    00-project-story.md
    01-ingress-to-gateway-api.md
    02-controller-comparison.md
    03-migration-checklist.md
    04-failure-behaviour.md
    portability-rules.md
    controller-picker.md

  controllers/
    ingress-nginx/
      install.sh
      notes.md

    nginx-gateway-fabric/
      install.sh
      notes.md
      limitations.md

    cilium/
      install.sh
      notes.md
      limitations.md

    traefik/
      install.sh
      notes.md
      limitations.md

    envoy-gateway/
      install.sh
      notes.md
      limitations.md

  examples/
    00-ingress-nginx-baseline/
    01-basic-http-route/
    02-hostname-routing/
    03-path-routing/
    04-weighted-traffic-splitting/
    05-header-routing/
    06-tls-termination/
    07-cross-namespace-routing/
    08-failure-behaviour/

  apps/
    echo-v1/
    echo-v2/
    echo-admin/

  scripts/
    create-cluster.sh
    delete-cluster.sh
    install-controller.sh
    apply-example.sh
    test-routes.sh
    generate-report.sh

  reports/
    nginx-gateway-fabric.md
    cilium.md
    traefik.md
    envoy-gateway.md
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

## MVP scope

The first milestone focuses on the migration baseline:

```text
kind
ingress-nginx
sample echo application
classic Ingress
Gateway API CRDs
NGINX Gateway Fabric
Gateway
HTTPRoute
curl validation
migration notes
```

NGINX Gateway Fabric is used as the first Gateway API implementation because it provides the most natural migration story for users already familiar with NGINX and `ingress-nginx`.

Traefik and Cilium are planned next for portability comparison.

## Quick start

Prerequisites:

- Docker
- kubectl
- kind or k3d
- Helm

Create a local cluster:

```bash
./scripts/create-cluster.sh
```

Install the ingress-nginx baseline:

```bash
./scripts/install-controller.sh ingress-nginx
```

Apply the baseline Ingress example:

```bash
./scripts/apply-example.sh 00-ingress-nginx-baseline
```

Test the route:

```bash
./scripts/test-routes.sh
```

Then install the first Gateway API controller:

```bash
./scripts/install-controller.sh nginx-gateway-fabric
```

Apply the Gateway API equivalent:

```bash
./scripts/apply-example.sh 01-basic-http-route
```

Test again:

```bash
./scripts/test-routes.sh
```

## Portability comparison

The same Gateway API scenario should be tested across controllers where possible.

| Scenario | NGINX Gateway Fabric | Cilium | Traefik | Envoy Gateway |
|---|---|---|---|---|
| Basic HTTPRoute | planned | planned | planned | planned |
| Hostname routing | planned | planned | planned | planned |
| Path routing | planned | planned | planned | planned |
| Weighted traffic splitting | planned | planned | planned | planned |
| Header routing | planned | planned | planned | planned |
| TLS termination | planned | planned | planned | planned |
| Cross-namespace routing | planned | planned | planned | planned |
| Failure behaviour | planned | planned | planned | planned |

Each controller report should document:

- installation steps,
- supported scenarios,
- required manifest changes,
- status condition behaviour,
- observability notes,
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

This project is in early development.

Initial milestone:

```text
v0.1 - ingress-nginx baseline and NGINX Gateway Fabric basic HTTPRoute
```

Planned milestones:

```text
v0.2 - Add Traefik Gateway API comparison
v0.3 - Add Cilium Gateway API comparison
v0.4 - Add controller comparison reports
v0.5 - Add traffic splitting, cross-namespace routing, and failure behaviour labs
v0.6 - Add Envoy Gateway comparison
```

## Project tagline

```text
From ingress-nginx to Gateway API: migrate once, compare everywhere.
```

## License

This project is licensed under the Apache License 2.0.

See the `LICENSE` file for details.