#!/usr/bin/env bash
# install.sh — set up the sandbox kit on any machine (macOS or Linux, or
# Windows via WSL2 / Git Bash). Idempotent: safe to run again.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"

echo ">> Checking prerequisites..."
command -v docker >/dev/null || { echo "!! Install Docker Desktop first: https://docker.com/products/docker-desktop"; exit 1; }
command -v git    >/dev/null || { echo "!! Install git first"; exit 1; }
docker info >/dev/null 2>&1 || echo "!! Docker is installed but not running — start Docker Desktop, then re-run."

chmod +x "$KIT/bin/vet" "$KIT/bin/sandbox"

# Add the kit's bin to PATH for both bash and zsh, once.
LINE="export PATH=\"$KIT/bin:\$PATH\""
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$RC" ] || touch "$RC"
  grep -qF "$KIT/bin" "$RC" || { echo "$LINE" >> "$RC"; echo ">> added to $RC"; }
done

echo ">> Pre-pulling scanner + sandbox images (one time)..."
docker pull aquasec/trivy:latest         >/dev/null 2>&1 || true
docker pull ghcr.io/datadog/guarddog:latest >/dev/null 2>&1 || true
docker pull node:22-bookworm             >/dev/null 2>&1 || true
docker pull nicolaka/netshoot            >/dev/null 2>&1 || true

echo
echo ">> Done. Restart your terminal (or: source ~/.zshrc), then:"
echo "     vet https://github.com/some/repo"
echo "     sandbox /tmp/vet.XXXX/repo --no-net"
