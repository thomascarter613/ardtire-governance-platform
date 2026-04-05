# Monitoring

## Current State (Phase 0)

Monitoring infrastructure is not yet in place.
This document records the intended monitoring posture to be implemented in Phase 4.

## Intended Monitoring Stack

| Component | Tool | Notes |
|---|---|---|
| Metrics collection | Prometheus (self-hosted) | Scrapes `/metrics` endpoint |
| Metrics visualisation | Grafana (self-hosted) | Dashboards per bounded context |
| Log aggregation | Loki (self-hosted) | Paired with Grafana |
| Alerting | Grafana Alerting | Routes to email initially |
| Uptime | Uptime Kuma (self-hosted) | External health check |

## Alert Thresholds (Planned)

| Condition | Threshold | Severity |
|---|---|---|
| API P95 latency | > 1000 ms sustained 5 min | Warning |
| API error rate | > 1% of requests over 5 min | Critical |
| Database connection failures | Any | Critical |
| Audit log emission failures | Any | Critical |
| Disk usage | > 80% | Warning |
| Disk usage | > 95% | Critical |
| Keycloak unavailable | > 30 seconds | Critical |

## Backup Monitoring

- Daily backup completion must be verified and logged.
- Backup failure must trigger an alert.
- Monthly restore tests must be documented.

## On-Call

No formal on-call rotation. The operator (Thomas J. Carter) is the sole responder.
All critical alerts route to `thomas.carter@appliedinnovationcorp.com`.

See [Incident Response](../runbooks/incident-response.md) for response procedures.
