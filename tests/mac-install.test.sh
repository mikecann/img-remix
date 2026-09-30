#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/img-remix-install.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
BIN_DIR="$TEST_DIR/bin with spaces"
bash "$REPO_DIR/install.sh" "$BIN_DIR"
bash "$REPO_DIR/install.sh" "$BIN_DIR"
[[ "$(readlink "$BIN_DIR/img-remix")" == "$REPO_DIR/img-remix" ]]
# Exercise the installed symlink from outside the clone. Invalid flags prevent API calls.
if (cd "$TEST_DIR" && OPENROUTER_API_KEY=offline-test-key "$BIN_DIR/img-remix" --variations 0 > "$TEST_DIR/output" 2>&1); then
  echo 'CLI unexpectedly accepted invalid variations' >&2
  exit 1
fi
python3 - "$TEST_DIR/output" <<'PY'
from pathlib import Path
import sys
assert '--variations must be 1, 2, 3, or 4' in Path(sys.argv[1]).read_text()
PY
bash "$REPO_DIR/uninstall.sh" "$BIN_DIR"
bash "$REPO_DIR/uninstall.sh" "$BIN_DIR"
[[ ! -L "$BIN_DIR/img-remix" ]]
printf 'unrelated command\n' > "$BIN_DIR/img-remix"
if bash "$REPO_DIR/install.sh" "$BIN_DIR" > "$TEST_DIR/refusal" 2>&1; then
  echo 'Installer overwrote an unrelated command' >&2
  exit 1
fi
bash "$REPO_DIR/uninstall.sh" "$BIN_DIR"
[[ "$(cat "$BIN_DIR/img-remix")" == 'unrelated command' ]]
echo 'macOS installer smoke checks passed.'
