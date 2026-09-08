#!/usr/bin/env bash
# install.sh — set up the sandbox kit on any machine (macOS or Linux, or
# Windows via WSL2 / Git Bash). Idempotent: safe to run again.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"

echo ">> Checking prerequisites..."
command -v docker >/dev/null || { echo "!! Install Docker Desktop first: https://docker.com/products/docker-desktop"; exit 1; }
command -v git    >/dev/null || { echo "!! Install git first"; exit 1; }
docker info >/dev/null 2>&1 || echo "!! Docker is installed but not running — start Docker Desktop, then re-run."

chmod +x "$KIT/bin/saferepo" "$KIT/bin/sandbox"

# Add the kit's bin to PATH for both bash and zsh, once.
LINE="export PATH=\"$KIT/bin:\$PATH\""
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$RC" ] || touch "$RC"
  grep -qF "$KIT/bin" "$RC" || { echo "$LINE" >> "$RC"; echo ">> added to $RC"; }
done

echo ">> Pre-pulling scanner + sandbox images (one time)..."
docker pull aquasec/trivy@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969 >/dev/null 2>&1 || true
docker pull ghcr.io/datadog/guarddog@sha256:3dbc783f65f508b95222101cb2cd84d1d5f3e3675e42d6f1329bb9b8a99c8998 >/dev/null 2>&1 || true
docker pull node@sha256:8a34c4ab3ea2c5cd194f07e317b2a8f09461d3c8b05c4e34c8ccd56d56024c4d >/dev/null 2>&1 || true
docker pull nicolaka/netshoot@sha256:b09d9b21381f47a79b3cbcb30da25266dc17186ea00ae65e99fdc51396f48e70 >/dev/null 2>&1 || true

echo
echo ">> Done. Restart your terminal (or: source ~/.zshrc), then:"
echo "     saferepo add https://github.com/some/repo"
echo "     saferepo list"
