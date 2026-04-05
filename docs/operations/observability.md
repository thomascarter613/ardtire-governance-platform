# Observability

## Principle

The platform is operated by a single engineer. Observability tooling must be proportionate
to that reality — comprehensive enough to diagnose issues quickly, not so complex that it
becomes a maintenance burden.

## Logging

- All application logs are structured JSON.
- Log levels: `error`, `warn`, `info`, `debug`.
- Production runs at `info` level.
- Logs must never contain: plaintext passwords, tokens, PII, or secret values.
- All governance-critical mutations log at `info` level with resource type, resource ID, actor, and action.
- All errors log at `error` level with full stack trace and correlation ID.

## Correlation IDs

Every inbound HTTP request receives a correlation ID (`X-Correlation-Id` header).
The correlation ID appears in every log line for that request.
If the client provides a correlation ID it is used; otherwise one is generated.

## Metrics (Planned — Phase 4)

| Metric | Type | Description |
|---|---|---|
| `http_request_duration_ms` | Histogram | API response time by route and status |
| `governance_proposals_total` | Counter | Total proposals by status |
| `governance_votes_cast_total` | Counter | Total votes cast |
| `audit_log_entries_total` | Counter | Total audit events emitted |
| `auth_failures_total` | Counter | Authentication failures by reason |
| `db_query_duration_ms` | Histogram | Database query time by operation |
| `queue_job_duration_ms` | Histogram | Background job duration by type |

## Tracing (Planned — Phase 4)

OpenTelemetry distributed tracing. Trace IDs must be propagated through:
- Inbound HTTP requests (`traceparent` header)
- Database queries
- Background job execution

All traces must include: `service.name`, `service.version`, `deployment.environment`.

## Health Endpoints

- `GET /health` — liveness check. Returns 200 if the process is running.
- `GET /health/ready` — readiness check. Returns 200 only if all dependencies are healthy.
