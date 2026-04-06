# Project Manifest

> **Entry point for every AI session.** Read this first, then `state.md`.
> Stable document — changes only when fundamental decisions change.

---

## Identity

- **Project:** <!-- e.g. Ardtire Civic Platform -->
- **Purpose:** <!-- One sentence. What does this system do and for whom? -->
- **Domain:** <!-- e.g. Civic governance / Constitutional institution management -->
- **Repository:** <!-- e.g. github.com/org/repo -->

---

## Stack

> Locked decisions. Changing any of these requires an ADR.

- <!-- Runtime: e.g. Node 22 LTS (via mise) -->
- <!-- Frontend framework: -->
- <!-- API framework: -->
- <!-- Database + ORM: -->
- <!-- Auth: -->
- <!-- Package manager + monorepo tooling: pnpm workspaces + Turborepo -->
- <!-- Deployment targets: -->

---

## Architecture Invariants

> These cannot change without a new ADR and a migration plan.

- <!-- e.g. The two-register boundary (exterior Society / interior Kingdom) is a constitutional invariant in all data models and APIs -->
- <!-- e.g. gov-api is the canonical source of truth; Decidim defers to it on conflict -->
- <!-- Add more as they are established -->

---

## Active Phase

See: [`context/state.md`](./state.md)

---

## ADR Index

See: [`docs/architecture/decisions/`](../docs/architecture/decisions/)

Notable decisions:
- ADR-000 — Template (read before writing a new ADR)
<!-- Add entries as ADRs are created: -->
<!-- - ADR-001 — Use SolidJS with TanStack ecosystem -->

---

## Key Contacts / Roles

<!-- Remove this section if solo project -->
- **Architect / Lead:** <!-- name or handle -->
- **On-call runbook:** [`docs/runbooks/incident-response.md`](../docs/runbooks/incident-response.md)
