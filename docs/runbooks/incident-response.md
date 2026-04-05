# Incident Response Runbook

## Severity Definitions

| Severity | Definition |
|---|---|
| **P1 — Critical** | Platform is down or governance records are at risk of corruption |
| **P2 — High** | Major feature degraded; members cannot complete governance workflows |
| **P3 — Medium** | Minor feature degraded; workaround available |
| **P4 — Low** | Cosmetic issue or minor degradation with no functional impact |

## P1 Response Procedure

1. **Assess** — Determine scope. Full platform down or single service?
2. **Preserve** — Capture current state before taking any action:
   ```bash
   docker compose ps
   docker compose logs --tail=200 > /tmp/incident-$(date +%Y%m%d-%H%M%S).log
   ```
3. **Isolate** — If governance records may be at risk, take the API offline:
   ```bash
   docker compose stop gov-api
   ```
4. **Diagnose** — Review logs, recent deployments, database state.
5. **Remediate** — Apply the minimum change necessary to restore service.
6. **Verify** — Confirm health endpoints return 200.
7. **Document** — Record the incident: timeline, root cause, remediation, follow-up.

## Common Failure Scenarios

### Database Unavailable

```bash
docker compose restart postgres
docker compose exec postgres pg_isready -U postgres
```

### Keycloak Unavailable

```bash
docker compose restart keycloak
# Allow 60 seconds for startup before checking health
```

### Out of Disk Space

```bash
df -h
docker system prune --volumes  # WARNING: removes unused volumes
```

### High API Latency

1. Check database query performance.
2. Check for long-running transactions.
3. Review recent deployments for unindexed queries.

## Rollback Procedure

```bash
docker compose pull
docker compose up -d --force-recreate
```

## Post-Incident

All P1 and P2 incidents require a written post-mortem within 48 hours:
- Timeline of events
- Root cause
- Resolution steps
- Prevention measures

**RTO target:** 8 hours from incident declaration to service restoration.
**RPO target:** 24 hours maximum data loss window.
