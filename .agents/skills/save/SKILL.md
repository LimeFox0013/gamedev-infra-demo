---
name: save
description: >
  Record finished work in this games repository as conventional commits, one game at a time.
  Use this skill when a feature or fix you were asked for is finished, when the owner says they
  are done ("that's all", "wrap up", "save", "commit this", "I'm done for today"), and when the
  platform asks you to save before the workspace sleeps. It lists what is pending, groups it by
  game and concern, leaves out secrets and generated files, and commits each group with a
  message that says what changed and why — without touching other games' pending work, which
  other chats may be changing at the same moment. Also invocable as /save.
---

# save — record pending work, one game at a time

This repository is a monorepo of games (`games/<name>/`) plus shared files at its root (`scripts/`,
`AGENTS.md`, `LIB_CANDIDATES.md`, …). Several chats may be changing different games
right now. Everything below keeps your commits to your own game's files and never disturbs
anyone else's.

The helper `python3 .agents/skills/save/save_commit.py` does the git work; run it from anywhere in
the repository. It prints JSON.

## Step 1 — Inventory

```
python3 .agents/skills/save/save_commit.py pending
```

You get `games` (pending files per game), `shared` (pending files outside `games/`), `library`
(changes inside `libs/lf-godot-gd-utils`) and `leftOut` (files the safety scan keeps out, with the
reason).

- Nothing in `games` or `shared`: say "Nothing to save." and stop. Do not make an empty commit.
- In a game chat, you save **your game only** (and the shared files your change was made with).
  Other games listed there belong to other chats: leave them exactly as they are.
- Before the workspace sleeps (the platform asks you to save), save every game listed, one game
  at a time, and the shared files.

## Step 2 — Group by concern

Within one game, a group is one answer to "what changed and why?" — a new mechanic, a bug fix,
its tests, art or tuning. One commit per group; split a group whose subject would need "and".
A shared file goes into the commit of the game whose change needed it (for example the line you
added to `LIB_CANDIDATES.md` for that game's helper). A shared change no game needed (a script, a
rule) is its own commit with the scope `repo`.

Write each message:

```
<type>(<game>): <subject — imperative, lower case, no full stop; whole line at most 72 characters>

<body: why — the owner's goal or the bug it fixes; what changed, if the subject does not say it>
```

- `<type>`: `feat` (new behaviour), `fix` (a bug), `refactor` (no behaviour change), `test`,
  `docs`, `style` (formatting only), `perf`, `chore` (tooling, config).
- `<game>`: the game's folder name. Never `library`, never a `Chat-Message:` line — those mark
  the platform's own turn commits.

## Step 3 — Safety scan

The helper already keeps out of every commit:

- secrets and credentials: `.env*`, `*.pem`, `*.key`, keystores, `export_credentials.cfg`, and any
  file whose text holds a private key, a token or `password = …` / `api_key = …`;
- generated or build output: `.godot/`, `build/`, `export/`, exported binaries (`*.pck`, `*.zip`,
  `*.exe`, `*.apk`, …), caches.

Read `leftOut` and tell the owner, in plain words, which files were kept out and why. Never move
a left-out file into a commit by another route, and never delete it.

The utilities library `libs/lf-godot-gd-utils` is read-only: it is never staged or committed here,
and the helper refuses any path inside it. If `library` lists changes, say so to the owner and
leave them as they are (do not revert them).

## Step 4 — Tests before code commits

The rule "Playtest first, tests at commit" in `AGENTS.md` still applies: a group that changes a
game's code is committed only after `scripts/test.sh <game>` passes. A group whose suite fails is
not committed; say which tests fail and leave its files pending. Docs-only, art-only and tuning
groups with no code need no run.

## Step 5 — Commit in sequence

One call per group, in order:

```
python3 .agents/skills/save/save_commit.py commit --scope <game> --type feat \
  --subject "add a double jump" \
  --body "The owner wants a second jump in mid-air so the gaps can be wider." \
  --path games/<game>/player.gd --path games/<game>/tests/test_player.gd \
  --shared LIB_CANDIDATES.md
```

- Leave out `--path` to commit everything pending in `games/<game>/`.
- The helper re-reads what is pending just before staging, stages and commits only those files
  (`git add -A -- <files>` then `git commit -- <files>`), and when another git process holds
  `.git/index.lock` it waits a moment and starts over. You never need `git add -A`, `git add .`,
  `git stash`, `git reset`, `git checkout -- <path>` or `git restore` — never use them: they would
  take or destroy other chats' work.
- `{"nothing": true}` means another commit already recorded those files: move on.
- `{"error": …}` with exit 2 is a refused request (wrong scope, a path in another game or in the
  library, a bad message): fix the request. Exit 1 is a failed commit: report it plainly and stop.

Print each result as one line: `<short sha> <subject>`.

## What this never does

- No new branch, no switching branches, no amend, rebase, reset or force-push. Commits go on the
  branch that is checked out (`lf/games` when the repository has an `origin`).
- No remote is needed. With no `origin` the commits stay in the workspace, and you never ask the
  owner to set a remote up. Pushing is the platform's (skill `git-workflow`).
- It does not repeat the platform's record: the platform still makes its own `chat(<game>): …`
  commit after your turn, holding only what you left and the chat's history.
