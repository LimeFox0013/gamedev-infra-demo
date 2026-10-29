# Rules for this repository

This repository is a monorepo of Godot 4 games (`games/<name>/`). These rules are yours: change
or delete any of them. They came with the workspace's game-factory kit (see `.lf-kit.json`).

## New games

New games are made only by `scripts/new-game.sh <name>`; never lay out a project by hand. It
writes an empty project — an empty main scene, a web export preset, a GUT test setup with no test
yet, the links to the shared libraries — and nothing outside `games/<name>/`. The skill
`create-game` (`.agents/skills/create-game/`) says when to call it and how to read its result.

A new game holds no gameplay, art or rules: there is no starter game to adapt. You build the game
the owner asked for from scratch in that empty project, reading `libs/lf-godot-gd-utils/LF_INDEX.md`
first (next section) so what the library already has is reused, not written again.

## lf-godot-gd-utils first

Applies whenever you plan, write or change GDScript. The skill `lf-utils-first`
(`.agents/skills/lf-utils-first/`) covers it; this rule backs it up, because a skill match is a
judgment call.

Before writing any new GDScript class, helper, component or system:

1. Read `libs/lf-godot-gd-utils/LF_INDEX.md` (the "Find it by task" table first). Every class in
   the library starts with `LF`.
2. If a class fits, open its module `README.md` and reuse it. Do not write a second copy in a game.
3. If nothing fits, write the helper in the game that needs it. The library is read-only for you:
   never change, add or delete a file under `libs/lf-godot-gd-utils/`. When the helper is generic
   (no game classes, no game constants), add one line for it to `LIB_CANDIDATES.md` at the
   repository root (create the file on first use), for the owner, who maintains the library, to
   review and promote:
   `- games/<name>/<path>.gd — <what it does> — <why any game could use it>`

Say which index row you checked when you plan a feature, so a skipped check is visible.

## How the library is kept

- `libs/lf-godot-gd-utils/` is a git submodule of the library's public repository
  (https://github.com/LimeFox0013/lf-godot-gd-utils, see `.gitmodules`), checked out at the commit
  this repository records. `.lf-kit.json` records which commit the kit came with. There is no
  second copy: never copy library files into a game.
- If the folder is empty (a fresh clone), check it out with
  `git submodule update --init libs/lf-godot-gd-utils`; `scripts/new-game.sh` refuses to make a
  game until it is.
- Scripts and scenes address it as `res://libs/lf-godot-gd-utils/...`. A game under `games/<name>/`
  reaches it through a relative symlink `games/<name>/libs/lf-godot-gd-utils` ->
  `../../../libs/lf-godot-gd-utils`, made when the game is created, so every game uses the same copy.
- The library is read-only for you: no edits inside it, no commits inside it (`git -C
  libs/lf-godot-gd-utils commit`), and its folder is never staged here. A change made inside it
  could not reach the owner's GitHub repository without a pull request into the library's own
  repository, so it would be stranded in this workspace. Generic helpers go in the game and on
  `LIB_CANDIDATES.md` (rule 3 above); the platform's turn commit leaves the library alone too.
- Never move the submodule to another library commit (no `git -C libs/lf-godot-gd-utils checkout`,
  `pull` or `submodule update --remote`) unless the owner asks for it. A newer library is offered as a
  separate branch for the owner to review and merge, never written over your files.

## Playtest first, tests at commit

The default flow for changing how a game plays or feels:

1. Build the change with its own tests (single test files while developing; no full suite):
   `scripts/test.sh <name> -gselect=test_<file>.gd` runs one GUT test file.
2. Start the game with `scripts/play.sh <name>` and let the player play it in the workspace's
   preview. Wait for the player's verdict; tune from it. Read the running game's errors and printed
   output from the preview before reporting that it works.
3. Only when the player is happy (or asks to commit): run the game's full test suite with
   `scripts/test.sh <name>` (the game's `tests/` and the library's tests), then commit.

Tests use GUT, kept in `libs/gut/` (version in `.lf-kit.json`) and linked into each game as
`games/<name>/addons/gut`. A game's `.gutconfig.json` lists the folders its suite runs.

A green suite says nothing about how a game feels, and a full run costs minutes each time. Pure
refactors, spec-only changes and bug fixes with a clear failing test skip the playtest step; the
full suite still runs before their commit.

## Runtime feedback

While a game's preview runs, the running game's errors (file and line), printed output, live
reloads and restarts are collected by the preview runner. Each message you receive in that game's
chat carries the events since your previous turn; read them before you answer, and never ask the
owner to paste errors. For more: `tail -n 100 /tmp/lf-preview/events.jsonl` (one JSON event per
line); `cat /tmp/lf-preview/status.json` says which game plays and whether someone watches.
A saved script with a parse error is reported there and the game keeps running the old code until
you fix it. A change the preview could not apply live restarts the game and says why.

## Playtests

`scripts/playtest.sh <name> <script.json>` plays a game yourself through scripted inputs, on a
display of its own, and leaves frames, output and errors under `/tmp/lf-playtest/<name>/…`. The
skill `playtest` (`.agents/skills/playtest/`) covers the script shape and how to read the result.
Use it to check a change plays as intended, or to reproduce a bug, before the owner's turn; it
never disturbs the owner's running preview.

## Playable before finished

A game is finished only when it is playable as the owner asked. With the game, keep its scripted
run in `games/<name>/tests/playtest.json` and state in its `"expect"` list what the owner's request
requires: one short-named, observable fact per thing the owner named — the objects that must
appear, the controls and keys that must move something, the score that must grow (the skill
`playtest` has the shape). Before you say a game or a feature is done, run
`python3 /opt/lf-playtest/playable.py <name>` from the repository root: it passes only with no
errors, every expectation observed and a picture that responds to the inputs. A game with no
expectation fails. Never weaken or drop an expectation to pass, and never add motion (an animated
label) that no expectation names — it counts for nothing. The platform runs the same check after
every turn that changed the game's code or scenes, sends a failure back to you, and shows the owner
each expectation and whether it held.

## The platform's brief

Every message in a game's chat reaches you after a short brief the platform adds (the owner does
not see it): the library-first rule, the expectations to keep, no hand steps, and the Godot
mistakes this service has already met. Follow it; it is not repeated here. The owner's reply shows
the platform's check first and your text after it, labelled as yours, so report only what you
checked.

## The owner does nothing by hand

- Never ask the owner to open the editor, an inspector or a file, to drag or assign anything, or
  to run a command. The owner has only this chat. Do the wiring in code: `load("res://...")` or
  `preload` instead of an export variable someone must assign, nodes and signals connected in
  scripts or scene files you write.
- When you cannot do something, say what is missing in plain words; do not call the work finished.
- Keep the owner's words: keys, names and numbers the owner named are used as asked (arrow keys
  stay arrow keys). If you could not, say so plainly and why.

## Git and delivery

When `git remote` lists `origin`, this repository is bound to the owner's GitHub repository. Your
changes are then on the working branch `lf/games`, never on the default branch; you hold no GitHub
credential, and the platform pushes that branch and opens (or updates) its pull request when the
owner asks, when a chat ends, when the workspace goes idle and before it sleeps. The skill
`git-workflow` (`.agents/skills/git-workflow/`) covers it; never rewrite history, never switch
branches. With no `origin` the repository lives on the workspace only, on whatever branch is
checked out, and there is nothing to push.

## Conventional commits

When you finish a feature, or the owner says they are done, run the skill `save`
(`.agents/skills/save/`) in that same turn, before you reply. The platform also asks the agent to
run it once before the workspace sleeps. It lists what is pending, groups it by game and concern,
leaves out secrets and generated files, and makes one conventional commit per group: subject
`<type>(<game>): <subject>` with a type from `feat fix refactor test docs style perf chore`, and a
body that says why — on the branch that is checked out, with no `Chat-Message` trailer. No remote
is needed, and none is asked for.

Several chats may change different games at the same moment. A commit holds only its own game's
files and the shared root files that change was made with (`LIB_CANDIDATES.md`, a script). Never
stage, commit, reset, stash, check out or revert another game's pending changes: no `git add -A`
or `git add .` without paths, no `git stash`, no `git reset`, no `git checkout -- <path>`. The
skill's helper commits by path and retries while another commit holds the repository.

## Game chats

Each game can have its own chat in the workspace. A chat works inside `games/<name>/`, and after
every turn the platform makes one commit covering that game and the repository-root `libs/` (never
inside the read-only `libs/lf-godot-gd-utils`) — nothing else — with the subject
`chat(<name>): ...` and a `Chat-Message: <id>` trailer. `games/<name>/.chat/history.jsonl` is the chat's record: append-only,
written by the platform — do not edit or delete it, and do not amend or rewrite those commits.
