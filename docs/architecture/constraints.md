# Architectural Constraints

## Technical Constraints

### Deployment
- Initial deployment is single-VPS, Docker Compose based.
- No managed Kubernetes or cloud-native orchestration in v1.
- Must be operable by a single engineer without a dedicated operations team.
- All services must be self-hostable. No hard dependencies on proprietary cloud services.

### Identity
- Keycloak is the sole identity provider. No alternative IdP integration in v1.
- Three distinct Keycloak realms must be maintained: public, member, and admin.
- Token encryption at rest is required for sensitive claims.

### Governance Logic
- All canonical governance logic resides in `apps/gov-api`.
- No frontend surface is permitted to be the source of truth for a governance outcome.
- Third-party participation tools are advisory and participatory — not authoritative.
- Governance outcomes must reference the rule version active at the time of decision.

### Data
- Ratified and published governance records are immutable except by formal supersession.
- Supersession must itself be a governed, audited process.
- All consequential mutations must emit an audit event before the mutation is committed.

## Legal and Governance Constraints

- The platform must support dual-register separation: public society layer vs. protected Kingdom institution.
- The boundary between registers must be enforced at the API layer, not assumed at the UI layer.
- Permission decisions must combine RBAC (role) and ABAC (attribute) factors.
- Publication of official records must support treatment as legal institutional records.

## Organizational Constraints

- Single engineer maintains and operates the platform.
- Complexity budget is allocated to domain correctness, not infrastructure novelty.
- Documentation is a first-class artifact. Undocumented decisions are not acceptable.
- Pre-code specification rigor is required before major implementation phases.
