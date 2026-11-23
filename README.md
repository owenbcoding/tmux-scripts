# split4.sh

A tiny bash script that turns one tmux pane into a 2×2 grid of four panes, with
the cursor left in the top-left one.

```
┌───────────┬───────────┐
│           │           │
│  top-left │ top-right │   <- cursor ends here
│           │           │
├───────────┼───────────┤
│           │           │
│ bot-left  │ bot-right │
│           │           │
└───────────┴───────────┘
```

The whole project is one file: [`split4.sh`](split4.sh). There is no install
step, no config, and no dependencies beyond bash and tmux.

## Requirements

- `tmux` (3.0 or newer — the script targets panes by name with `{top-right}` /
  `{top-left}`).
- bash.

## Usage

Run it from a shell **inside** a tmux session:

```bash
./split4.sh
```

Then start a session if you don't have one, and run it from a pane in that
session:

```bash
tmux new -s work
./split4.sh
```

Running it outside tmux prints `Not inside a tmux session. Start tmux first.`
and exits with status 1, since tmux commands only reach the server you're
attached to.

If you get `Permission denied`, run `chmod +x split4.sh` once.

### Optional shortcut

Bind it to a key in `~/.tmux.conf` and reload the config:

```tmux
bind 4 run-shell "/full/path/to/split4.sh"
```

## How it works

tmux has no single "make a 2×2 grid" command, so the script builds it in steps.
Each `split-window` makes the new pane active: `-h` splits side by side and `-v`
splits top/bottom.

| Step | Command | Result |
| ---- | ------- | ------ |
| 1 | `tmux split-window -h` | left and right, right is active |
| 2 | `tmux split-window -v` | splits the right pane: one tall left pane, two on the right |
| 3 | `tmux select-pane -t '{top-right}'` | focus moves to the top-right pane |
| 4 | `tmux split-window -v` | four panes total |
| 5 | `tmux select-layout tiled` | rebalances all four into an even 2×2 grid |
| 6 | `tmux select-pane -t '{top-left}'` | focus lands in the top-left pane |

Step 5 is doing the real work: steps 1–4 only create four panes, and
`select-layout tiled` is what turns them into a clean grid. Step 6 just decides
where you start typing.

## Caveats

- **Start from a fresh window.** The script assumes exactly one pane; run it in a
  window that already has panes and you'll get more than four and a lopsided
  layout.
- **Panes inherit the current working directory**, so all four start where you
  ran the script.
- **It only creates panes, changes the layout, and moves focus** — it doesn't
  resize the terminal, detach, or start any programs.
- **Exit status** is `1` outside tmux, otherwise the status of the last tmux
  command.

## Customizing

- Replace `tiled` with `even-horizontal`, `even-vertical`, or `main-vertical` for
  a different arrangement of the same four panes.
- Delete the final `select-pane -t '{top-left}'` line to leave focus wherever it
  was.
- Add more `split-window` calls before `select-layout` for six or more panes;
  `tiled` keeps balancing the grid.

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `Not inside a tmux session.` | Start or attach to a tmux session first. |
| `command not found: tmux` | Install tmux, or check it's on the `PATH` of the shell running the script. |
| `unknown pane` / `can't find pane` | tmux is older than 3.0; upgrade it, or replace `{top-right}` / `{top-left}` with pane indexes (`-t 1`, `-t 0`). |
| `Permission denied` | `chmod +x split4.sh`. |
| Layout looks lopsided | You ran it in a window that already had panes; kill them down to one and rerun. |
