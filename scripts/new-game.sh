#!/usr/bin/env bash
# Creates games/<name>/ — a new, empty Godot 4 project: an empty main scene that runs, a web export
# preset, a GUT test setup whose suite passes with no test of the game's own, and links to the
# repository's utilities library and test runner. It holds no gameplay, art or rules: the game is
# built in it afterwards, from what the owner asked for. The only way new games are made. It
# writes nothing outside games/<name>/.
#
# The first line printed says what happened, and the exit code matches it:
#   0  CREATED games/<name>
#   2  INVALID <reason>      (nothing written)
#   3  EXISTS games/<name>   (nothing written; that game is left as it is)
#   1  ERROR <reason>        (this repository lacks the test runner, or the library submodule is
#                            not checked out; nothing written)
set -euo pipefail
cd "$(dirname "$0")/.."

readonly NAME_PATTERN='^[a-z][a-z0-9-]{1,39}$'
readonly RESERVED_NAMES=(library)
readonly LIBRARY=libs/lf-godot-gd-utils
readonly LIBRARY_INDEX="$LIBRARY/LF_INDEX.md"
readonly TEST_RUNNER=libs/gut
# A game reaches the repository-root libraries through the same relative links, so every game
# uses one copy: res://libs/lf-godot-gd-utils/... and the runner's own res://addons/gut.
readonly LINK_TO_ROOT=../../..

if [ "$#" -ne 1 ]; then
  echo "INVALID expected exactly one name, for example: scripts/new-game.sh sky-hopper"
  exit 2
fi
name="$1"
if [[ ! "$name" =~ $NAME_PATTERN ]]; then
  echo "INVALID a name is 2 to 40 characters: lowercase letters, digits and dashes, starting with a letter"
  exit 2
fi
for reserved in "${RESERVED_NAMES[@]}"; do
  if [ "$name" = "$reserved" ]; then
    echo "INVALID the name $name is reserved"
    exit 2
  fi
done

dir="games/$name"
if [ -e "$dir" ] || [ -L "$dir" ]; then
  echo "EXISTS $dir"
  exit 3
fi

if [ ! -d "$TEST_RUNNER" ]; then
  echo "ERROR $TEST_RUNNER is missing from this repository, so no game can be created"
  exit 1
fi
# The utilities library is a git submodule: its folder exists but is empty until it is checked out.
if [ ! -f "$LIBRARY_INDEX" ]; then
  echo "ERROR $LIBRARY is not checked out (run: git submodule update --init $LIBRARY), so no game can be created"
  exit 1
fi

mkdir -p games
mkdir "$dir"
# A creation that fails partway leaves nothing behind.
created=0
trap '[ "$created" = 1 ] || rm -rf "$dir"' EXIT

cat > "$dir/project.godot" <<GODOT
config_version=5

[application]

config/name="$name"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
GODOT

cat > "$dir/main.tscn" <<'TSCN'
[gd_scene format=3]

[node name="Main" type="Node2D"]
TSCN

# Web preset: threads off, so the export runs on any static host without cross-origin isolation.
cat > "$dir/export_presets.cfg" <<'CFG'
[preset.0]

name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/web/index.html"

[preset.0.options]

variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/canvas_resize_policy=2
CFG

# scripts/test.sh runs every test_*.gd these folders hold: the game's own tests/ (empty until the
# game has tests, kept in git by .gitkeep) and the library's tests.
mkdir "$dir/tests"
: > "$dir/tests/.gitkeep"
cat > "$dir/.gutconfig.json" <<JSON
{
  "dirs": ["res://tests", "res://$LIBRARY"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "should_exit": true
}
JSON

mkdir "$dir/libs" "$dir/addons"
ln -s "$LINK_TO_ROOT/$LIBRARY" "$dir/$LIBRARY"
ln -s "$LINK_TO_ROOT/$TEST_RUNNER" "$dir/addons/gut"

godot --headless --path "$dir" --import >/dev/null 2>&1 || true

created=1
echo "CREATED $dir"
echo "It is empty: build the game asked for in it. Run it with: scripts/play.sh $name"
