

# Gateway API Portability Kit

A vendor-neutral Kubernetes Gateway API lab for comparing Gateway API controllers using shared, portable examples.

## Overview

Gateway API Portability Kit helps users explore Kubernetes Gateway API as a standard traffic-management API, separate from any single controller implementation.

The project provides reusable examples and controller-specific setup notes so users can test the same Gateway API patterns across different implementations such as Traefik, Envoy Gateway, NGINX Gateway Fabric, Kong, Cilium, Istio, and cloud-managed Gateway API controllers.

```text
Gateway API first.
Controller second.
```

Gateway API defines the desired traffic model. A controller implements that model in a Kubernetes cluster.

## Why this project exists

Many Kubernetes environments still expose applications with classic Ingress resources and controller-specific annotations. This can make routing behaviour difficult to standardise across teams, clusters, and vendors.

Gateway API introduces a more expressive and role-oriented model for Kubernetes traffic management. This project focuses on practical examples that show what can be kept portable and what may still depend on a specific controller.

## Goals

- Provide portable Gateway API examples.
- Compare multiple Gateway API controllers using the same scenarios.
- Separate standard Gateway API resources from controller-specific configuration.
- Demonstrate common migration patterns from Ingress to Gateway API.
- Document portability notes, limitations, and implementation differences.
- Keep the examples simple enough to run locally with `kind` or `k3d`.

## Supported controllers

The initial scope focuses on:

- Traefik
- Envoy Gateway
- NGINX Gateway Fabric

Future examples may include:

- Kong
- Cilium
- Istio
- Cloud-managed Gateway API controllers

## Example scenarios

Planned examples include:

- Basic HTTP routing
- Path-based routing
- Header-based routing
- Weighted traffic splitting
- Canary routing
- Cross-namespace route attachment
- TLS termination
- Backend TLS patterns
- gRPC routing
- TCP routing
- AI / API gateway routing patterns

## Repository structure

```text
gateway-api-portability-kit/
  README.md

  docs/
    why-gateway-api.md
    controller-picker.md
    decision-matrix.md
    portability-rules.md
    ingress-migration.md
    enterprise-patterns.md
    ai-gateway-pattern.md

  controllers/
    traefik/
      install.sh
      notes.md
      limitations.md

    envoy-gateway/
      install.sh
      notes.md
      limitations.md

    nginx-gateway-fabric/
      install.sh
      notes.md
      limitations.md

  examples/
    01-basic-http-route/
    02-path-routing/
    03-header-routing/
    04-traffic-splitting/
    05-cross-namespace-routing/
    06-tls-termination/
    07-backend-tls/
    08-grpc-route/
    09-tcp-route/
    10-ai-api-gateway/

  scripts/
    create-cluster.sh
    delete-cluster.sh
    install-controller.sh
    apply-example.sh
    test-routes.sh
    generate-report.sh

  reports/
    traefik.md
    envoy-gateway.md
    nginx-gateway-fabric.md
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

## MVP: basic HTTPRoute

The first runnable example uses:

```text
kind
Gateway API CRDs
Traefik as the first reference controller
whoami demo application
Gateway
HTTPRoute
curl validation
```

Traefik is used first because it is lightweight and easy to run locally. The examples are designed so they can later be tested against Envoy Gateway and NGINX Gateway Fabric.

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

Install a controller:

```bash
./scripts/install-controller.sh traefik
```

Apply an example:

```bash
./scripts/apply-example.sh 01-basic-http-route
```

Test the route:

```bash
./scripts/test-routes.sh
```

## Controller picker

A simple starting point for choosing a controller:

| Requirement | Possible controllers |
|---|---|
| Simple local Gateway API lab | Traefik |
| Ingress replacement | Traefik, NGINX Gateway Fabric, Envoy Gateway |
| Envoy-based gateway | Envoy Gateway |
| Existing NGINX environment | NGINX Gateway Fabric |
| API management features | Kong-style platforms |
| eBPF networking and security | Cilium |
| Service mesh and east-west routing | Istio, Cilium |
| Cloud-managed Kubernetes | Cloud provider Gateway API controllers |

Exact feature support depends on the controller version, Gateway API version, and supported conformance profile.

## Portability rules

This project follows these rules:

1. Prefer standard Gateway API resources where possible.
2. Keep shared examples controller-neutral.
3. Put controller-specific settings under `controllers/<controller-name>/`.
4. Document required changes when an example is not fully portable.
5. Avoid hiding controller differences behind overly complex scripts.

## Status

This project is in early development.

Initial milestone:

```text
v0.1 - Basic HTTPRoute with Traefik
```

Planned milestones:

```text
v0.2 - Add Envoy Gateway implementation
v0.3 - Add NGINX Gateway Fabric implementation
v0.4 - Add controller comparison reports
v0.5 - Add traffic splitting and cross-namespace examples
```

## License

License to be decided.