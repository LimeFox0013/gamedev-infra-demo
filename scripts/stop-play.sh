#!/usr/bin/env bash
# Stops the workspace's game preview entirely — the game, the picture transport and the virtual
# display — and clears its status. Exits 0 also when nothing was running.
set -uo pipefail

# play.sh starts run.sh in its own session, so its process group is the whole stack: signal the
# group first (run.sh reaps its children), then whatever survived by name, then insist.
for pid in $(pgrep -f /opt/lf-preview/run.sh 2>/dev/null); do
  kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
done
pkill -TERM -f /opt/lf-preview/runner.py 2>/dev/null || true
pkill -TERM -x godot 2>/dev/null || true
for _ in 1 2 3 4; do
  pgrep -f '/opt/lf-preview/(run.sh|runner.py)' >/dev/null 2>&1 || break
  sleep 0.5
done
pkill -KILL -f /opt/lf-preview/runner.py 2>/dev/null || true
pkill -KILL -f /opt/lf-preview/run.sh 2>/dev/null || true
pkill -KILL -x godot 2>/dev/null || true
pkill -KILL -f 'websockify 127.0.0.1' 2>/dev/null || true
pkill -KILL -x x11vnc 2>/dev/null || true
pkill -KILL -f 'Xvfb :99' 2>/dev/null || true
rm -f /tmp/lf-preview/status.json
echo "STOPPED"
