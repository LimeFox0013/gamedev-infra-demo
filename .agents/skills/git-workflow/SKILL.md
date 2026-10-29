---
name: git-workflow
description: >
  How this repository's changes reach the owner's GitHub repository. Use this skill when the
  owner asks to push, publish, open or update a pull request, send changes to GitHub, or asks
  where their changes went; when a feature is finished or the owner says the session is ending
  (commit it then with the skill `save`); and before you reach for any git command that
  touches a branch, a commit or a remote. It says which branch you work on (never the default
  one), how you write your commits and what you leave to the platform, and how a pull request
  gets opened. Also invocable as /git-workflow.
---

# git-workflow — branch, commit, push, pull request

Run `git remote` first. When it lists `origin`, this repository is bound to one GitHub repository
of the owner: your changes reach it as a pushed branch with a pull request, and the owner reviews
and merges that pull request. You never write to the default branch and you never merge. When it
lists nothing, the repository lives on the workspace only: stay on the branch that is checked out,
commit normally, and tell an owner who asks to push that this workspace is not bound to GitHub.

## The branch

- Work happens on the working branch `lf/games`. The platform checks it out for every chat turn,
  so you are on it already. Do not create other branches and do not switch away; the platform
  pushes this one branch, and a further push updates its open pull request.
- Never commit to, push to or force-push the default branch (`main`).
- Never rewrite history: no amend, rebase, reset or force-push of commits that exist.

## Commits

- After every turn the platform commits the chat's game and the shared `libs/` (never inside the
  read-only `libs/lf-godot-gd-utils`) for you, with the subject `chat(<name>): ...` and a
  `Chat-Message` trailer. That record of the turn is the
  platform's; never write it yourself.
- Your own commits are conventional commits that say what changed and why (next section).
- If you must commit something outside that scope (a script, a rule), make a conventional commit
  of that path the same way, with `repo` as the scope (`save` does it with `--scope repo`).

## Conventional commits

Commit in the same turn, before your reply, when either happens:

- a feature (or fix) you were asked for is finished — it works, its tests pass, the owner is
  happy with it when they played it;
- the owner says the session is ending ("that's all for today", "wrap up", "I'm done").

Earlier turns are already committed by the platform, so there is nothing to collect from them:
commit what this turn changed, and if nothing is left uncommitted, there is nothing to commit.
The platform's commit after your reply then records only the chat's history.

The message:

```
<type>(<game>): <subject — imperative, lower case, no full stop, under 72 characters>

<body: why the change was made — the owner's goal or the bug it fixes; what changed, if the
subject alone does not say it>
```

- `<type>` is one of: `feat` (new behaviour), `fix` (a bug), `refactor` (no behaviour change),
  `test` (tests only), `docs`, `style` (formatting only), `perf`, `chore` (tooling, config).
- `<game>` is the game's folder name (`games/<game>/`).
- Never add a `Chat-Message:` trailer: that one marks the platform's turn commits.
- Split unrelated changes into separate commits.

Make them with the skill `save` (`.agents/skills/save/`): its helper lists what is pending by
game, leaves out secrets and generated files, and commits by path — so another chat's pending or
staged work on another game is never swept into yours, reset, stashed or reverted. Never run
`git add -A` or `git add .` without paths, `git stash`, `git reset` or `git checkout -- <path>`.
If git says `index.lock` exists, another chat is committing: the helper waits a moment and reads
what is pending again before it stages. If it says there is nothing to commit, the platform
already recorded it; do not make an empty commit.

`libs/lf-godot-gd-utils` is a git submodule and read-only for you: never edit, commit or stage
anything inside it, and never move it to another library commit (no `git -C libs/lf-godot-gd-utils
checkout`, `pull` or `submodule update --remote`) unless the owner asks. A generic helper stays in
the game and gets a line in `LIB_CANDIDATES.md` (`AGENTS.md`, "lf-godot-gd-utils first").

- Commit on the branch that is checked out (`lf/games` when `origin` exists). Never create a
  branch, never amend, rebase or reset.
- No remote is needed: with no `origin` the commits stay in the workspace, and you never ask the
  owner to set a remote up.

## Push and pull request

- You cannot push: this workspace holds no GitHub credential, by design. The platform does it.
- The owner asks for it with the **Open pull request** action on their game workspace page. The
  platform then pushes `lf/games` and opens the pull request — or, when one is already open,
  updates it with the new commits — and shows the owner its address.
- The platform also does it by itself when a chat ends, goes idle past the workspace's timeout,
  and just before the workspace sleeps. Nothing committed is left only on the workspace.
- When the owner asks you in chat to push or open a pull request: say that it is done with the
  **Open pull request** action (and automatically at the moments above); do not try git remote
  commands. If they ask what was sent, read `git log origin/<default>..lf/games` and tell them in
  plain words.

## If something goes wrong

- A push or pull request that fails is reported to the owner by the platform in plain words and
  every commit stays in the workspace; nothing is lost. Do not work around it.
- If a checkout of `lf/games` is refused because of uncommitted changes, tell the owner what is
  in the way instead of discarding anything.
