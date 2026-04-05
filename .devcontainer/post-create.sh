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
