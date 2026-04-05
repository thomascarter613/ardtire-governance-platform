# Contributing

## Who Can Contribute

The Ardtire Governance Platform is a proprietary institutional platform.
Contributions are currently limited to authorised collaborators.
Contact the maintainer if you believe you should have access.

## Before You Write Any Code

1. Read the [Architecture Overview](docs/architecture/overview.md).
2. Read the [Functional Requirements](docs/spec/functional-requirements.md).
3. Read the [Coding Standards](docs/development/coding-standards.md).
4. Follow the [Getting Started](docs/development/getting-started.md) guide completely.

## Process

1. **Check for an existing issue** — do not start work without a corresponding issue.
2. **Discuss before building** — comment on the issue before beginning significant work.
3. **Branch from `main`** — follow the [Git Workflow](docs/development/git-workflow.md).
4. **Write tests** — follow the [Testing Strategy](docs/development/testing-strategy.md).
5. **Open a Pull Request** — use the PR template. Ensure CI passes.
6. **Request review** — @thomascarter613 reviews all PRs.

## Architecture Decisions

Any significant architectural decision requires an ADR before implementation.
Copy `docs/architecture/decisions/ADR-000-template.md`, assign the next sequential number,
and open a PR for review before beginning implementation.

## Commit Messages

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/).
See `commitlint.config.ts` for valid types and scopes.
Commits are validated on pre-commit by Lefthook.

## Questions

Contact: thomas.carter@appliedinnovationcorp.com
