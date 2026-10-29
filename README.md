# Godot games

A monorepo of Godot 4 games. Each game is its own Godot project under `games/<name>/`.

## Commands

| Command | What it does |
|---|---|
| `scripts/new-game.sh <name>` | Creates a new, empty game, `games/<name>/`: a Godot 4 project with an empty main scene, a web export preset and a GUT test setup, linked to the shared libraries. The game itself is built in it afterwards. Prints `CREATED games/<name>` (exit 0), `INVALID <reason>` (exit 2) or `EXISTS games/<name>` (exit 3); writes nothing outside `games/<name>/`. |
| `scripts/test.sh <name> [GUT options]` | Runs the game's GUT tests headless and exits non-zero on a failure; `-gselect=<file>.gd` runs one test file. |
| `scripts/play.sh <name>` | Runs the game for the workspace's preview; `scripts/stop-play.sh` stops it. |

Every command runs Godot headless — no editor is needed.

## Your rules and skills

Add the rules, skills and shared libraries your agent should follow to this repository — the
coding workspace's agent loads the repository's own guidance (for example `AGENTS.md` and
`.agents/skills/`) from its first turn.
