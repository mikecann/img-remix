#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
WITH_BUN_INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --with-bun-install|-B) WITH_BUN_INSTALL=1 ;;
    -h|--help) echo 'Usage: install.sh [target_bin_dir] [--with-bun-install|-B]'; exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done
if [[ "$WITH_BUN_INSTALL" -eq 1 ]]; then
  command -v bun >/dev/null 2>&1 || { echo 'Install Bun first: https://bun.sh' >&2; exit 1; }
  (cd "$REPO_DIR" && bun install --frozen-lockfile)
fi
mkdir -p "$TARGET_DIR"
# Refuse to replace an unrelated command. Re-running against our own link is fine.
if [[ -e "$TARGET_DIR/img-remix" || -L "$TARGET_DIR/img-remix" ]]; then
  if [[ ! -L "$TARGET_DIR/img-remix" || "$(readlink "$TARGET_DIR/img-remix")" != "$REPO_DIR/img-remix" ]]; then
    echo "Already exists: $TARGET_DIR/img-remix. Move it before installing." >&2
    exit 1
  fi
fi
chmod +x "$REPO_DIR/img-remix"
ln -sf "$REPO_DIR/img-remix" "$TARGET_DIR/img-remix"
echo "Installed $TARGET_DIR/img-remix"
echo "Make sure $TARGET_DIR is on PATH. Set OPENROUTER_API_KEY in $REPO_DIR/.env."
