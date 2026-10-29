#!/usr/bin/env bash
# Plays games/<name>/ through a scripted sequence of inputs, without a viewer and without touching
# the workspace's preview: its own virtual display, its own game process, movie-writing mode.
#   scripts/playtest.sh <name> <script.json> [--frames N]
# Writes /tmp/lf-playtest/<name>/<timestamp>/: frames/ (PNG per frame), output.log (prints and
# errors) and summary.json; prints `PLAYTEST <dir>` and exits with Godot's exit code. The same
# script on unchanged game code gives the same frame sequence (`--fixed-fps`).
# Script shape: {"frames": 150, "log_every": 30, "watch": ["Character", "Hud/Score:text", "Rock*"],
#                "inputs": [{"frame": 10, "action": "jump", "pressed": true}, ...]}
# output.log gets `playtest watch frame=<n> <entry>=<value>` per watched entry every log_every frames.
set -euo pipefail
cd "$(dirname "$0")/.."

name="${1:-}"
script="${2:-}"
if [ -z "$name" ] || [ ! -f "games/$name/project.godot" ] || [ -z "$script" ] || [ ! -f "$script" ]; then
  echo "usage: scripts/playtest.sh <name> <script.json> [--frames N]   (an existing games/<name>/ and a readable script)" >&2
  exit 1
fi
shift 2
frames=""
while [ $# -gt 0 ]; do
  case "$1" in
    --frames) frames="${2:?--frames needs a number}"; shift 2 ;;
    *) echo "unknown option $1" >&2; exit 1 ;;
  esac
done

# Where the harness lives (the image: /opt/lf-playtest); LF_PLAYTEST_HARNESS overrides for local runs.
harness="${LF_PLAYTEST_HARNESS:-/opt/lf-playtest}"
[ -f "$harness/harness.tscn" ] || { echo "no playtest harness at $harness" >&2; exit 1; }
script_abs="$(cd "$(dirname "$script")" && pwd)/$(basename "$script")"
dir="games/$name"
out="${LF_PLAYTEST_OUT:-/tmp/lf-playtest}/$name/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$out/frames"

# The harness is reached through a temporary link inside the game; it is removed whatever happens.
link="$dir/.lf-playtest"
cleanup() {
  rm -f "$link"
  if [ -n "${xvfb_pid:-}" ]; then kill "$xvfb_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM
rm -f "$link"
ln -s "$harness" "$link"

# A display of its own (:98 — the preview uses :99); on a desktop the real display is used.
# Plain words, split on purpose (no value holds a space); bash 3.2 (macOS) cannot expand an empty array under set -u.
driver_args=""
if [ -z "${DISPLAY:-}" ] && command -v Xvfb >/dev/null 2>&1; then
  Xvfb :98 -screen 0 640x360x24 -nolisten tcp >/dev/null 2>&1 &
  xvfb_pid=$!
  sleep 1
  export DISPLAY=:98
  driver_args="--rendering-driver opengl3 --display-driver x11"
fi

frames_args=""
[ -n "$frames" ] && frames_args="--lf-frames=$frames"

set +e
# shellcheck disable=SC2086 — intentional word splitting of the option strings above.
godot --path "$dir" $driver_args --write-movie "$out/frames/frame.png" --fixed-fps 30 \
  res://.lf-playtest/harness.tscn -- "--lf-playtest=$script_abs" $frames_args >"$out/output.log" 2>&1
code=$?
set -e

count=$(find "$out/frames" -name '*.png' | wc -l | tr -d ' ')
printf '{"frames": %s, "exitCode": %s, "script": "%s", "game": "%s"}\n' "$count" "$code" "$script_abs" "$name" >"$out/summary.json"
echo "PLAYTEST $out"
exit "$code"
