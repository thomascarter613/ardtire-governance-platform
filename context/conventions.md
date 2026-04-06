# Conventions

> Naming patterns, structural rules, and code-style rationale.
> Written for AI consumers — be explicit; do not assume shared knowledge.
> Update when conventions change. Prefer adding over deleting old entries.

---

## Commit Convention

Conventional Commits enforced via commitlint.
Format: `type(scope): description`

Types: `feat` `fix` `docs` `refactor` `test` `chore` `ci` `perf` `build`

Scopes mirror the monorepo structure:
```
feat(gov-api): ...
feat(web): ...
fix(packages/observability): ...
docs(context): ...
ci(github): ...
```

Breaking changes: append `!` after scope — `feat(gov-api)!: ...`

---

## File & Directory Naming

- Directories: `kebab-case`
- TypeScript source files: `kebab-case.ts`
- React/SolidJS components: `PascalCase.tsx`
- Test files: co-located, suffix `.test.ts` or `.test.tsx`
- Config files: follow the tool's convention (do not rename)

---

## TypeScript

- Strict mode (`strict: true`) everywhere — no exceptions
- Prefer `type` over `interface` for data shapes; `interface` for extension points
- No `any` — use `unknown` and narrow; or `// biome-ignore` with justification
- Imports: named exports preferred; default exports only for framework requirements (e.g. Solid components, Payload config)
- Path aliases: `@repo/*` maps to `packages/*`; `@/*` maps to the consuming app's `src/`

---

## API Design

<!-- Fill in as the API takes shape -->

- REST resource naming: plural nouns, kebab-case (`/governance-sessions`, not `/governanceSessions`)
- Error shape: `{ error: { code: string, message: string, details?: unknown } }`
- Auth: all non-public endpoints expect `Authorization: Bearer <jwt>` header
- Versioning strategy: <!-- URI prefix `/v1/` | header-based | none yet -->

---

## Monorepo Rules

- Each `apps/*` app owns its own `tsconfig.json` extending `@ardtire/tsconfig/base`
- No cross-app imports — apps communicate via API only
- Shared code lives in `packages/*` — if two apps need it, it becomes a package
- `tooling/*` contains zero runtime code — build/lint/test config only
- `scripts/*` are repo-maintenance scripts — not imported by any app or package

---

## Linting & Formatting

- Biome is the single tool for linting and formatting (replaces ESLint + Prettier for TS/JS)
- ESLint config in `tooling/eslint-config` is retained for legacy/config-specific cases only
- Do not add Prettier — it conflicts with Biome's formatter
- Lefthook runs Biome on pre-commit; CI runs `pnpm biome check`

---

## Testing

- Test framework: Vitest (shared config via `tooling/vitest-config`)
- Unit tests: co-located with source
- Integration tests: `src/__tests__/` or `test/` at app root, clearly named
- No test should reach a real database or external service without explicit `--integration` flag
- Test naming: `describe("ModuleName", () => { it("does X when Y", ...) })`

---

## Environment Variables

- All env vars declared in `.env.example` at repo root and app root (where applicable)
- Runtime env vars validated at startup with a schema — not scattered raw `process.env` reads
- Secrets never committed; use Fly.io secrets / GitHub Actions secrets in CI

---

## Documentation

- User-facing docs: Diátaxis structure under `docs/` (tutorials / how-to / reference / explanation)
- Architecture decisions: ADR in `docs/architecture/decisions/`; one decision per file
- In-code comments: explain *why*, not *what* — the code shows what
- JSDoc on all exported public API surface in packages
