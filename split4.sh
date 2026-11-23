#!/usr/bin/env bash
# tmux4 — split current tmux window into a 2x2 grid of 4 panes

if [ -z "$TMUX" ]; then
    echo "Not inside a tmux session. Start tmux first."
    exit 1
fi

tmux split-window -h
tmux split-window -v
tmux select-pane -t '{top-right}'
tmux split-window -v
tmux select-layout tiled
tmux select-pane -t '{top-left}'
