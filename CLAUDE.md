# Claude Context

> Automatically read by Claude Projects at session start.
> This file is intentionally thin — it is a pointer map, not content.

## Session Startup Order

Read these in sequence before doing anything else:

1. [`context/manifest.md`](./context/manifest.md) — identity, stack, invariants
2. [`context/state.md`](./context/state.md) — current phase, active slice, blockers

If doing architecture or cross-cutting work, also read:

3. [`context/architecture.md`](./context/architecture.md)
4. [`context/conventions.md`](./context/conventions.md)

## Reference Locations

| Topic                    | Location |
|--------------------------|----------|
| Architectural decisions  | `docs/architecture/decisions/` |
| System context + diagrams| `docs/architecture/` |
| Domain language / glossary | `docs/domain/` |
| API specification        | `docs/api/openapi.yaml` + `typespec/` |
| Functional requirements  | `docs/spec/functional-requirements.md` |
| Coding standards         | `docs/development/coding-standards.md` |
| Git workflow              | `docs/development/git-workflow.md` |
| Observability package    | `packages/observability/` |

## Context Bundle

To generate a copyable context bundle for pasting into a Claude Project or another AI tool:

```bash
just context-inject          # manifest + state → stdout
just context-inject-full     # all four context files → stdout
node scripts/context/inject.mjs --output .context.md   # write to file
```

## Rules for This Session

- Do not modify `context/manifest.md` unless explicitly asked
- `context/state.md` **should** be updated at session end to reflect what was done
- All new architectural decisions must have an ADR in `docs/architecture/decisions/`
- Follow the conventions in `context/conventions.md` — do not invent new patterns
