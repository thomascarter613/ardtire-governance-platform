# Git Workflow

## Branch Strategy

Simplified trunk-based development.

| Branch | Purpose |
|---|---|
| `main` | Canonical trunk. Always deployable. Protected. |
| `feat/<scope>/<description>` | Feature branches |
| `fix/<scope>/<description>` | Bug fix branches |
| `chore/<scope>/<description>` | Maintenance, tooling, dependency updates |
| `docs/<scope>/<description>` | Documentation-only changes |

## Branch Protection

`main` is protected:
- Direct pushes are not permitted
- All changes require a pull request
- CI must pass before merge
- At least one review is required

## Commit Messages

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/).

```
type(scope): short imperative description

Optional longer body explaining WHY, not WHAT.

Optional footer: Closes #123
```

**Types:** `feat`, `fix`, `docs`, `chore`, `refactor`, `perf`, `test`, `ci`, `build`, `revert`

Commits are validated by Lefthook + commitlint on every commit.

## Pull Request Process

1. Create a branch from `main`
2. Make atomic, well-described commits
3. Push and open a PR with a Conventional Commit-formatted title
4. Ensure all CI checks pass
5. Self-review your diff before requesting merge
6. Squash merge into `main` with a clean commit message

## Release Process

Releases are managed by Changesets.

1. For any user-visible change, run `pnpm changeset` and commit the generated file
2. The release CI workflow automatically creates a Release PR when changesets accumulate
3. Merging the Release PR creates a GitHub Release

## Tagging

Tags follow SemVer: `v0.1.0`, `v1.0.0`, etc.
Tags are created automatically by the release workflow. Do not create tags manually.
