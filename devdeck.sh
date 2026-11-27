#!/usr/bin/env bash
# devdeck — a beautiful 4-zone developer terminal layout
# Usage: devdeck [project_dir]
#        devdeck --kill [project_dir]
#   Creates a tmux session "deck-<project>" (one per project directory) with:
#   ┌───────────────────────┬──────────────┐
#   │                       │  dev server  │
#   │       EDITOR          ├──────────────┤
#   │    (vim/nvim/etc)     │    logs      │
#   │                       ├──────────────┤
#   │                       │  git / htop  │
#   └───────────────────────┴──────────────┘
#
# Config: $DEVDECK_CONFIG, or ${XDG_CONFIG_HOME:-~/.config}/devdeck/config,
# is sourced if it exists. See the README for the variables it can set.

CONFIG="${DEVDECK_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/devdeck/config}"

# --kill closes the deck instead of opening it. An optional directory picks
# which project's deck to close (default: the current directory).
KILL=0
if [ "${1:-}" = "--kill" ]; then
    KILL=1
    shift
fi

# Resolve to an absolute path before tmux sees it: -c is resolved against the
# tmux server's cwd, not this shell's, so a relative path would silently point
# at a directory that isn't there.
cd "${1:-.}" 2>/dev/null || { echo "devdeck: no such directory: ${1:-.}" >&2; exit 1; }
DIR="$(pwd)"

# One session per project, so `devdeck ~/proj-a` and `devdeck ~/proj-b` give
# you two decks instead of fighting over one. tmux forbids '.' and ':' in
# session names, so sanitise the directory basename. DEVDECK_SESSION overrides
# the name entirely (used by tests and anyone who wants a custom name).
if [ -n "${DEVDECK_SESSION:-}" ]; then
    SESSION="$DEVDECK_SESSION"
else
    SAFE="$(basename "$DIR")"
    SAFE="${SAFE//[!a-zA-Z0-9_-]/-}"
    if [ -z "$SAFE" ]; then
        SESSION="devdeck"
    else
        SESSION="deck-$SAFE"
    fi
fi

# Go to the session. From inside tmux, attaching would try to nest a client,
# so switch the current one instead.
attach() {
    if [ -n "${TMUX:-}" ]; then
        exec tmux switch-client -t "$SESSION"
    fi
    exec tmux attach -t "$SESSION"
}

if [ "$KILL" -eq 1 ]; then
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux kill-session -t "$SESSION" || {
            echo "devdeck: could not close session '$SESSION'" >&2
            exit 1
        }
        echo "devdeck: closed session '$SESSION'"
        exit 0
    fi
    echo "devdeck: no session '$SESSION' to close" >&2
    exit 1
fi

# This project's deck is already running? Just go to it (and ignore anything
# else on the command line — the panes and their commands are already up).
if tmux has-session -t "$SESSION" 2>/dev/null; then
    attach
fi

# Defaults. Anything here can be overridden from the config file; the git line
# is built after cd so it describes this project, not the caller's directory.
EDITOR_WIDTH=65
EDITOR_CMD=""   # empty: first of nvim, vim, bash that exists
SERVER_CMD="echo '⚡ dev server — run your start command here'"
LOGS_CMD="echo '📜 logs — tail -f your log file here'"
GIT_CMD="echo '🌿 git: '$(git branch --show-current 2>/dev/null || echo 'not a repo') && git status -s | head -5"

if [ -r "$CONFIG" ]; then
    # shellcheck disable=SC1090
    . "$CONFIG"
fi

# The width drives the split, so reject anything that can't be a percentage.
case "$EDITOR_WIDTH" in
    ''|*[!0-9]*)
        echo "devdeck: editor width must be a number from 1 to 99 (got '$EDITOR_WIDTH')" >&2
        exit 1
        ;;
esac
if [ "$EDITOR_WIDTH" -lt 1 ] || [ "$EDITOR_WIDTH" -gt 99 ]; then
    echo "devdeck: editor width must be from 1 to 99 (got $EDITOR_WIDTH)" >&2
    exit 1
fi

# Main pane: your editor (nvim if available, else vim, else bash)
if [ -z "$EDITOR_CMD" ]; then
    EDITOR_CMD="bash"
    command -v nvim >/dev/null && EDITOR_CMD="nvim" || command -v vim >/dev/null && EDITOR_CMD="vim"
fi

# Size the detached session like the terminal we launched from. tmux otherwise
# creates it at 80x24, and the percentage splits below would be computed from
# one size and applied to another.
COLS="$(tput cols 2>/dev/null || true)"
LINES="$(tput lines 2>/dev/null || true)"

# tput falls back to terminfo's 80x24 whenever stdout isn't a terminal, so when
# we're already inside tmux ask it for the window we're running in instead.
if [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ]; then
    COLS="$(tmux display -p -t "$TMUX_PANE" '#{window_width}' 2>/dev/null || echo "${COLS:-80}")"
    LINES="$(tmux display -p -t "$TMUX_PANE" '#{window_height}' 2>/dev/null || echo "${LINES:-24}")"
fi
COLS="${COLS:-80}"
LINES="${LINES:-24}"

# Track panes by id rather than index: pane-base-index / base-index in a user's
# config would otherwise move every :0.N target out from under us.
PANE_EDITOR="$(tmux new-session -d -s "$SESSION" -n dev -c "$DIR" -x "$COLS" -y "$LINES" -P -F '#{pane_id}')"
WINDOW="$(tmux display -p -t "$PANE_EDITOR" '#{window_id}')"
tmux send-keys -t "$PANE_EDITOR" "$EDITOR_CMD" Enter

# Note: this tmux (3.4) accepts split-window -l but not -p, so no sizes are
# passed here. The widths are set by the main-vertical layout call below.

# Right column: split off the remainder of the width
PANE_SERVER="$(tmux split-window -h -t "$PANE_EDITOR" -c "$DIR" -P -F '#{pane_id}')"

# Split the right column into three stacked panes: server on top, then logs and
# git below. main-vertical evens them out afterwards.
PANE_LOGS="$(tmux split-window -v -t "$PANE_SERVER" -c "$DIR" -P -F '#{pane_id}')"
PANE_GIT="$(tmux split-window -v -t "$PANE_LOGS" -c "$DIR" -P -F '#{pane_id}')"

tmux select-pane -t "$PANE_SERVER" -T "dev server"
tmux select-pane -t "$PANE_LOGS" -T "logs"
tmux select-pane -t "$PANE_GIT" -T "git"
tmux select-pane -t "$PANE_EDITOR" -T "editor"

tmux send-keys -t "$PANE_SERVER" "$SERVER_CMD" Enter
tmux send-keys -t "$PANE_LOGS" "$LOGS_CMD" Enter
tmux send-keys -t "$PANE_GIT" "$GIT_CMD" Enter

# Editor keeps EDITOR_WIDTH of the width; the right column shares the height.
# select-layout overrides any split sizes, so this is the only place the ratio
# is applied.
tmux set-option -w -t "$WINDOW" main-pane-width "${EDITOR_WIDTH}%"
tmux select-layout -t "$WINDOW" main-vertical

# ── Styling ─────────────────────────────────────────────
tmux set-option -w -t "$WINDOW" pane-border-status top
tmux set-option -w -t "$WINDOW" pane-border-format " #{pane_index} ● #{pane_title} "
tmux set-option -w -t "$WINDOW" pane-border-style "fg=colour238"
tmux set-option -w -t "$WINDOW" pane-active-border-style "fg=colour51"
tmux set-option -t "$SESSION" mouse on
tmux set-option -t "$SESSION" status-position top
tmux set-option -t "$SESSION" status-style "bg=colour236,fg=colour250"
tmux set-option -t "$SESSION" status-left "#[bg=colour51,fg=colour235,bold] ⚡ DECK #[default] #[fg=colour51]#S "
tmux set-option -t "$SESSION" status-right "#[fg=colour51]%a %d %b #[fg=colour250]%H:%M "
tmux set-option -t "$SESSION" window-status-current-format "#[fg=colour51,bold]● #W "

# Focus the editor
tmux select-pane -t "$PANE_EDITOR"

attach
