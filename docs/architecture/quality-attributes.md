# Quality Attributes

## Priority Order

When trade-offs must be made, quality attributes are prioritized in this order:

1. **Correctness** — governance outcomes must be accurate and rule-compliant
2. **Auditability** — all consequential actions must be permanently traceable
3. **Security** — institutional access controls must hold under adversarial conditions
4. **Availability** — the platform must be reliably accessible
5. **Usability** — interfaces must be accessible and clear
6. **Performance** — response times must be acceptable for governance workflows
7. **Maintainability** — the codebase must remain manageable by a single engineer

## Non-Functional Targets

| Attribute | Target | Notes |
|---|---|---|
| Availability | 99.5% | Self-hosted VPS baseline |
| P95 API Latency | < 500 ms | Standard CRUD and read operations under normal load |
| Audit Coverage | 100% | All governance-critical mutations must be logged |
| RPO | 24 hours | Maximum acceptable data loss window |
| RTO | 8 hours | Maximum acceptable restoration time |
| Accessibility | WCAG 2.1 AA | All public and member-facing interfaces |

## Correctness

- Governance state transitions are validated against the active rule version before execution.
- Invalid transitions are rejected at the API layer before any persistence occurs.
- No optimistic mutations on governance-critical paths.

## Auditability

- Every state-changing operation on governance resources emits an audit record.
- Audit records include: actor ID, action type, resource type, resource ID, before/after state diff,
  timestamp, and rule version reference.
- Audit records are append-only. No update or delete operations are permitted on the audit log.

## Security

- Step-up authentication is required for high-sensitivity actions (ratification, role assignment,
  record finalization, member suspension or expulsion).
- All API endpoints enforce permission checks at the handler layer.
- Permissions are derived from the five-factor model: tier × standing × role × office × rule_version.

## Availability

- Correctness takes precedence over availability.
- Under split-brain or degraded state conditions, governance operations fail closed.

## Performance

- Search operations via Meilisearch may have higher latency than standard API reads.
- Background processing must not block governance API response paths.
