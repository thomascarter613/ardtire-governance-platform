set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default: list all available tasks
default:
  @just --list

# ── Dependencies ──────────────────────────────────────────────────────────────

# Install all dependencies
install:
  pnpm install

# Check for dependency version mismatches across workspaces
deps-check:
  pnpm syncpack list-mismatches

# Fix dependency version mismatches across workspaces
deps-fix:
  pnpm syncpack fix-mismatches

# ── Development ───────────────────────────────────────────────────────────────

# Start all apps in development mode
dev:
  pnpm turbo dev

# ── Build ─────────────────────────────────────────────────────────────────────

# Build all packages and apps
build:
  pnpm turbo build

# ── Code Quality ──────────────────────────────────────────────────────────────

# Run Biome linter
lint:
  pnpm biome lint .

# Run Biome formatter (writes changes)
format:
  pnpm biome format --write .

# Run TypeScript type checking across all packages
typecheck:
  pnpm turbo typecheck

# Umbrella: lint + typecheck + test
check:
  just lint
  just typecheck
  just test

# ── Testing ───────────────────────────────────────────────────────────────────

# Run all tests
test:
  pnpm turbo test

# Run tests in watch mode
test-watch:
  pnpm vitest watch

# Run tests with coverage report
coverage:
  pnpm vitest run --coverage

# ── Database ──────────────────────────────────────────────────────────────────

# Start only the database service
db-up:
  docker compose up postgres -d

# Stop the database service
db-down:
  docker compose stop postgres

# Drop and recreate the dev database, then migrate
db-reset:
  docker compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS ardtire_dev;"
  docker compose exec postgres psql -U postgres -c "CREATE DATABASE ardtire_dev;"
  just db-migrate

# Generate Prisma client
db-generate:
  pnpm turbo db:generate

# Run pending migrations
db-migrate:
  pnpm turbo db:migrate

# Seed the database with development data
db-seed:
  pnpm turbo db:seed

# ── Docker Compose ────────────────────────────────────────────────────────────

# Start all local services
compose-up:
  docker compose up -d

# Stop all local services
compose-down:
  docker compose down

# Stream logs from all services
compose-logs:
  docker compose logs -f

# ── TypeSpec (Schema-Driven API) ──────────────────────────────────────────────

# Compile TypeSpec definitions → generates docs/api/openapi.yaml
typespec-compile:
  pnpm tsp compile typespec/

# Validate TypeSpec without writing output (dry run)
typespec-validate:
  pnpm tsp compile typespec/ --no-emit

# Watch TypeSpec and recompile on changes
typespec-watch:
  pnpm tsp compile typespec/ --watch

# ── Policy as Code ────────────────────────────────────────────────────────────

# Run Checkov policy scan locally (requires checkov in PATH)
policy-check:
  checkov --config-file .checkov.yaml

# ── Contracts & Generation ────────────────────────────────────────────────────

# Generate API clients and types from OpenAPI spec (after typespec-compile)
contracts-generate:
  echo "contracts-generate: not yet implemented"

# Validate OpenAPI spec with Redocly
contracts-validate:
  npx @redocly/cli lint docs/api/openapi.yaml

# ── Documentation ─────────────────────────────────────────────────────────────

# Validate documentation structure
docs-validate:
  echo "docs-validate: not yet implemented"

# ── Scaffolding ───────────────────────────────────────────────────────────────

# Run Turborepo generators to scaffold new apps or packages
scaffold:
  pnpm turbo gen

# ── Maintenance ───────────────────────────────────────────────────────────────

# Remove all build artifacts, turbo cache, and coverage
clean:
  find . -name "dist" -not -path "*/node_modules/*" -exec rm -rf {} + 2>/dev/null || true
  find . -name ".turbo" -not -path "*/node_modules/*" -exec rm -rf {} + 2>/dev/null || true
  find . -name "coverage" -not -path "*/node_modules/*" -exec rm -rf {} + 2>/dev/null || true
  find . -name "*.tsbuildinfo" -not -path "*/node_modules/*" -delete 2>/dev/null || true
  echo "Clean complete."

# Verify toolchain versions and environment prerequisites
doctor:
  @echo "=== Ardtire Governance Platform — Environment Check ==="
  @echo "Node:           $(node --version)"
  @echo "pnpm:           $(pnpm --version)"
  @echo "Docker:         $(docker --version)"
  @echo "Docker Compose: $(docker compose version)"
  @echo "mise:           $(mise --version)"
  @echo "just:           $(just --version)"
  @echo "Checkov:        $(checkov --version 2>/dev/null || echo 'not installed')"
  @echo "TypeSpec:       $(pnpm tsp --version 2>/dev/null || echo 'not installed (run pnpm install)')"
  @echo "=== All checks passed ==="

# Run the full CI pipeline locally (including typespec and policy)
ci-local:
  just install
  just typespec-validate
  just check
  just policy-check
  just build

# Context
context-validate:
  node scripts/context/validate.mjs

context-inject:
  node scripts/context/inject.mjs

context-check: context-validate
  @echo "Context OK"


# Validate the context layer (same check that runs in CI and pre-push)
context-validate:
    node scripts/context/validate.mjs

# Generate a context bundle (manifest + state) → stdout
# Pipe to clipboard: just context-inject | pbcopy    (macOS)
#                    just context-inject | xclip -sel clip  (Linux)
context-inject:
    node scripts/context/inject.mjs

# Generate a full context bundle (all four context files) → stdout
context-inject-full:
    node scripts/context/inject.mjs --full

# Generate a context bundle and write to .context.md (gitignored)
context-bundle:
    node scripts/context/inject.mjs --full --output .context.md
    @echo "Bundle written to .context.md"

# Scaffold context/ files for a new project (idempotent — skips existing files)
context-scaffold:
    @echo "Scaffolding context/ layer..."
    @mkdir -p context
    @[ -f context/manifest.md ]     || cp scripts/context/templates/manifest.md     context/manifest.md
    @[ -f context/state.md ]        || cp scripts/context/templates/state.md        context/state.md
    @[ -f context/architecture.md ] || cp scripts/context/templates/architecture.md context/architecture.md
    @[ -f context/conventions.md ]  || cp scripts/context/templates/conventions.md  context/conventions.md
    @[ -f CLAUDE.md ]                  || cp scripts/context/templates/CLAUDE.md       CLAUDE.md
    @echo "Done. Fill in the placeholder values in context/manifest.md to begin."
