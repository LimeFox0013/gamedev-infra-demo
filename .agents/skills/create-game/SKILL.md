---
name: create-game
description: >
  Make a new game. Use this skill when the owner asks, in plain words, for a NEW game
  ("make me a game about a frog", "start a new game", "I want another game") — not a change
  to a game that already exists. It derives a short lowercase-dash name from the request,
  creates the empty game project with scripts/new-game.sh <name> (the only way new games
  are made), reads the result line and exit code, and then builds the requested game from
  scratch in it, reading the utilities library's index first. Also invocable as /create-game.
---

# create-game — a new game from one request

A new game is always made by the repository's creation procedure, `scripts/new-game.sh <name>`.
It writes an empty Godot project into `games/<name>/` — an empty main scene that runs, a web
export preset, a GUT test setup with no test yet — and links the shared libraries. There is no
starter game: the new game holds no gameplay, art or rules until they are built from the owner's
request. It never writes outside `games/<name>/` and never touches an existing game. Never lay
out a game project by hand, and never copy another game's folder to start one.

If your only tool is `create_game(name)`, that tool runs this same script and returns its
output: follow the steps below with it in place of the command.

## 1. Is it a new game?

Use this skill only when the owner asks for a new game. A request to change, fix or extend a
game that already exists belongs in that game's own chat: say so, and create nothing.

## 2. Derive the name

From the request, pick a short name that says what the game is:

- 2 to 40 characters: lowercase letters `a-z`, digits and dashes, starting with a letter
  (`^[a-z][a-z0-9-]{1,39}$`).
- One to three words joined by dashes: "a game where a frog jumps over logs" → `frog-jump`;
  "Space Race!" → `space-race`. Drop punctuation; spell numbers as digits.
- `library` is reserved.
- If the owner named the game, use that name, converted to the rules above.

## 3. Create it

Run from the repository root:

```
scripts/new-game.sh <name>
```

The first line it prints says what happened, and the exit code matches:

| Exit | First line | What to do |
|---|---|---|
| 0 | `CREATED games/<name>` | Done: go to step 4. |
| 2 | `INVALID <reason>` | Nothing was written. Pick a name that fits the rules (step 2) and run it again once. |
| 3 | `EXISTS games/<name>` | Nothing was written; that game is untouched. Tell the owner a game with that name already exists, suggest another name (for example `<name>-2`, or a more specific one), and wait for their answer. Never delete, overwrite or reuse the existing game. |
| 1 | `ERROR <reason>` | This repository lacks the test runner or its utilities library is not checked out. Tell the owner what is missing; do not try to build the game another way. |

## 4. Build the requested game from scratch

The new game is empty. When you can edit files (the game's own chat), build what the owner asked
for in `games/<name>/`:

1. Read `libs/lf-godot-gd-utils/LF_INDEX.md` first — the skill `lf-utils-first` — and say which
   index rows you checked; reuse what fits instead of writing it again.
2. Write the game's scenes and scripts, its input actions in `project.godot`, and its tests in
   `games/<name>/tests/`, following the repository's rules (playtest first, tests at commit).

When your only tool is `create_game(name)`, you cannot edit files: the game is built in its own
chat (step 5).

## 5. Tell the owner

In plain words, without jargon:

- The new game `<name>` is made: an empty project, ready for the game to be built in it.
- What they asked for is built, and changed later, in that game's own chat. Each game has its own
  chat, and changes to one game never touch another.
