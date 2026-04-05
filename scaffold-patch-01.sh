#!/usr/bin/env bash
# =============================================================================
# scaffold-patch-01.sh
# Targeted fixes for the 6 issues identified in code review.
# Run from inside ardtire-governance-platform/ after scaffold-addendum.sh.
# Idempotent — safe to re-run.
# =============================================================================
set -euo pipefail

if [[ ! -f "tsp-config.yaml" ]] || [[ ! -d "typespec" ]]; then
  echo "ERROR: Run this script from inside ardtire-governance-platform/" >&2
  exit 1
fi

echo "==> Applying patch 01: TypeSpec @info decorator + @typespec/openapi import"
echo "==> Applying patch 02: devcontainer feature version pins"
echo "==> Applying patch 03: post-create.sh PATH timing"
echo "==> Applying patch 04: hono peerDependency in observability package"
echo "==> Applying patch 05: Checkov severity config key names"
echo "==> Applying patch 06: checkov-action and @redocly/cli version pins"
echo ""

# =============================================================================
# PATCH 01 — TypeSpec
#
# Root cause: @info is not auto-imported. It lives in @typespec/openapi,
# which must be explicitly imported and used. Without this, tsp compile fails
# with "unknown decorator @info".
#
# Secondary: @useAuth(NoAuth) is valid when NoAuth is in scope via
# `using TypeSpec.Http`, but `@useAuth([])` is the more explicit and
# idiomatic form for public-endpoint auth overrides.
# =============================================================================

# ── typespec/main.tsp ──────────────────────────────────────────────────────
cat > typespec/main.tsp << 'EOF'
/**
 * Ardtire Governance API — TypeSpec root.
 *
 * This file is the TypeSpec compiler entry point.
 * Running `tsp compile typespec/` regenerates docs/api/openapi.yaml.
 *
 * DO NOT manually edit docs/api/openapi.yaml — it is a generated artifact.
 * All API changes must originate here as TypeSpec definitions.
 *
 * Compile:  pnpm typespec:compile
 * Watch:    pnpm typespec:watch
 * Validate: pnpm typespec:validate
 */
import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi";    // Required: provides @info decorator
import "@typespec/openapi3";   // Required: provides the OpenAPI 3.x emitter

import "./common.tsp";
import "./health.tsp";
import "./members.tsp";
import "./governance.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using TypeSpec.OpenAPI;       // Brings @info into scope

/**
 * The Ardtire Governance API.
 *
 * The canonical governance API for the Ardtire Society. This API is the single
 * authoritative source of truth for all governance state. All governance outcomes,
 * membership records, and audit events originate here.
 *
 * When this API and any other system disagree on governance state, this API is correct.
 */
@service({ title: "Ardtire Governance API" })
@info({
  version: "0.1.0",
  contact: {
    name: "Thomas J. Carter",
    email: "thomas.carter@appliedinnovationcorp.com",
    url: "https://www.ardtiresociety.org",
  },
  license: {
    name: "Proprietary",
  },
})
@server("https://api.ardtiresociety.org", "Production")
@server("https://staging-api.ardtiresociety.org", "Staging")
@server("http://localhost:3001", "Local development")
@useAuth(BearerAuth)
namespace ArdtireGovernanceApi;
EOF

# ── typespec/health.tsp ────────────────────────────────────────────────────
# Change @useAuth(NoAuth) → @useAuth([]).
# Both are valid when TypeSpec.Http is in scope, but the empty-array form is
# the canonical way to say "this operation explicitly requires no authentication"
# and is unambiguous regardless of what is or isn't in the enclosing using scope.
cat > typespec/health.tsp << 'EOF'
import "@typespec/http";
import "@typespec/rest";

using TypeSpec.Http;
using TypeSpec.Rest;

namespace Ardtire.Health;

enum ServiceStatus {
  ok,
  degraded,
  unhealthy,
}

model HealthResponse {
  status: ServiceStatus;
  timestamp: utcDateTime;
  version: string;
  services?: Record<ServiceStatus>;
}

@route("/health")
@tag("health")
interface HealthEndpoints {
  /**
   * Liveness check. Returns 200 if the process is running.
   * Does not check downstream dependencies.
   * Public endpoint — no authentication required.
   */
  @get
  @summary("Liveness check")
  @useAuth([])
  liveness(): {
    @statusCode statusCode: 200;
    @body body: HealthResponse;
  };

  /**
   * Readiness check. Returns 200 only when all dependencies are healthy.
   * Used by load balancers and orchestrators to gate traffic.
   * Public endpoint — no authentication required.
   */
  @get
  @route("ready")
  @summary("Readiness check")
  @useAuth([])
  readiness():
    | {
        @statusCode statusCode: 200;
        @body body: HealthResponse;
      }
    | {
        @statusCode statusCode: 503;
        @body body: HealthResponse;
      };
}
EOF

# ── package.json (root) — add @typespec/openapi ────────────────────────────
# @typespec/openapi must be the same version as the other typespec/* packages.
# We update only the devDependencies block; all other content is preserved.
node - << 'JSEOF'
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
pkg.devDependencies["@typespec/openapi"] = "0.63.0";
// Re-sort devDependencies alphabetically for consistency
pkg.devDependencies = Object.fromEntries(
  Object.entries(pkg.devDependencies).sort(([a], [b]) => a.localeCompare(b))
);
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
console.log("  package.json: added @typespec/openapi@0.63.0");
JSEOF

# =============================================================================
# PATCH 02 — devcontainer feature version pins
#
# Root cause: `"feature:1"` is a floating major-version reference. A new
# minor or patch release of the feature can silently change the container
# environment. Specific version tags (or SHA digests) are required for
# true reproducibility.
#
# Note on SHA digests: SHA pinning (`feature@sha256:...`) is the gold
# standard for security-critical contexts because version tags can
# theoretically be moved, though ghcr.io feature version tags are
# content-addressed in practice. If your threat model requires SHA pinning,
# retrieve the digest for each feature from:
#   ghcr.io/devcontainers/features/docker-outside-docker
#   ghcr.io/devcontainers/features/github-cli
# and substitute here. Renovate will keep version tags current automatically.
# =============================================================================
cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "Ardtire Governance Platform",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-docker:1.6.1": {
      "moby": true,
      "dockerDashComposeVersion": "v2"
    },
    "ghcr.io/devcontainers/features/github-cli:1.0.6": {}
  },
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "postStartCommand": "mise install",
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached,readonly"
  ],
  "remoteUser": "vscode",
  "remoteEnv": {
    "NODE_ENV": "development"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "biomejs.biome",
        "EditorConfig.EditorConfig",
        "eamodio.gitlens",
        "github.vscode-github-actions",
        "github.vscode-pull-request-github",
        "ms-azuretools.vscode-docker",
        "ms-vscode.vscode-typescript-next",
        "redhat.vscode-yaml",
        "streetsidesoftware.code-spell-checker",
        "vitest.explorer",
        "yoavbls.pretty-ts-errors",
        "mikestead.dotenv",
        "Prisma.prisma",
        "tamasfe.even-better-toml",
        "ms-vscode.azure-account",
        "mindaro.mindaro"
      ],
      "settings": {
        "editor.defaultFormatter": "biomejs.biome",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "quickfix.biome": "explicit",
          "source.organizeImports.biome": "explicit"
        },
        "typescript.tsdk": "node_modules/typescript/lib",
        "typescript.enablePromptUseWorkspaceTsdk": true,
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  },
  "forwardPorts": [3001, 5432, 7700, 8025, 8080],
  "portsAttributes": {
    "3001": { "label": "Governance API", "onAutoForward": "notify" },
    "5432": { "label": "PostgreSQL", "onAutoForward": "silent" },
    "7700": { "label": "Meilisearch", "onAutoForward": "silent" },
    "8025": { "label": "Mailpit UI", "onAutoForward": "notify" },
    "8080": { "label": "Keycloak", "onAutoForward": "notify" }
  }
}
EOF

# =============================================================================
# PATCH 03 — post-create.sh PATH timing
#
# Root cause: The original script appended mise activation to .bashrc and then
# immediately called `mise install` and `pnpm install` in the same process.
# .bashrc is only sourced by interactive login shells — it has no effect on
# the current script execution. As a result, the mise shim directory was never
# on PATH when those commands ran, causing a "command not found" failure on a
# cold container build.
#
# Fix: After installing mise, explicitly export PATH and eval the activation
# expression within the current shell session. .bashrc is still updated for
# interactive terminal sessions, but the script no longer depends on it.
# =============================================================================
cat > .devcontainer/post-create.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [devcontainer] Starting post-create setup..."

# ── System packages ───────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  curl \
  git \
  gnupg \
  jq \
  postgresql-client \
  unzip \
  wget \
  ca-certificates

# ── mise ──────────────────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing mise..."
curl -sSf https://mise.run | sh

# Make mise available to THIS script session immediately.
# Do not rely on .bashrc being sourced — it only applies to interactive shells.
export PATH="$HOME/.local/bin:$PATH"
eval "$("$HOME/.local/bin/mise" activate bash)"

# Also configure .bashrc for interactive terminal sessions inside the container.
if ! grep -q 'mise activate' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo 'eval "$(mise activate bash)"' >> "$HOME/.bashrc"
fi

# Verify mise is callable before proceeding.
mise --version

# ── just ──────────────────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing just..."
curl --proto '=https' --tlsv1.2 -sSf \
  https://just.systems/install.sh | bash -s -- --to /usr/local/bin
chmod +x /usr/local/bin/just

# ── Checkov ───────────────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing Checkov..."
sudo pip3 install checkov --break-system-packages 2>/dev/null || \
  pip3 install --user checkov

# ── Runtime via mise ─────────────────────────────────────────────────────────
# mise activate has already run above, so `node` and `pnpm` will be on PATH
# after `mise install` completes.
echo "==> [devcontainer] Installing Node + pnpm via mise..."
mise install

# Verify the runtimes are callable before using them.
echo "  node: $(node --version)"
echo "  pnpm: $(pnpm --version)"

# ── Workspace dependencies ───────────────────────────────────────────────────
echo "==> [devcontainer] Installing pnpm workspace dependencies..."
pnpm install

# ── Copy env example ─────────────────────────────────────────────────────────
if [[ ! -f ".env" ]]; then
  cp .env.example .env
  echo "==> [devcontainer] .env created from .env.example — review and fill in values."
fi

echo ""
echo "==> [devcontainer] Setup complete."
echo "    Run 'just doctor' to verify your environment."
echo "    Run 'just compose-up && just db-migrate && just db-seed' to start local services."
EOF
chmod +x .devcontainer/post-create.sh

# =============================================================================
# PATCH 04 — hono peerDependency in packages/observability
#
# Root cause: packages/observability/src/middleware/hono.ts imports Hono
# types and concepts, but hono was not declared as a peerDependency. Any
# package consuming @ardtire/observability/middleware/hono will fail at
# runtime if hono is not already installed, with no install-time warning.
#
# Fix: Declare hono as an optional peerDependency (optional because the core
# tracer, metrics, and logger exports have zero dependency on Hono — only the
# middleware subpath does) and add it as a devDependency for local testing.
# =============================================================================
node - << 'JSEOF'
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("packages/observability/package.json", "utf8"));

pkg.peerDependencies = {
  "hono": ">=4.0.0"
};

pkg.peerDependenciesMeta = {
  "hono": {
    "optional": true
  }
};

// Add hono as a devDependency for tests and local type resolution.
pkg.devDependencies = pkg.devDependencies ?? {};
pkg.devDependencies["hono"] = "4.7.5";

// Re-sort both blocks alphabetically.
pkg.peerDependencies = Object.fromEntries(
  Object.entries(pkg.peerDependencies).sort(([a], [b]) => a.localeCompare(b))
);
pkg.devDependencies = Object.fromEntries(
  Object.entries(pkg.devDependencies).sort(([a], [b]) => a.localeCompare(b))
);

fs.writeFileSync(
  "packages/observability/package.json",
  JSON.stringify(pkg, null, 2) + "\n"
);
console.log("  packages/observability/package.json: added hono peerDependency + devDependency");
JSEOF

# =============================================================================
# PATCH 05 — Checkov severity config key names
#
# Root cause: `soft-fail-on` and `hard-fail-on` in .checkov.yaml accept
# lists of CHECK IDs (e.g. CKV_AWS_1), not severity level strings. The
# severity-based equivalents are `soft-fail-on-severity` and
# `hard-fail-on-severity`. Using severity strings under the wrong keys is
# silently ignored, meaning ALL failures were effectively treated as hard
# fails regardless of severity.
# =============================================================================
cat > .checkov.yaml << 'EOF'
# Checkov policy-as-code configuration.
# https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html

# Scan these directories and files for IaC misconfigurations.
directory:
  - infra
  - .github/workflows

file:
  - docker-compose.yml

# Output formats
output:
  - cli
  - json

# Severity thresholds.
# `soft-fail-on-severity` → report but exit 0 (warning only).
# `hard-fail-on-severity` → report and exit 1 (pipeline fails).
# These keys accept severity level strings: INFO | LOW | MEDIUM | HIGH | CRITICAL
soft-fail-on-severity:
  - LOW
  - MEDIUM

hard-fail-on-severity:
  - HIGH
  - CRITICAL

# Suppress known false-positives with documented justifications.
# Format: list of check IDs. Each suppression must have a comment explaining why.
skip-check:
  # docker-compose.yml: Keycloak runs dev-mem and start-dev — TLS is terminated
  # at the host/reverse-proxy layer in all non-local environments.
  - CKV_DOCKER_2
  # docker-compose.yml: KEYCLOAK_ADMIN_PASSWORD is a local-development default
  # only. Production secrets are injected via environment variables, never committed.
  - CKV_SECRET_6
  # .github/workflows: Third-party action SHA pinning is tracked and updated
  # automatically by Renovate. Checkov's check is redundant given that control.
  - CKV_GH_1

# Compact output for CI log readability.
compact: true
EOF

# =============================================================================
# PATCH 06a — Pin checkov-action to a specific release tag
#
# Root cause: `bridgecrewio/checkov-action@master` is a floating reference.
# For a security-scanning tool in particular, a supply-chain compromise of
# the action's master branch would run attacker code with contents: read and
# security-events: write permissions. Pinning to a specific release tag
# (or ideally a commit SHA) eliminates this vector.
#
# Note: For maximum supply-chain security, replace the version tag with a
# full commit SHA (e.g. @abc123def...). Renovate will keep the tag current.
# =============================================================================
cat > .github/workflows/infra-policy.yml << 'EOF'
name: Infrastructure Policy

on:
  push:
    branches: [main]
    paths:
      - "infra/**"
      - "docker-compose.yml"
      - ".checkov.yaml"
      - ".github/workflows/**"
  pull_request:
    branches: [main]
    paths:
      - "infra/**"
      - "docker-compose.yml"
      - ".checkov.yaml"
      - ".github/workflows/**"
  schedule:
    # Run weekly even without changes to catch newly released checks.
    - cron: "0 7 * * 1"
  workflow_dispatch:

jobs:
  checkov:
    name: Checkov Policy Scan
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4

      - name: Run Checkov
        # Pinned to a specific release tag. Update via Renovate or manually.
        # To harden further, replace this tag with a full commit SHA.
        uses: bridgecrewio/checkov-action@v12.2950.0
        with:
          config_file: .checkov.yaml
          output_format: cli,sarif
          output_file_path: console,checkov-results.sarif
          download_external_modules: false

      - name: Upload SARIF to GitHub Security tab
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: checkov-results.sarif
          category: checkov
EOF

# =============================================================================
# PATCH 06b — Pin @redocly/cli to a specific version
#
# Root cause: `npx --yes @redocly/cli lint` pulls whatever @redocly/cli
# version is current at CI run time. This makes the validation non-deterministic
# — a new Redocly version can start failing specs that previously passed,
# with no change to the spec itself. Pinning ties the validation to a known-good
# version; Renovate handles upgrades through a deliberate PR.
# =============================================================================
cat > .github/workflows/typespec.yml << 'EOF'
name: TypeSpec

on:
  push:
    branches: [main]
    paths:
      - "typespec/**"
      - "tsp-config.yaml"
      - "docs/api/openapi.yaml"
  pull_request:
    branches: [main]
    paths:
      - "typespec/**"
      - "tsp-config.yaml"
      - "docs/api/openapi.yaml"

jobs:
  compile:
    name: Compile and Validate TypeSpec
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 10.6.2
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile

      - name: Compile TypeSpec
        run: pnpm typespec:compile

      - name: Assert openapi.yaml was not modified uncommitted
        run: |
          if ! git diff --quiet docs/api/openapi.yaml; then
            echo ""
            echo "ERROR: docs/api/openapi.yaml is out of sync with the TypeSpec source."
            echo "Run 'pnpm typespec:compile' locally and commit the result."
            echo ""
            git diff docs/api/openapi.yaml
            exit 1
          fi

      - name: Validate generated OpenAPI with Redocly
        # Pinned to a specific version. Renovate will keep this current.
        run: npx @redocly/cli@1.25.0 lint docs/api/openapi.yaml
EOF

echo ""
echo "============================================================"
echo "  scaffold-patch-01.sh complete."
echo "============================================================"
echo ""
echo "Summary of changes:"
echo ""
echo "  typespec/main.tsp"
echo "    + import \"@typespec/openapi\""
echo "    + using TypeSpec.OpenAPI"
echo "    ~ @info() now resolves correctly"
echo ""
echo "  typespec/health.tsp"
echo "    ~ @useAuth(NoAuth) → @useAuth([])"
echo ""
echo "  package.json"
echo "    + @typespec/openapi@0.63.0"
echo ""
echo "  .devcontainer/devcontainer.json"
echo "    ~ docker-outside-docker:1 → 1.6.1"
echo "    ~ github-cli:1 → 1.0.6"
echo ""
echo "  .devcontainer/post-create.sh"
echo "    ~ PATH now set via explicit export + eval within script session"
echo "    ~ .bashrc still updated for interactive terminals"
echo "    + node/pnpm version verification before pnpm install"
echo ""
echo "  packages/observability/package.json"
echo "    + peerDependencies: { hono: '>=4.0.0' }"
echo "    + peerDependenciesMeta: { hono: { optional: true } }"
echo "    + devDependencies: { hono: '4.7.5' }"
echo ""
echo "  .checkov.yaml"
echo "    ~ soft-fail-on → soft-fail-on-severity"
echo "    ~ hard-fail-on → hard-fail-on-severity"
echo ""
echo "  .github/workflows/infra-policy.yml"
echo "    ~ checkov-action@master → @v12.2950.0"
echo ""
echo "  .github/workflows/typespec.yml"
echo "    ~ @redocly/cli (unpinned) → @redocly/cli@1.25.0"
echo ""
echo "Next: pnpm install  (picks up @typespec/openapi and hono devDep)"
EOF
