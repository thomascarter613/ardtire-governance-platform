# Repository Information

## Maintainer

**Thomas J. Carter** ([@thomascarter613](https://github.com/thomascarter613))
thomas.carter@appliedinnovationcorp.com

## Project

**ardtire-governance-platform** — Ardtire Digital Governance Platform

A production-grade digital governance platform for the Ardtire Society, supporting membership
governance, proposals, deliberation, voting, ratification, publication, and auditable institutional records.

## Architecture

Modular monolith with bounded contexts, deployed as a small set of cooperating apps within
a Turborepo monorepo.

## Repository Conventions

- All commits must follow the Conventional Commits specification
- All PRs must carry a Conventional Commit-formatted title
- Branch protection is enforced on `main`
- All changes require at least one review before merge
- The `CODEOWNERS` file defines required reviewers per path

## Useful Links

- [Contributing Guide](../CONTRIBUTING.md)
- [Security Policy](../SECURITY.md)
- [Code of Conduct](../CODE_OF_CONDUCT.md)
- [Architecture Overview](../docs/architecture/overview.md)
- [Getting Started](../docs/development/getting-started.md)
