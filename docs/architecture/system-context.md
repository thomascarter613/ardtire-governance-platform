# System Context

## Position in the Ardtire Society

The Ardtire Governance Platform is the sole authoritative digital system for the institutional
operations of the Ardtire Society. It is not one system among several — it is the governance system.

## Actors

### Primary Users

| Actor | Description |
|---|---|
| **Sovereign / Head of State** | Highest authority. Full platform access. |
| **Officers** | Appointed officials with domain-specific administrative roles |
| **Full Members** | Enrolled members with voting rights and deliberation participation |
| **Associate Members** | Limited-rights members, observers and candidates |
| **Public Visitors** | Read-only access to published records |

### System Actors

| Actor | Description |
|---|---|
| **Keycloak** | Identity and access management — issues tokens, enforces realm boundaries |
| **PostgreSQL** | Primary persistence layer for all governance state |
| **Meilisearch** | Full-text search over member-facing document collections |
| **Background Worker** | Asynchronous job processing (notifications, scheduled tasks) |

## External Integrations (Planned)

| System | Purpose | Status |
|---|---|---|
| Email provider (SMTP) | Transactional governance notifications | Planned |
| Document storage | Archival of ratified records | Planned |

## System Boundaries

The platform is responsible for:
- All governance process state (proposals, votes, ratifications)
- Member identity and standing records
- Role and permission enforcement
- Official publication and record archiving
- Audit logging of all consequential actions

The platform is explicitly not responsible for:
- External communications outside the platform
- Financial transactions
- Territorial or physical operations
- General-purpose content publishing unrelated to governance
