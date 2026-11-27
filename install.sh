#!/usr/bin/env bash
# install.sh — install devdeck + split4 to ~/.local/bin and verify each one
# actually builds working tmux panes.
#
# Usage:
#   ./install.sh              # install + verify
#   ./install.sh --no-verify  # install only
#   ./install.sh --uninstall  # remove installed binaries
#
# After `git pull` on another machine, just re-run `./install.sh` and both
# commands work the same there.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"
VERIFY=1

for arg in "$@"; do
    case "$arg" in
        --no-verify) VERIFY=0 ;;
        --uninstall)
            rm -f "$PREFIX/devdeck" "$PREFIX/split4"
            echo "uninstalled devdeck + split4 from $PREFIX"
            exit 0
            ;;
        -h|--help)
            sed -n '1,12p' "$0"
            exit 0
            ;;
        *)
            echo "install.sh: unknown option '$arg' (try --help)" >&2
            exit 1
            ;;
    esac
done

# ── Preconditions ──────────────────────────────────────────────
command -v tmux >/dev/null || { echo "install.sh: tmux not found — install tmux 3.0+ first" >&2; exit 1; }
TMUX_VS="$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)"
TMUX_MAJOR="${TMUX_VS%%.*}"
if [ "${TMUX_MAJOR:-0}" -lt 3 ]; then
    echo "install.sh: tmux $TMUX_VS found, 3.0+ required" >&2
    exit 1
fi

mkdir -p "$PREFIX"
install -m 755 "$REPO_DIR/devdeck.sh" "$PREFIX/devdeck"
install -m 755 "$REPO_DIR/split4.sh" "$PREFIX/split4"
echo "installed: $PREFIX/devdeck  $PREFIX/split4"

# Warn (don't fail) if the bin dir isn't on PATH yet.
case ":$PATH:" in
    *":$PREFIX:"*) ;;
    *)
        echo "note: $PREFIX is not on your PATH."
        echo "add this to ~/.bashrc (or ~/.zshrc):"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

if [ "$VERIFY" -eq 0 ]; then
    echo "skip verification (--no-verify)"
    exit 0
fi

# ── Verification: prove each installed script builds working panes ──
fail() { echo "verify FAILED: $1" >&2; exit 1; }

# 1) Syntax check both scripts.
bash -n "$PREFIX/devdeck" || fail "devdeck has a syntax error"
bash -n "$PREFIX/split4" || fail "split4 has a syntax error"

# 2) split4: run it inside a throwaway detached session, expect 4 panes.
tmux kill-session -t verify-split4 2>/dev/null || true
tmux new-session -d -s verify-split4 -x 200 -y 50 >/dev/null
# The script refuses to run outside tmux, so feed it to the session's shell.
tmux send-keys -t verify-split4 "$PREFIX/split4" Enter
sleep 1
SPLIT4_COUNT="$(tmux list-panes -t verify-split4 2>/dev/null | wc -l)"
tmux kill-session -t verify-split4 2>/dev/null || true
[ "$SPLIT4_COUNT" -eq 4 ] || fail "split4 made $SPLIT4_COUNT panes, expected 4"
echo "verify split4: OK (4 panes)"

# 3) devdeck: run it against a temp dir. It ends in `attach`, which fails
# without a terminal — that's fine; the detached session should be left
# behind with 4 panes. Run with a short timeout so the failed attach can't hang us.
# A fixed session name keeps the test independent of the temp dir's basename.
VERIFY_SESSION="verify-devdeck"
tmux kill-session -t "$VERIFY_SESSION" 2>/dev/null || true
TMPDIR_VERIFY="$(mktemp -d)"
if command -v timeout >/dev/null; then
    DEVDECK_SESSION="$VERIFY_SESSION" timeout 10 "$PREFIX/devdeck" "$TMPDIR_VERIFY" >/dev/null 2>&1 || true
else
    DEVDECK_SESSION="$VERIFY_SESSION" "$PREFIX/devdeck" "$TMPDIR_VERIFY" >/dev/null 2>&1 || true
fi
rmdir "$TMPDIR_VERIFY" 2>/dev/null || true
tmux has-session -t "$VERIFY_SESSION" 2>/dev/null || fail "devdeck did not create session '$VERIFY_SESSION'"
DEVDECK_COUNT="$(tmux list-panes -t "$VERIFY_SESSION" 2>/dev/null | wc -l)"
tmux kill-session -t "$VERIFY_SESSION" 2>/dev/null || true
[ "$DEVDECK_COUNT" -eq 4 ] || fail "devdeck made $DEVDECK_COUNT panes, expected 4"
echo "verify devdeck: OK (4 panes, session '$VERIFY_SESSION')"

# 4) devdeck projects get their own sessions: two dirs -> two sessions.
PROJ_A="$(mktemp -d)"; PROJ_B="$(mktemp -d)"
SESS_A="deck-$(basename "$PROJ_A")"; SESS_A="${SESS_A//[!a-zA-Z0-9_-]/-}"
SESS_B="deck-$(basename "$PROJ_B")"; SESS_B="${SESS_B//[!a-zA-Z0-9_-]/-}"
tmux kill-session -t "$SESS_A" 2>/dev/null || true
tmux kill-session -t "$SESS_B" 2>/dev/null || true
if command -v timeout >/dev/null; then
    timeout 10 "$PREFIX/devdeck" "$PROJ_A" >/dev/null 2>&1 || true
    timeout 10 "$PREFIX/devdeck" "$PROJ_B" >/dev/null 2>&1 || true
else
    "$PREFIX/devdeck" "$PROJ_A" >/dev/null 2>&1 || true
    "$PREFIX/devdeck" "$PROJ_B" >/dev/null 2>&1 || true
fi
COUNT_A="$(tmux list-panes -t "$SESS_A" 2>/dev/null | wc -l)"
COUNT_B="$(tmux list-panes -t "$SESS_B" 2>/dev/null | wc -l)"
# --kill resolves the session from the directory, so run it before rmdir.
"$PREFIX/devdeck" --kill "$PROJ_A" >/dev/null 2>&1 || tmux kill-session -t "$SESS_A" 2>/dev/null || true
"$PREFIX/devdeck" --kill "$PROJ_B" >/dev/null 2>&1 || tmux kill-session -t "$SESS_B" 2>/dev/null || true
rmdir "$PROJ_A" "$PROJ_B" 2>/dev/null || true
tmux kill-session -t "$SESS_B" 2>/dev/null || true
([ "$COUNT_A" -eq 4 ] && [ "$COUNT_B" -eq 4 ]) || fail "per-project decks made $COUNT_A/$COUNT_B panes, expected 4/4"
echo "verify devdeck projects: OK (two dirs -> two 4-pane sessions)"

echo "all good — re-run ./install.sh after every git pull."
