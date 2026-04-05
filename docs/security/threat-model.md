# Threat Model

## Scope

This threat model covers the Ardtire Governance Platform in its initial self-hosted,
Docker Compose configuration.

## Assets

| Asset | Sensitivity | Notes |
|---|---|---|
| Governance outcomes (votes, ratifications) | Critical | Must not be tampered with or forged |
| Audit log | Critical | Must be append-only and tamper-evident |
| Member identity data | High | PII — names, emails, roles |
| Authentication tokens | High | JWT — must be short-lived and validated |
| Constitutional documents (canon) | High | Immutability is a hard requirement |
| Member credentials | High | Managed by Keycloak — not stored by platform |
| API keys and secrets | High | Environment variables — never in source control |

## Threat Actors

| Actor | Motivation | Capability |
|---|---|---|
| Unauthenticated external attacker | Data exfiltration, disruption | Low to Medium |
| Authenticated member (malicious) | Privilege escalation, vote manipulation | Medium |
| Compromised member account | Identity theft, impersonation | Medium |
| Insider (operator) | Unauthorized record manipulation | High |

## Threats and Mitigations

### T-01: Unauthorized API Access
**Threat:** An attacker accesses governance endpoints without a valid token.
**Mitigation:** All non-public endpoints require a valid JWT validated on every request.

### T-02: Privilege Escalation
**Threat:** A member accesses resources or actions above their permission level.
**Mitigation:** Five-factor permission enforcement at the API handler layer on every request.

### T-03: Vote Manipulation
**Threat:** A member casts multiple votes or modifies a recorded vote.
**Mitigation:** Vote eligibility is locked at vote-open time. Votes are immutable once cast.
All vote events are audit-logged.

### T-04: Audit Log Tampering
**Threat:** An operator or attacker deletes or modifies audit log entries.
**Mitigation:** Audit log is append-only at the database constraint level.
No update or delete operations are exposed.

### T-05: Governance Record Forgery
**Threat:** A ratified record is modified after publication.
**Mitigation:** Published records are immutable at the application and database constraint level.

### T-06: Token Replay
**Threat:** A stolen JWT is reused after the legitimate session ends.
**Mitigation:** Short token lifetimes. Refresh tokens are rotated on use.
Step-up required for sensitive actions.

### T-07: Secrets Exposure
**Threat:** Database credentials, API keys, or JWT signing keys are exposed.
**Mitigation:** All secrets in environment variables. `.env` files excluded from version control.
Secrets are never logged. Secret rotation is documented in the runbooks.

## Out of Scope for This Model

- Physical infrastructure attacks
- Keycloak internal security (treated as a trust boundary)
- Attacks on the VPS host OS
- Network-level DDoS
