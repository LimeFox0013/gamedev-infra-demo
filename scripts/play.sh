#!/usr/bin/env bash
# Starts (or replaces) the workspace's game preview for games/<name>/: the picture, input and
# runtime output are served at the workspace's preview address, and the game process itself
# runs while someone watches. The running game's errors and printed output land in
# /tmp/lf-preview/events.jsonl; /tmp/lf-preview/status.json says which game plays.
set -euo pipefail
cd "$(dirname "$0")/.."

name="${1:?usage: scripts/play.sh <name>}"
[ -f "games/$name/project.godot" ] || { echo "No game named $name under games/." >&2; exit 1; }

"$(dirname "$0")/stop-play.sh" >/dev/null
mkdir -p /tmp/lf-preview
setsid nohup /opt/lf-preview/run.sh "$PWD/games/$name" >/tmp/lf-preview/run.log 2>&1 &

# Return only once the runner answers on the preview port, so a viewer that connects right
# after this call finds the picture transport up (the stack needs a few seconds to come up).
for _ in $(seq 1 40); do
  if (exec 3<>/dev/tcp/127.0.0.1/3000) 2>/dev/null; then
    exec 3>&- 2>/dev/null
    echo "PLAYING games/$name"
    exit 0
  fi
  sleep 0.5
done
echo "The preview runner did not come up; see /tmp/lf-preview/run.log" >&2
exit 1
