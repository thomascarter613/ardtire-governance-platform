# Roadmap

## Phase 0 — Baseline (Current)

**Goal:** Fully specified, documented, and scaffolded repository before any application code.

- [x] Repository scaffold and toolchain configuration
- [x] Pre-code documentation suite
- [x] Architecture specification
- [x] Governance domain model definition
- [ ] Prisma schema (30+ tables)
- [ ] OpenAPI specification (complete)
- [ ] ADR set for all major initial decisions

## Phase 1 — Core Identity and Membership

**Goal:** Working authentication, member registration, and basic role enforcement.

- [ ] Keycloak realm configuration (public, member, admin)
- [ ] `gov-api` bootstrap with auth middleware
- [ ] Member registration and onboarding flow
- [ ] Role and permission enforcement layer
- [ ] Audit log infrastructure

## Phase 2 — Governance Lifecycle

**Goal:** Full proposal → deliberation → vote → ratification pipeline.

- [ ] Proposal intake and submission
- [ ] Deliberation period with commenting
- [ ] Voting mechanics with rule-version binding
- [ ] Ratification workflow
- [ ] Officer and Sovereign action surfaces

## Phase 3 — Publication and Records

**Goal:** Official record publication and canonical document management.

- [ ] Publication pipeline for ratified records
- [ ] Document canon management via CMS
- [ ] Meilisearch indexing for public record search
- [ ] Record supersession workflow

## Phase 4 — Administration and Operations

**Goal:** Complete internal tooling and production-hardening.

- [ ] Admin portal feature completion
- [ ] Monitoring and observability instrumentation
- [ ] Backup and recovery runbooks tested against RTO/RPO
- [ ] Accessibility audit (WCAG 2.1 AA)
- [ ] Security review

## Phase 5 — Production Deployment

**Goal:** Stable production environment with documented operational procedures.

- [ ] Production infrastructure provisioned
- [ ] Domain and TLS configured
- [ ] Production data seeding
- [ ] Operational handbooks complete
