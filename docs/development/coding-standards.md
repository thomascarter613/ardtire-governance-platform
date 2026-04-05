# Coding Standards

## Language

All application code is TypeScript. JavaScript is permitted only in tooling shims that explicitly
cannot use TypeScript.

## Formatting and Linting

All formatting and linting is handled by **Biome 1.9.4**. No ESLint. No Prettier.

```bash
just lint      # lint only
just format    # format and fix
just check     # lint + typecheck + test
```

Biome configuration is in `biome.json` at the repository root.

## TypeScript

- `strict: true` is required. No exceptions.
- `exactOptionalPropertyTypes: true` — do not use `| undefined` to circumvent this.
- `noUncheckedIndexedAccess: true` — always guard array and record access.
- `verbatimModuleSyntax: true` — use `import type` for type-only imports.
- No `any`. Use `unknown` and narrow explicitly.
- No non-null assertion (`!`) except in test factories with a documented justification.

## Naming Conventions

Refer to [Ubiquitous Language](../domain/ubiquitous-language.md) for all domain terms.

| Construct | Convention | Example |
|---|---|---|
| Files | `kebab-case.ts` | `proposal-service.ts` |
| Classes | `PascalCase` | `ProposalService` |
| Interfaces | `PascalCase` | `ProposalRepository` |
| Types | `PascalCase` | `CreateProposalInput` |
| Functions | `camelCase` | `submitProposal` |
| Variables | `camelCase` | `activeRuleVersion` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_DELIBERATION_DAYS` |
| Enum values | `SCREAMING_SNAKE_CASE` | `UNDER_DELIBERATION` |
| DB tables | `snake_case`, plural | `proposals` |
| DB columns | `snake_case` | `submitted_at` |
| API paths | `kebab-case` | `/governance/proposals` |
| Event names | `DOMAIN_ENTITY_ACTION` | `GOVERNANCE_PROPOSAL_SUBMITTED` |

## Module Structure

- Each bounded context owns its own directory.
- No cross-context database joins. Access foreign context data through its public interface or events.
- Circular dependencies between packages are a build error.

## Error Handling

- Never swallow errors silently.
- Use typed error classes, not string-based error codes at boundaries.
- All unhandled promise rejections must be caught and logged.
- API errors must return a structured `Error` response per the OpenAPI schema.

## Commit Messages

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/).
Enforced by Lefthook + commitlint on every commit.

Format: `type(scope): description`
Example: `feat(governance): add proposal submission endpoint`

Valid types and scopes are enumerated in `commitlint.config.ts`.
