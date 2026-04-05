# Ubiquitous Language

This document defines the terms that must be used consistently across all code, tests,
API contracts, database schemas, and documentation. Listed synonyms are prohibited in
formal contexts — use only the canonical term.

## Canonical Terms

| Canonical Term | Prohibited Synonyms | Notes |
|---|---|---|
| `proposal` | ticket, request, item, motion | The formal governance submission entity |
| `deliberation` | discussion, debate, comment period | The structured pre-vote engagement period |
| `vote` | poll, ballot, survey | The formal decision-making event |
| `ratification` | approval, confirmation, sign-off | The formal authority step before publication |
| `publication` | release, posting, announcement | Committing to official canon |
| `member` | user, person, citizen | A registered Ardtire Society participant |
| `full_member` | full member, voting member | Member with voting rights |
| `associate_member` | associate, observer | Limited-rights member |
| `officer` | admin, moderator, manager | Appointed role-holder |
| `sovereign` | king, ruler, owner | Head of State |
| `standing` | status, state | Current membership participation status |
| `tier` | level, rank, grade | Membership tier (Associate, Full) |
| `rule_version` | policy version, rules version | Versioned constitutional ruleset |
| `audit_log` | activity log, history, changelog | The immutable governance audit record |
| `outcome` | result, decision, resolution | The binding result of a completed vote |
| `supersession` | replacement, update | The formal process of replacing a canon document |
| `canon` | official docs, published docs | The set of ratified official documents |

## Naming Conventions in Code

- Database table names: `snake_case`, plural (e.g. `proposals`, `audit_log_entries`)
- TypeScript types and interfaces: `PascalCase` (e.g. `Proposal`, `AuditLogEntry`)
- API endpoints: `kebab-case` (e.g. `/governance/proposals`, `/members/standing`)
- Event names: `SCREAMING_SNAKE_CASE` with domain prefix (e.g. `GOVERNANCE_PROPOSAL_SUBMITTED`)
- Enum values: `SCREAMING_SNAKE_CASE` (e.g. `FULL_MEMBER`, `UNDER_DELIBERATION`)
