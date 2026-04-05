# Testing Strategy

## Philosophy

Tests exist to verify governance-critical behaviour and catch regressions.
Coverage is a lagging indicator, not a goal.

Priority:
1. Integration tests for governance workflows
2. Unit tests for pure business logic and utility functions
3. E2E tests for critical user-facing paths

## Test Pyramid

```
        ┌──────────────────┐
        │       E2E        │  Critical governance lifecycle paths
        ├──────────────────┤
        │   Integration    │  Governance workflows, API endpoints, DB operations
        ├──────────────────┤
        │      Unit        │  Pure functions, domain logic, utilities
        └──────────────────┘
```

## Tools

| Tool | Purpose |
|---|---|
| Vitest 3.1.1 | Test runner |
| v8 | Coverage provider |
| Supertest | HTTP integration testing |
| Docker Compose | Test service dependencies |

## Test File Conventions

| Type | Location | Naming |
|---|---|---|
| Unit | Adjacent to source file | `proposal-service.test.ts` |
| Integration | `test/integration/` | `proposal-workflow.integration.test.ts` |
| E2E | `test/e2e/` | `governance-lifecycle.e2e.test.ts` |

## Coverage Targets

| Category | Lines | Functions | Branches |
|---|---|---|---|
| Governance-critical modules | 90% | 90% | 85% |
| All other modules | 80% | 80% | 75% |

Coverage thresholds are enforced by Vitest. CI fails if thresholds are not met.

## What Must Be Tested

- Every governance state transition (happy path and all rejection paths)
- Every permission enforcement boundary
- All audit log emissions
- Vote eligibility computation
- Rule version binding
- Any function that reads or writes governance state

## Running Tests

```bash
just test          # run all tests
just test-watch    # watch mode
just coverage      # coverage report
```
