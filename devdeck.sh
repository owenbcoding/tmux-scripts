#!/usr/bin/env bash
# devdeck — a beautiful 4-zone developer terminal layout
# Usage: devdeck [project_dir]
#   Creates a tmux session "devdeck" with:
#   ┌───────────────────────┬──────────────┐
#   │                       │  dev server  │
#   │       EDITOR          ├──────────────┤
#   │    (vim/nvim/etc)     │    logs      │
#   │                       ├──────────────┤
#   │                       │  git / htop  │
#   └───────────────────────┴──────────────┘

SESSION="devdeck"

# Go to the session. From inside tmux, attaching would try to nest a client,
# so switch the current one instead.
attach() {
    if [ -n "${TMUX:-}" ]; then
        exec tmux switch-client -t "$SESSION"
    fi
    exec tmux attach -t "$SESSION"
}

# Already running? Just go to it.
if tmux has-session -t "$SESSION" 2>/dev/null; then
    attach
fi

# Resolve to an absolute path before tmux sees it: -c is resolved against the
# tmux server's cwd, not this shell's, so a relative path would silently point
# at a directory that isn't there.
cd "${1:-.}" 2>/dev/null || { echo "devdeck: no such directory: ${1:-.}" >&2; exit 1; }
DIR="$(pwd)"

# Size the detached session like the terminal we launched from. tmux otherwise
# creates it at 80x24, and the percentage splits below would be computed from
# one size and applied to another.
COLS="$(tput cols 2>/dev/null || echo 80)"
LINES="$(tput lines 2>/dev/null || echo 24)"

# Big main pane: your editor (nvim if available, else vim, else bash)
MAIN="bash"
command -v nvim >/dev/null && MAIN="nvim" || command -v vim >/dev/null && MAIN="vim"

# Track panes by id rather than index: pane-base-index / base-index in a user's
# config would otherwise move every :0.N target out from under us.
PANE_EDITOR="$(tmux new-session -d -s "$SESSION" -n dev -c "$DIR" -x "$COLS" -y "$LINES" -P -F '#{pane_id}')"
WINDOW="$(tmux display -p -t "$PANE_EDITOR" '#{window_id}')"
tmux send-keys -t "$PANE_EDITOR" "$MAIN" Enter

# Right column: split off ~35%
PANE_SERVER="$(tmux split-window -h -t "$PANE_EDITOR" -p 35 -c "$DIR" -P -F '#{pane_id}')"

# Split the right column into three equal stacked panes: server on top, then
# logs and git below.
PANE_LOGS="$(tmux split-window -v -t "$PANE_SERVER" -p 66 -c "$DIR" -P -F '#{pane_id}')"
PANE_GIT="$(tmux split-window -v -t "$PANE_LOGS" -p 50 -c "$DIR" -P -F '#{pane_id}')"

tmux select-pane -t "$PANE_SERVER" -T "dev server"
tmux select-pane -t "$PANE_LOGS" -T "logs"
tmux select-pane -t "$PANE_GIT" -T "git"
tmux select-pane -t "$PANE_EDITOR" -T "editor"

tmux send-keys -t "$PANE_SERVER" "echo '⚡ dev server — run your start command here'" Enter
tmux send-keys -t "$PANE_LOGS" "echo '📜 logs — tail -f your log file here'" Enter
tmux send-keys -t "$PANE_GIT" "echo '🌿 git: '$(git branch --show-current 2>/dev/null || echo 'not a repo') && git status -s | head -5" Enter

# Editor pane keeps 65% of the width; the right column shares the height.
WIDTH="$(tmux display -p -t "$WINDOW" '#{window_width}')"
tmux resize-pane -t "$PANE_EDITOR" -x "$(( WIDTH * 65 / 100 ))"

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
