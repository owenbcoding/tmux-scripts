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
DIR="${1:-.}"

# Already running? Just attach.
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
fi

cd "$DIR" || exit 1

# Big main pane: your editor (nvim if available, else vim, else bash)
MAIN="bash"
command -v nvim >/dev/null && MAIN="nvim" || command -v vim >/dev/null && MAIN="vim"

tmux new-session -d -s "$SESSION" -n dev -c "$DIR"
tmux send-keys -t "$SESSION:0" "$MAIN" Enter

# Right column: split off ~35%
tmux split-window -h -t "$SESSION:0" -p 35 -c "$DIR"
tmux send-keys -t "$SESSION:0.1" "echo '⚡ dev server — run your start command here'" Enter

# Split right column into three stacked panes
tmux split-window -v -t "$SESSION:0.1" -p 66 -c "$DIR"
tmux split-window -v -t "$SESSION:0.2" -p 50 -c "$DIR"

tmux send-keys -t "$SESSION:0.2" "echo '📜 logs — tail -f your log file here'" Enter
tmux send-keys -t "$SESSION:0.3" "echo '🌿 git: '$(git branch --show-current 2>/dev/null || echo 'not a repo') && git status -s | head -5" Enter

# 50/50 the top two right panes vertically
tmux resize-pane -t "$SESSION:0.1" -y "$(( $(tput lines) * 30 / 100 ))" 2>/dev/null

# Editor pane gets the remaining 65%
tmux select-pane -t "$SESSION:0.0"
tmux resize-pane -t "$SESSION:0.0" -x "$(( $(tput cols) * 65 / 100 ))" 2>/dev/null

# ── Styling ─────────────────────────────────────────────
tmux set-option -t "$SESSION" mouse on
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_index} ● #{pane_title} "
tmux set-option -t "$SESSION" pane-border-style "fg=colour238"
tmux set-option -t "$SESSION" pane-active-border-style "fg=colour51"
tmux set-option -t "$SESSION" status-position top
tmux set-option -t "$SESSION" status-style "bg=colour236,fg=colour250"
tmux set-option -t "$SESSION" status-left "#[bg=colour51,fg=colour235,bold] ⚡ DECK #[default] #[fg=colour51]#S "
tmux set-option -t "$SESSION" status-right "#[fg=colour51]%a %d %b #[fg=colour250]%H:%M "
tmux set-option -t "$SESSION" window-status-current-format "#[fg=colour51,bold]● #W "

# Focus the editor
tmux select-pane -t "$SESSION:0.0"

exec tmux attach -t "$SESSION"