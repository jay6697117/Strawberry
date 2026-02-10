#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

find_godot_bin() {
  if command -v godot >/dev/null 2>&1; then
    echo "godot"
    return 0
  fi

  if command -v godot4 >/dev/null 2>&1; then
    echo "godot4"
    return 0
  fi

  return 1
}

GODOT_BIN="$(find_godot_bin || true)"

if [[ -z "$GODOT_BIN" ]]; then
  echo "Error: Godot executable not found (expected 'godot' or 'godot4' in PATH)."
  exit 1
fi

MODE="${1:-run}"

ensure_imported() {
  local cache_file="$ROOT_DIR/.godot/global_script_class_cache.cfg"
  if [[ -f "$cache_file" ]]; then
    return 0
  fi

  "$GODOT_BIN" --headless --import --path "$ROOT_DIR"
}

if [[ "$MODE" == "run" ]]; then
  exec "$GODOT_BIN" --path "$ROOT_DIR"
fi

if [[ "$MODE" == "test" ]]; then
  ensure_imported
  exec "$GODOT_BIN" --headless -d -s --path "$ROOT_DIR" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gdir=res://test/integration -ginclude_subdirs -gexit
fi

echo "Usage: ./start.sh [run|test]"
exit 2
