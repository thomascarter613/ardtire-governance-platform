# Milestones

## M0 — Repository Baseline

**Status:** In Progress

All pre-code documentation, toolchain configuration, and repository scaffolding complete.
No application code. Repo is fully specified and ready for Phase 1 implementation.

**Exit Criteria:**
- Complete docs suite merged to `main`
- All tooling packages configured and passing
- CI pipeline green on initial commit
- Architecture specifications reviewed and accepted

## M1 — Identity Foundation

**Status:** Not Started

Working Keycloak integration with member authentication and basic role enforcement.

**Exit Criteria:**
- A new member can register, verify, and authenticate
- JWT tokens are issued and validated correctly
- Role claims are enforced at the API layer
- Audit log records authentication events

## M2 — Membership Administration

**Status:** Not Started

Officers can manage the full member lifecycle.

**Exit Criteria:**
- Member applications can be submitted, reviewed, and decided
- Members can be promoted, suspended, or expelled via governed workflow
- Member standing is correctly reflected in permission decisions
- All membership mutations appear in the audit log

## M3 — Governance Lifecycle MVP

**Status:** Not Started

A proposal can travel from submission to ratification.

**Exit Criteria:**
- A member can submit a proposal
- Deliberation period opens and closes correctly
- A vote is conducted with correct eligibility enforcement
- A ratified outcome is recorded with rule-version reference
- The complete lifecycle is present in the audit log

## M4 — Production Ready

**Status:** Not Started

Platform is stable, documented, monitored, and deployed to production.

**Exit Criteria:**
- All Phase 0–3 work merged and passing CI
- Monitoring and alerting configured
- Backup and recovery tested against RTO/RPO targets
- Accessibility audit passed
- Production deployment documented
