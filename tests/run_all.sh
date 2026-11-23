#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
echo "== The Long Note — full test suite =="
python3 tests/validate_content.py
echo "\n-- logic and save tests --"
godot --headless --path "$ROOT/game" res://tests/TestScene.tscn
echo "\n-- integration tests --"
godot --headless --path "$ROOT/game" res://tests/Integration.tscn
echo "\n-- end-to-end playthrough --"
godot --headless --path "$ROOT/game" res://tests/Playthrough.tscn
echo "\nAll suites completed."
