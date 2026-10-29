#!/usr/bin/env bash
# Runs games/<name>/'s GUT test suite headless: every test file its .gutconfig.json lists (the
# game's tests/ and the kit's library). Any further arguments go to GUT, for example
# `scripts/test.sh <name> -gselect=test_main.gd` runs one test file.
# Exits non-zero when a test fails.
set -euo pipefail
cd "$(dirname "$0")/.."

name="${1:-}"
dir="games/$name"
if [ -z "$name" ] || [ ! -f "$dir/project.godot" ]; then
  echo "usage: scripts/test.sh <name> [GUT options]   (an existing games/<name>/ project)" >&2
  exit 1
fi
shift
if [ ! -f "$dir/addons/gut/gut_cmdln.gd" ] || [ ! -f "$dir/.gutconfig.json" ]; then
  echo "$dir has no GUT runner: link addons/gut -> ../../../libs/gut and add .gutconfig.json (scripts/new-game.sh does both)" >&2
  exit 1
fi

# Registers every class_name (GutTest included) before the run.
godot --headless --path "$dir" --import >/dev/null
godot --headless --path "$dir" -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit "$@"
