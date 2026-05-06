#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

GODOT_BIN=""
if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "ERROR: Godot executable not found. Install Godot or ensure 'godot' or 'godot4' is on PATH."
  exit 1
fi

echo "Running smoke tests with $GODOT_BIN..."
$GODOT_BIN --headless --path godot_project/war-market --script res://tests/smoke_test.gd

echo "Tests passed"
