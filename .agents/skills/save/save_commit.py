#!/usr/bin/env python3
"""save_commit.py — the `save` skill's git side: list what is pending in this games repository,
and commit one game's share of it as one conventional commit, safely while other chats change
other games at the same moment.

  python3 .agents/skills/save/save_commit.py pending
  python3 .agents/skills/save/save_commit.py commit --scope <game> --type feat \
      --subject "add a double jump" --body "The owner wants ..." [--path games/<game>/x.gd ...] \
      [--shared LIB_CANDIDATES.md ...]

`pending` prints one JSON object: `games` (pending paths per game), `shared` (pending paths
outside `games/`), `library` (changes inside the read-only utilities library: never committed
here) and `leftOut` (paths the safety scan keeps out of every commit, with the reason).

`commit` stages and commits exactly the pending files under the given paths (default: the whole
game) plus the `--shared` ones, as `<type>(<scope>): <subject>` with the body; anything else that
is pending or staged — another game's work — is never staged, committed, reset, stashed or
reverted. Before staging it reads what is pending again; while another process holds
`.git/index.lock` it waits briefly and starts over. It commits on the branch that is checked out,
never creates a branch and never amends. It prints one JSON object: `commit`, `subject`, `files`,
`leftOut`; or `nothing` when nothing under the paths is pending. A refused request exits 2 with
`error`; a failed commit exits 1.

Standard library and git only.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import subprocess
import sys
import time
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from pathlib import Path

GAMES_DIR = "games"
GAME_NAME_PATTERN = re.compile(r"^[a-z][a-z0-9-]*$")
# A commit not about one game (a script, a rule): the scope is the repository.
REPO_SCOPE = "repo"
COMMIT_TYPES = ("feat", "fix", "refactor", "test", "docs", "style", "perf", "chore")
SUBJECT_MAX_LENGTH = 72
# The platform's per-turn commits carry this trailer; the agent's never do.
PLATFORM_TRAILER = "Chat-Message:"
GITLINK_MODE = "160000"

# The lock every chat host of the repository takes for its per-turn commit
# (`game_chat_repo.py`, `LOCK_FILE`); taking it too keeps a save from racing those commits.
CHAT_LOCK_FILE = "lf-game-chat.lock"
CHAT_LOCK_WAIT_SECONDS = 60.0
CHAT_LOCK_POLL_SECONDS = 0.05
INDEX_LOCK_MARKER = "index.lock"
INDEX_LOCK_RETRY_DELAYS: tuple[float, ...] = (0.2, 0.5, 1.0, 2.0, 4.0)

# The safety scan: never committed, whatever the paths say.
SECRET_NAME_PATTERNS = (
    ".env", ".env.*", "*.pem", "*.key", "*.p12", "*.pfx", "*.keystore", "*.jks",
    "id_rsa*", "id_ed25519*", "secrets.*", "credentials.*", "export_credentials.cfg",
)
SECRET_CONTENT = re.compile(
    r"-----BEGIN [A-Z ]*PRIVATE KEY-----"
    r"|\b(?:password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*['\"]?[^\s'\"]{6,}"
    r"|\bgh[pousr]_[A-Za-z0-9]{20,}"
    r"|\bsk-[A-Za-z0-9_-]{20,}",
    re.IGNORECASE,
)
GENERATED_DIRS = (".godot", "build", "export", "exports", "__pycache__", ".lf-playtest", "node_modules")
GENERATED_NAME_PATTERNS = (
    "*.pyc", "*.tmp", "*.pck", "*.zip", "*.exe", "*.x86_64", "*.apk", "*.aab", "*.dmg", "*.wasm",
    "core", "core.[0-9]*", "*.core", "*.dmp",
)
# No source file is this large; a larger one is a dump, a render or a download, never committed.
MAX_COMMIT_FILE_BYTES = 10 * 1024 * 1024
CONTENT_SCAN_MAX_BYTES = 512 * 1024
REASON_SECRET = "looks like a secret or credential"
REASON_GENERATED = "generated or build output"
REASON_OVERSIZED = "too large to be source (over 10 MiB)"

EXIT_REFUSED = 2
EXIT_FAILED = 1


class GitError(RuntimeError):
    def __init__(self, args: Sequence[str], stderr: str) -> None:
        super().__init__(f"git {' '.join(args[:1])} failed: {stderr}")
        self.index_locked = INDEX_LOCK_MARKER in stderr


class Refused(Exception):
    """A request the procedure will not carry out; the message says why."""


def literal(path: str) -> str:
    return f":(literal){path}"


class Git:
    def __init__(self, root: Path) -> None:
        self.root = root

    def __call__(self, *args: str) -> str:
        result = subprocess.run(
            ["git", "-C", str(self.root), *args], capture_output=True, text=True
        )
        if result.returncode != 0:
            raise GitError(args, result.stderr.strip())
        return result.stdout


def repo_root(start: Path) -> Path:
    return Path(Git(start)("rev-parse", "--show-toplevel").strip())


def submodule_paths(git: Git) -> set[str]:
    """Every submodule the index records (the utilities library), checked out or not."""
    entries = git("ls-files", "-s", "-z")
    return {
        entry.split("\t", 1)[1]
        for entry in entries.split("\0")
        if entry.startswith(GITLINK_MODE) and "\t" in entry
    }


def status_paths(git: Git) -> list[str]:
    """Every uncommitted path (both sides of a rename), submodules included. A read that takes
    no `index.lock` (`--no-optional-locks`), so it never makes another chat's commit fail."""
    out = git("--no-optional-locks", "status", "--porcelain", "-z", "--untracked-files=all")
    paths: list[str] = []
    entries = iter(out.split("\0"))
    for entry in entries:
        if len(entry) < 4:
            continue
        paths.append(entry[3:])
        if entry[0] in "RC":
            source = next(entries, "")
            if source:
                paths.append(source)
    return paths


def _under(path: str, folder: str) -> bool:
    return path == folder or path.startswith(f"{folder}/")


def scan(root: Path, path: str) -> str | None:
    """Why `path` must not be committed, or None."""
    parts = path.split("/")
    name = parts[-1]
    if any(part in GENERATED_DIRS for part in parts[:-1]) or any(
        fnmatch.fnmatch(name, pattern) for pattern in GENERATED_NAME_PATTERNS
    ):
        return REASON_GENERATED
    if any(fnmatch.fnmatch(name, pattern) for pattern in SECRET_NAME_PATTERNS):
        return REASON_SECRET
    file = root / path
    if file.is_file() and not file.is_symlink() and file.stat().st_size > MAX_COMMIT_FILE_BYTES:
        return REASON_OVERSIZED
    if file.is_file() and not file.is_symlink() and file.stat().st_size <= CONTENT_SCAN_MAX_BYTES:
        try:
            text = file.read_text(errors="ignore")
        except OSError:
            return None
        if SECRET_CONTENT.search(text):
            return REASON_SECRET
    return None


def inventory(git: Git) -> dict[str, object]:
    libraries = submodule_paths(git)
    games: dict[str, list[str]] = {}
    shared: list[str] = []
    library: list[str] = []
    left_out: list[dict[str, str]] = []
    for path in sorted(set(status_paths(git))):
        if any(_under(path, lib) for lib in libraries):
            library.append(path)
            continue
        reason = scan(git.root, path)
        if reason is not None:
            left_out.append({"path": path, "reason": reason})
            continue
        parts = path.split("/")
        if parts[0] == GAMES_DIR and len(parts) > 2:
            games.setdefault(parts[1], []).append(path)
        else:
            shared.append(path)
    return {"games": games, "shared": shared, "library": library, "leftOut": left_out}


def validate_message(scope: str, kind: str, subject: str, body: str) -> str:
    if scope != REPO_SCOPE and not GAME_NAME_PATTERN.match(scope):
        raise Refused(f"The scope must be a game's folder name or {REPO_SCOPE!r}.")
    if kind not in COMMIT_TYPES:
        raise Refused(f"The type must be one of: {' '.join(COMMIT_TYPES)}.")
    subject = subject.strip()
    header = f"{kind}({scope}): {subject}"
    if not subject or "\n" in subject:
        raise Refused("The subject must be one line.")
    if len(header) > SUBJECT_MAX_LENGTH:
        raise Refused(f"The subject line must be at most {SUBJECT_MAX_LENGTH} characters: {header!r}.")
    if subject.endswith("."):
        raise Refused("The subject ends without a full stop.")
    if not body.strip():
        raise Refused("The body must say why the change was made.")
    if PLATFORM_TRAILER in body:
        raise Refused(f"The {PLATFORM_TRAILER} trailer belongs to the platform's turn commits.")
    return header


def allowed_paths(git: Git, scope: str, paths: Sequence[str], shared: Sequence[str]) -> list[str]:
    """The repository-relative paths this commit may cover; refuses anything that reaches
    another game or the utilities library."""
    libraries = submodule_paths(git)
    game_dir = f"{GAMES_DIR}/{scope}"
    if scope != REPO_SCOPE and not ((git.root / game_dir).is_dir() or git("ls-files", "--", literal(game_dir))):
        raise Refused(f"There is no game {scope!r} in {GAMES_DIR}/.")
    default = [game_dir] if scope != REPO_SCOPE else []
    wanted = [p.strip("/") for p in paths] or default
    result: list[str] = []
    for path in [*wanted, *(s.strip("/") for s in shared)]:
        if not path or path.startswith("..") or "/../" in f"/{path}/":
            raise Refused(f"{path!r} is not a path inside the repository.")
        if any(_under(path, lib) or _under(lib, path) for lib in libraries):
            raise Refused(f"{path!r} reaches the utilities library, which is read-only.")
        in_games = _under(path, GAMES_DIR)
        if path in wanted and scope != REPO_SCOPE and not _under(path, game_dir):
            raise Refused(f"{path!r} is not inside {game_dir}/; pass a shared file with --shared.")
        if in_games and not _under(path, game_dir):
            raise Refused(f"{path!r} belongs to another game or to every game; commit it in its own scope.")
        result.append(path)
    if not result:
        raise Refused(f"A {REPO_SCOPE!r} commit needs the paths it covers (--shared).")
    return result


@contextmanager
def chat_lock(git: Git) -> Iterator[None]:
    """The repository-wide lock of the platform's per-turn commits; without `fcntl`
    (not Linux/macOS) the index.lock retry alone keeps commits apart."""
    try:
        import fcntl
    except ImportError:
        yield
        return
    git_dir = Path(git("rev-parse", "--absolute-git-dir").strip())
    deadline = time.monotonic() + CHAT_LOCK_WAIT_SECONDS
    with open(git_dir / CHAT_LOCK_FILE, "a") as handle:
        while True:
            try:
                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise GitError(["commit"], f"timed out waiting for {CHAT_LOCK_FILE}") from None
                time.sleep(CHAT_LOCK_POLL_SECONDS)
        try:
            yield
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def _files_under(git: Git, covered: Sequence[str]) -> tuple[list[str], list[dict[str, str]]]:
    """The pending files under `covered` that may be committed, and those the scan keeps out."""
    libraries = submodule_paths(git)
    files: list[str] = []
    left_out: list[dict[str, str]] = []
    for path in sorted(set(status_paths(git))):
        if not any(_under(path, c) for c in covered) or any(_under(path, lib) for lib in libraries):
            continue
        reason = scan(git.root, path)
        if reason is None:
            files.append(path)
        else:
            left_out.append({"path": path, "reason": reason})
    return files, left_out


def commit(
    git: Git,
    scope: str,
    kind: str,
    subject: str,
    body: str,
    paths: Sequence[str] = (),
    shared: Sequence[str] = (),
    delays: Sequence[float] = INDEX_LOCK_RETRY_DELAYS,
) -> dict[str, object]:
    header = validate_message(scope, kind, subject, body)
    covered = allowed_paths(git, scope, paths, shared)
    for delay in (*delays, None):
        try:
            with chat_lock(git):
                # Read again on every attempt: another chat may have committed meanwhile.
                files, left_out = _files_under(git, covered)
                if not files:
                    return {"nothing": True, "leftOut": left_out}
                specs = [literal(f) for f in files]
                # `add` refuses a path gone from both the tree and the index (a staged rename's
                # source); `commit -- <paths>` still records its removal from HEAD.
                indexed = set(git("ls-files", "-z", "--", *specs).split("\0"))
                addable = [literal(f) for f in files if f in indexed or (git.root / f).exists()]
                if addable:
                    git("add", "-A", "--", *addable)
                git("commit", "-q", "-m", header, "-m", body.strip(), "--", *specs)
                sha = git("rev-parse", "HEAD").strip()
                return {"commit": sha, "subject": header, "files": files, "leftOut": left_out}
        except GitError as exc:
            if not exc.index_locked or delay is None:
                raise
            time.sleep(delay)
    raise AssertionError("unreachable")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="The save skill's inventory and commit.")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("pending", help="List what is pending, by game.")
    c = sub.add_parser("commit", help="Commit one game's (or the repository's) pending files.")
    c.add_argument("--scope", required=True, help=f"the game's folder name, or {REPO_SCOPE!r}")
    c.add_argument("--type", required=True, choices=COMMIT_TYPES)
    c.add_argument("--subject", required=True)
    c.add_argument("--body", required=True)
    c.add_argument("--path", action="append", default=[], help="a path inside the game (repeatable)")
    c.add_argument("--shared", action="append", default=[], help="a shared file outside games/ (repeatable)")
    args = parser.parse_args(argv)

    git = Git(repo_root(Path.cwd()))
    try:
        if args.command == "pending":
            result = inventory(git)
        else:
            result = commit(git, args.scope, args.type, args.subject, args.body, args.path, args.shared)
    except Refused as exc:
        print(json.dumps({"error": str(exc)}))
        return EXIT_REFUSED
    except GitError as exc:
        print(json.dumps({"error": str(exc)}))
        return EXIT_FAILED
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
