#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-${HOME}/.local/bin}"
if [[ -L "$TARGET_DIR/img-remix" && "$(readlink "$TARGET_DIR/img-remix")" == "$REPO_DIR/img-remix" ]]; then
  rm "$TARGET_DIR/img-remix"
  echo "Removed $TARGET_DIR/img-remix"
else
  echo "No launcher belonging to this clone at $TARGET_DIR/img-remix"
fi
