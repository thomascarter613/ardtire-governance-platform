# Architecture Overview

## Platform Summary

The Ardtire Governance Platform is the canonical digital infrastructure for the Ardtire Society.
It provides formal governance workflows including membership administration, proposal lifecycle
management, deliberation, voting, ratification, publication, and immutable institutional recordkeeping.

## Architectural Style

**Modular monolith with bounded contexts**, deployed as a small set of cooperating applications
within a single Turborepo monorepo. Service boundaries are enforced at the module and package level,
not at the network level. This approach preserves deployment simplicity appropriate for a
single-engineer operation while maintaining structural discipline for future decomposition.

## Bounded Contexts

| Context | Responsibility |
|---|---|
| **Identity & Access** | Authentication, session management, role assignment, permission enforcement |
| **Membership** | Member lifecycle, tiers, standing, applications, records |
| **Governance** | Proposal intake, deliberation, voting, ratification, rule versioning |
| **Publication** | Official record publication, canon document management |
| **Audit** | Immutable event log of all consequential state changes |
| **Notifications** | Member-facing communication across governance events |
| **Administration** | Internal tooling for officers and system operators |

## Applications

| App | Purpose |
|---|---|
| `apps/gov-api` | Core governance API — canonical source of truth for all governance state |
| `apps/web` | Public-facing member portal |
| `apps/admin` | Internal administrative interface |
| `apps/cms` | Content management for official documents and publications |
| `apps/worker` | Background job processing |

## Key Architectural Decisions

- `gov-api` is the single canonical source of truth for all governance outcomes.
- No frontend surface or third-party integration is authoritative for governance state.
- All consequential mutations are recorded in the audit log with actor, timestamp, rule version, and diff.
- Permissions are enforced at the API layer, not in the UI.
- Governance records, once ratified and published, are immutable except by formal supersession.

## Infrastructure

- **Runtime**: Node.js 22, pnpm workspaces, Turborepo 2.5.0
- **Language**: TypeScript 5.8 (strict)
- **Identity**: Keycloak (three realms: public, member, admin)
- **Database**: PostgreSQL 16
- **Search**: Meilisearch
- **Email**: Mailpit (local dev), SMTP (production)
- **Deployment**: Docker Compose (initial), self-hosted VPS

## Further Reading

- [System Context](system-context.md)
- [Constraints](constraints.md)
- [Quality Attributes](quality-attributes.md)
- [Architecture Decision Records](decisions/)
