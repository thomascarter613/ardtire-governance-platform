# Architecture

> System boundaries, data flow, and structural decisions.
> Written for AI consumers first — dense, no prose padding.
> Update when boundaries or flows change; open an ADR first.

---

## System Context

<!-- One paragraph. What is the system, who uses it, what does it touch?
     Refer to docs/architecture/system-context.md for the full diagram.
-->

---

## Application Surfaces

<!-- List each app/surface, its role, and its entry point in the monorepo. -->

| Surface   | Role                          | Path              | Deployed to |
|-----------|-------------------------------|-------------------|-------------|
|           |                               |                   |             |

---

## Package Graph

<!-- Describe the internal dependency graph at a high level.
     What do shared packages export? What consumes them?
     Full diagram: docs/architecture/diagrams/
-->

```
apps/
  ├── [app-a]          → consumes: packages/[x], packages/[y]
  └── [app-b]          → consumes: packages/[x]
packages/
  ├── [x]              → no internal deps
  └── [y]              → consumes: packages/[x]
tooling/
  ├── tsconfig         → consumed by all
  └── vitest-config    → consumed by all
```

---

## Data Flow

<!-- Describe the primary request/response paths.
     e.g. "Web → gov-api (OIDC-protected) → Postgres via Prisma"
     Keep this to the happy path; edge cases belong in runbooks.
-->

---

## Auth Model

<!-- Who authenticates? How? What are the trust boundaries?
     e.g. "Keycloak with three realms: public, member, admin.
           Five OIDC clients. All API routes validate JWTs at middleware layer."
-->

---

## Persistence

<!-- What data stores are used? What owns what data?
     e.g. "PostgreSQL (primary, all relational data via Prisma)
           Redis (session cache, job queue backing store)"
-->

---

## External Integrations

<!-- Any third-party APIs, webhooks, or external services. -->

| Service | Purpose | Integration point |
|---------|---------|-------------------|
|         |         |                   |

---

## Critical Constraints

<!-- Things the architecture cannot violate. Non-negotiable.
     These should mirror or reference the invariants in manifest.md.
-->

- 

---

## Known Tradeoffs

<!-- Deliberate architectural tradeoffs and the reasoning behind them.
     Reference the ADR where one exists.
-->

- 
