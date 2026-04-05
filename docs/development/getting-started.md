# Getting Started

## Prerequisites

- **mise** — runtime version manager. Install: `brew install mise` or see https://mise.jdx.dev
- **Docker** and **Docker Compose** — for local service dependencies
- **just** — task runner. Install: `brew install just`
- **Git** with SSH configured for GitHub

## Initial Setup

### 1. Clone the Repository

```bash
git clone git@github.com:thomas-j-carter/ardtire-governance-platform.git
cd ardtire-governance-platform
```

### 2. Install Runtime Versions

```bash
mise install
```

Verify:

```bash
node --version   # 22.x
pnpm --version   # 10.6.2
```

### 3. Install Dependencies

```bash
pnpm install
```

### 4. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and fill in any required values. See `.env.example` comments for guidance.

### 5. Start Local Services

```bash
just compose-up
```

This starts PostgreSQL, Keycloak, Meilisearch, and Mailpit. Wait for all services to report healthy:

```bash
docker compose ps
```

### 6. Run Database Migrations

```bash
just db-migrate
```

### 7. Seed Development Data

```bash
just db-seed
```

### 8. Start Development Servers

```bash
just dev
```

## Verifying Your Setup

| Service | URL |
|---|---|
| API health | http://localhost:3001/health |
| Keycloak admin | http://localhost:8080 (admin / admin) |
| Mailpit | http://localhost:8025 |
| Meilisearch | http://localhost:7700 |

## Common Tasks

```bash
just --list        # all available tasks
just check         # lint + typecheck + test
just coverage      # test with coverage report
just doctor        # verify toolchain versions
```

## Troubleshooting

**`mise install` fails** — Verify mise is installed and your shell is configured per https://mise.jdx.dev.

**Docker services fail to start** — Ensure Docker is running and ports 5432, 8080, 7700, 8025, 1025 are free.

**`pnpm install` fails** — Ensure you are using pnpm 10.6.2 via mise, not a globally installed version.
