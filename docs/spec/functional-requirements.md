# Functional Requirements

## FR-001: Member Registration and Identity

- The platform must allow prospective members to register with a verified identity.
- Registration must create a Keycloak account in the appropriate realm.
- New registrants begin as Associate Members until elevated through a governed process.
- Identity verification requirements are enforced per membership tier.

## FR-002: Authentication and Session Management

- The platform must authenticate members via Keycloak using PKCE.
- Session tokens must be short-lived and refreshable.
- Step-up authentication must be required for high-sensitivity governance actions.
- All authentication events must be recorded in the audit log.

## FR-003: Role and Permission Enforcement

- The platform must enforce a five-factor permission model: tier × standing × role × office × rule_version.
- Permission checks must occur at the API layer, not in the UI.
- Unauthorized access attempts must be rejected and logged.

## FR-004: Proposal Submission

- Full Members and Officers must be able to submit governance proposals.
- A proposal must record: submitter, submission timestamp, content, and rule version at time of submission.
- Proposals must be validated against submission rules before entering the governance lifecycle.

## FR-005: Deliberation

- Upon intake approval, a proposal must enter a deliberation period with defined start and end times.
- Members with appropriate standing may submit deliberation comments.
- The deliberation period must close automatically at the scheduled end time.
- Deliberation records are advisory and do not constitute binding governance outcomes.

## FR-006: Voting

- Upon deliberation close, a vote must open for eligible members.
- Vote eligibility must be computed at vote-open time and locked for the duration of the vote.
- Each eligible member may cast exactly one vote per proposal.
- Vote results must be computed and recorded upon vote close.
- The vote record must reference the active rule version.

## FR-007: Ratification

- Following a successful vote, the outcome must proceed to ratification by the appropriate authority.
- Ratification requires step-up authentication.
- A ratification action must record: actor, timestamp, outcome reference, and authority basis.

## FR-008: Publication

- Ratified outcomes must be publishable to the official canon.
- Published records must be immutable.
- Publication must make records accessible to authorized readers.
- Publication must trigger appropriate member notifications.

## FR-009: Audit Log

- All consequential state changes must emit an audit record before the mutation is committed.
- Audit records must include: actor ID, action type, resource type, resource ID, before state,
  after state, timestamp, rule version.
- The audit log must be append-only. No update or delete operations are permitted.

## FR-010: Supersession

- Published canon documents must be supersedeable by a formally governed process.
- Superseded documents must be archived and marked as superseded, not deleted.
- The supersession event must appear in the audit log.

## FR-011: Search

- Members must be able to search published governance records using full-text search.
- Search is provided by Meilisearch.
- Search must not expose records above the requesting member's clearance level.

## FR-012: Notifications

- The platform must send notifications for key lifecycle events.
- Notification preferences must be configurable per member.
- Notification delivery failures must not block governance state transitions.
