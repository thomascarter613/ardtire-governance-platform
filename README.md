# Ardtire Governance Platform

> A production-grade digital governance platform for the Ardtire Society, supporting membership
> governance, proposals, deliberation, voting, ratification, publication, and auditable institutional records.

[![CI](https://github.com/thomas-j-carter/ardtire-governance-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/thomas-j-carter/ardtire-governance-platform/actions/workflows/ci.yml)

---

## Overview

The Ardtire Governance Platform is the canonical institutional operating system for the Ardtire Society.
It provides formal governance workflows with complete auditability, rule-version binding, and
dual-register institutional boundary enforcement.

**Architecture:** Modular monolith with bounded contexts — Turborepo monorepo, TypeScript throughout.

## Documentation

| Document | Description |
|---|---|
| [Architecture Overview](docs/architecture/overview.md) | System architecture and key decisions |
| [Getting Started](docs/development/getting-started.md) | Local development setup |
| [Functional Requirements](docs/spec/functional-requirements.md) | What the platform does |
| [Coding Standards](docs/development/coding-standards.md) | How we write code |
| [Git Workflow](docs/development/git-workflow.md) | Branching and commit conventions |
| [Testing Strategy](docs/development/testing-strategy.md) | How we test |
| [Glossary](docs/domain/glossary.md) | Canonical domain terminology |
| [ADR Directory](docs/architecture/decisions/) | Architecture decision records |

## Quick Start

```bash
# Install runtime versions (Node 22, pnpm 10.6.2)
mise install

# Install dependencies
pnpm install

# Start local services
just compose-up

# Run migrations and seed
just db-migrate && just db-seed

# Start development servers
just dev
```

## Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 22 |
| Language | TypeScript 5.8 (strict) |
| Package manager | pnpm 10.6.2 |
| Monorepo | Turborepo 2.5.0 |
| Linting / Formatting | Biome 1.9.4 |
| Testing | Vitest 3.1.1, v8 coverage |
| Identity | Keycloak |
| Database | PostgreSQL 16 |
| Search | Meilisearch |
| Version management | mise |

## Maintainer

**Thomas J. Carter** ([@thomas-j-carter](https://github.com/thomas-j-carter))
thomas.carter@appliedinnovationcorp.com

## License

Proprietary. Copyright (c) 2026 Thomas J. Carter. All rights reserved. See [LICENSE](LICENSE).
