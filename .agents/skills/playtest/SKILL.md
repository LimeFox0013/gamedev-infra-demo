---
name: playtest
description: >
  Play a game yourself through a scripted sequence of inputs and read back what happened —
  frames, printed output and errors — without the owner watching. Use it to check how a
  change plays before asking the owner to try it, to reproduce a bug the owner describes
  ("it crashes when I jump twice"), to compare behaviour before and after a change, and to
  prove a game is playable before saying it is done (playable.py). Runs with
  scripts/playtest.sh <name> <script.json>; never disturbs the owner's running preview.
  Also invocable as /playtest.
---

# playtest — play a game by script

`scripts/playtest.sh <name> <script.json> [--frames N]` runs `games/<name>/` on a display of its
own, in movie-writing mode at 30 fixed frames per second, pressing the inputs your script lists on
the frames it names. It never touches the preview the owner may be watching.

## 1. Write the script

A JSON object. The game's own scripted run lives in `games/<name>/tests/playtest.json`: write it
with the game and keep it up to date — it is what the playable check runs (section 4). One-off
scripts go outside the game's folder (for example `/tmp/pt-<name>.json`).

```json
{
  "frames": 150,
  "log_every": 30,
  "watch": ["Character", "Hud/Score"],
  "inputs": [
    {"frame": 10, "action": "jump", "pressed": true},
    {"frame": 12, "action": "jump", "pressed": false},
    {"frame": 60, "action": "jump", "pressed": true},
    {"frame": 62, "action": "jump", "pressed": false}
  ]
}
```

- `action` is an input-map action of the game (`project.godot` → `[input]`), not a key.
- `watch` lists what is printed every `log_every` frames, one `playtest watch frame=<n>
  <entry>=<value>` line each: `"Ship"` (a node path under the main scene: its `position`, else
  its `text`), `"Hud/Score:text"` (a node path and one property), `"Rock*"` (a name pattern
  matched anywhere in the running game: how many nodes match). A missing node prints `<missing>`.
- `frames` ends the run; 30 frames are one second.

## 2. Run it and read the result

```
scripts/playtest.sh <name> /tmp/pt-<name>.json
```

The last line is `PLAYTEST <dir>`; the exit code is Godot's (0 means the game ran and quit
cleanly). In `<dir>`:

- `output.log` — every `print`, every error with its file and line, and the harness's own
  `playtest frame=<n> …` and `playtest watch frame=<n> …` state lines.
- `frames/frame*.png` — one image per frame; open a few (start, around each input, end) to see
  what the owner would see.
- `summary.json` — frame count, exit code, script path.

## 3. Use it honestly

- Say what you ran and what you saw; quote the state lines or errors that matter.
- The same script on unchanged code gives the same `output.log` state lines, so run it before and
  after a change to show the difference.
- A playtest is not the owner's verdict: it checks that the game runs and behaves as you intended,
  then the owner plays it in the preview.

## 4. Expectations — what the owner asked for

`tests/playtest.json` states, under `"expect"`, what the owner's request requires, as facts the
run can observe. Derive one from each thing the owner named: an object that must appear, a
control or key that must move something, a score that must grow. Short names the owner reads.

```json
"expect": [
  {"name": "rocks appear", "node": "Rock*", "exists": true, "byFrame": 120},
  {"name": "ship moves on move_left", "node": "Ship", "changes": "position", "withInput": true},
  {"name": "score grows", "node": "Hud/Score", "increases": "text"}
]
```

- `exists: true` — a node matching `node` (a path, or a name pattern with `*`) is there by frame
  `byFrame` (default: any time in the run). Name the nodes you spawn so a pattern finds them:
  `rock.name = "Rock"` then `add_child(rock, true)` gives `Rock`, `Rock2`, …; without the `true`
  Godot names repeats `@Rock@2`, which only `*Rock*` matches.
- `changes: "<property>"` — the property takes more than one value in the run; with
  `"withInput": true` it must differ from the same run without inputs (a control moves it).
- `increases: "<property>"` — the first number in the property's value grows (`Score: 3`).
- Press, in `inputs`, the actions your `withInput` expectations need, early enough to be seen.

An animation nobody asked for (a pulsing label) proves nothing and counts toward nothing. Never
weaken or drop an expectation to pass the check; fix the game.

## 5. The playable check — before you say a game is done

```
python3 /opt/lf-playtest/playable.py <name>
```

It runs the game twice with `tests/playtest.json` — with its inputs and with none — and passes
only when there is no script or scene error, every expectation is observed, and the picture with
inputs differs from the one without. No script or no expectation: it fails without running. Exit 0
playable, 1 not (each expectation that did not hold and the errors are listed), 2 the check could
not run. Fix until it passes; never report a game as built while it fails. The Godot mistakes
already met here are listed in the platform's brief that comes with each message.
