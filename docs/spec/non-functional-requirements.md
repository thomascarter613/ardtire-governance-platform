# Non-Functional Requirements

## NFR-001: Correctness

- Governance state transitions must be validated against the active rule version before execution.
- Invalid transitions must be rejected at the API layer.
- No optimistic writes on governance-critical paths.
- Eventual consistency is not acceptable for governance state.

## NFR-002: Auditability

- 100% of governance-critical mutations must produce an audit record.
- Audit coverage is enforced in tests, not assumed by policy.
- The audit log must be queryable by: actor, resource, action type, time range, rule version.

## NFR-003: Security

- All endpoints must require authentication unless explicitly marked public.
- Permission enforcement must occur at the handler layer in `gov-api`.
- Step-up authentication must be required for: ratification, role assignment, member suspension
  or expulsion, and record finalization.
- JWT tokens must be validated on every request.
- Security events must be logged.

## NFR-004: Availability

- Target: 99.5% availability on a self-hosted VPS.
- Correctness takes precedence over availability.
- Under ambiguous state conditions, the platform fails closed.

## NFR-005: Performance

- P95 API latency for standard CRUD and read operations: < 500 ms under normal load.
- Search response time: < 1 second for full-text queries under normal load.
- Background jobs must not block governance API response paths.
- Query plan reviews are required for any query on tables with >10k rows.

## NFR-006: Recoverability

- RPO (Recovery Point Objective): 24 hours.
- RTO (Recovery Time Objective): 8 hours.
- Backup strategy must be documented and tested.
- Restore procedures must be runbook-documented.

## NFR-007: Accessibility

- All public and member-facing web interfaces must meet WCAG 2.1 AA.
- Accessibility is validated as part of the release checklist.
- Keyboard navigation must be fully functional for all governance workflows.

## NFR-008: Maintainability

- The codebase must be operable by a single engineer.
- All non-obvious decisions must be documented in ADRs.
- Test coverage must exceed 80% on lines and functions for all governance-critical modules.

## NFR-009: Privacy

- Member personal data must not appear in logs in plaintext.
- Search indexing must exclude fields designated as private.
- Data retention policies must be documented and enforced.
