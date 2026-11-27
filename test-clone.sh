#!/usr/bin/env bash
# test-clone.sh — prove `devdeck` and `split4` work straight from a fresh clone:
# clone the repo, put it on PATH, run both commands. No install step involved.
#
# Usage: ./test-clone.sh
# Needs bash, git and tmux 3.0+. Exits non-zero on the first failure.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION="verify-clone-$$"
SPLIT_SESSION="verify-clone-split-$$"
WORK="$(mktemp -d)"
CLONE="$WORK/clone"
PROJ="$WORK/proj"

cleanup() {
    tmux kill-session -t "$SESSION" 2>/dev/null || true
    tmux kill-session -t "$SPLIT_SESSION" 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup EXIT

fail() { echo "test-clone FAILED: $1" >&2; exit 1; }

command -v tmux >/dev/null || fail "tmux not found — install tmux 3.0+ first"
command -v git >/dev/null || fail "git not found"

# 1) A real clone: only tracked files come along, so this also catches a wrapper
#    that exists in the working tree but was never committed.
git clone --quiet "$REPO_DIR" "$CLONE" || fail "could not clone $REPO_DIR"
[ -x "$CLONE/devdeck" ] || fail "devdeck missing or not executable in the clone"
[ -x "$CLONE/split4" ] || fail "split4 missing or not executable in the clone"
echo "OK: clone carries executable devdeck + split4"

# 2) Bare `devdeck`, found through PATH from an unrelated directory.
mkdir -p "$PROJ"
( cd "$WORK" && PATH="$CLONE:$PATH" DEVDECK_SESSION="$SESSION" \
    timeout 10 devdeck "$PROJ" >/dev/null 2>&1 || true )
COUNT="$(tmux list-panes -t "$SESSION" 2>/dev/null | wc -l || true)"
[ "$COUNT" -eq 4 ] || fail "devdeck from the clone made $COUNT panes, expected 4"
echo "OK: devdeck from the clone -> 4 panes"

TITLES="$(tmux list-panes -t "$SESSION" -F '#{pane_title}' 2>/dev/null | sort | tr '\n' ' ' || true)"
[ "$TITLES" = "dev server editor git logs " ] || fail "unexpected pane titles: $TITLES"
echo "OK: pane titles ($TITLES)"

# 3) --kill through the same PATH lookup, naming the project directory.
( cd "$WORK" && PATH="$CLONE:$PATH" DEVDECK_SESSION="$SESSION" devdeck --kill "$PROJ" >/dev/null ) \
    || fail "devdeck --kill returned non-zero"
if tmux has-session -t "$SESSION" 2>/dev/null; then
    fail "session survived devdeck --kill"
fi
echo "OK: devdeck --kill closed the session"

# 4) split4 from the clone. It refuses to run outside tmux, so feed it to a
#    throwaway session's shell the way install.sh does.
tmux new-session -d -s "$SPLIT_SESSION" -x 200 -y 50 >/dev/null
tmux send-keys -t "$SPLIT_SESSION" "export PATH=\"$CLONE:\$PATH\"; split4" Enter
sleep 1.5
COUNT="$(tmux list-panes -t "$SPLIT_SESSION" 2>/dev/null | wc -l || true)"
[ "$COUNT" -eq 4 ] || fail "split4 from the clone made $COUNT panes, expected 4"
echo "OK: split4 from the clone -> 4 panes"

echo "all good — a fresh clone runs both commands with only PATH set"
