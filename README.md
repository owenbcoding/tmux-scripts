# tmux-scripts

Two small bash scripts for tmux:

| Script | What it does |
| ------ | ------------ |
| [`split4.sh`](split4.sh) | Turns the current window into a 2×2 grid of four panes. |
| [`devdeck.sh`](devdeck.sh) | Builds a whole four-zone developer workspace — editor, dev server, logs, git — as its own session. |

Each is a single file. There is no install step, no config, and no dependencies
beyond bash and tmux.

---

## split4.sh

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

The whole script is one file: [`split4.sh`](split4.sh).

### Requirements

- `tmux` (3.0 or newer — the script targets panes by name with `{top-right}` /
  `{top-left}`).
- bash.

### Usage

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

### How it works

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

### Caveats

- **Start from a fresh window.** The script assumes exactly one pane; run it in a
  window that already has panes and you'll get more than four and a lopsided
  layout.
- **Panes inherit the current working directory**, so all four start where you
  ran the script.
- **It only creates panes, changes the layout, and moves focus** — it doesn't
  resize the terminal, detach, or start any programs.
- **Exit status** is `1` outside tmux, otherwise the status of the last tmux
  command.

### Customizing

- Replace `tiled` with `even-horizontal`, `even-vertical`, or `main-vertical` for
  a different arrangement of the same four panes.
- Delete the final `select-pane -t '{top-left}'` line to leave focus wherever it
  was.
- Add more `split-window` calls before `select-layout` for six or more panes;
  `tiled` keeps balancing the grid.

### Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `Not inside a tmux session.` | Start or attach to a tmux session first. |
| `command not found: tmux` | Install tmux, or check it's on the `PATH` of the shell running the script. |
| `unknown pane` / `can't find pane` | tmux is older than 3.0; upgrade it, or replace `{top-right}` / `{top-left}` with pane indexes (`-t 1`, `-t 0`). |
| `Permission denied` | `chmod +x split4.sh`. |
| Layout looks lopsided | You ran it in a window that already had panes; kill them down to one and rerun. |

---

## devdeck.sh

Builds and attaches to its own session, `devdeck`, laid out for a full edit /
run / watch loop:

```
┌───────────────────────┬──────────────┐
│                       │  dev server  │
│                       ├──────────────┤
│       EDITOR          │     logs     │
│   (nvim/vim/bash)     ├──────────────┤
│                       │     git      │
└───────────────────────┴──────────────┘
```

By default the editor takes the left 65% of the window and the right 35% is
three equal rows, and both the ratio and what each pane runs are configurable.
Every pane gets a title, and the border above it shows
`index ● title`, so you can see at a glance which pane is which.

### Usage

```bash
./devdeck.sh              # use the current directory
./devdeck.sh ~/code/app   # open a specific project
./devdeck.sh --kill       # close the devdeck session
```

The directory is resolved to an absolute path before tmux sees it, and the
script exits with status `1` (printing `devdeck: no such directory: …`) if it
doesn't exist.

The session is created detached, sized to the terminal you launched from, and
then attached. If a `devdeck` session already exists the script just goes to it
— switching the current client when you're already inside tmux instead of trying
to nest one — and ignores the directory argument.

`--kill` closes the session, which is handy from a key binding, and exits with
status `1` if there's nothing to close.

### Requirements

- tmux 3.0 or newer (`pane-border-status`, pane titles, `switch-client`).
- bash, plus `nvim` or `vim` for the main pane — without either it falls back to
  bash.

### Configuration

On startup the script sources a config file if one exists: `$DEVDECK_CONFIG`,
otherwise `${XDG_CONFIG_HOME:-~/.config}/devdeck/config`. It's plain bash, so
it can run anything bash can, but these are the variables it looks for:

```bash
# ~/.config/devdeck/config
EDITOR_WIDTH=60             # percent of the window, 1-99 (default: 65)
EDITOR_CMD="nvim ."         # default: nvim, else vim, else bash
SERVER_CMD="npm run dev"    # default: a one-line hint in the pane
LOGS_CMD="tail -f dev.log"  # default: a one-line hint in the pane
GIT_CMD="git status -sb"    # default: branch name + short status
```

Each `*_CMD` is sent to its pane and run there, so it can be any shell command;
leave `EDITOR_CMD` empty to keep the automatic nvim → vim → bash choice. The
config is read after the script moves into the project directory, so relative
paths like `dev.log` point at the project. With no config file at all, the
layout and commands match the diagram.

### How it works

| Step | Command | Result |
| ---- | ------- | ------ |
| 1 | `new-session -d … -x COLS -y LINES` | detached session at your terminal's size, main pane is the editor |
| 2 | `split-window -h -p 100-EDITOR_WIDTH` | right column, the rest of the width |
| 3 | `split-window -v -p 66` | dev server on top, 66% left below it |
| 4 | `split-window -v -p 50` | that remainder becomes the logs and git panes |
| 5 | `resize-pane -x` (EDITOR_WIDTH% of window) | pins the editor to its width, 65 by default |
| 6 | `select-pane -T` + `set-option -w` | pane titles and border styling |
| 7 | `attach` / `switch-client` | hands you the session |

Two details matter for the layout to land where the diagram says:

- **The session is created at your terminal's size.** Detached sessions default
  to 80×24, so percentage splits computed from one size and applied to another
  produce lopsided panes once you attach.
- **Panes are tracked by id** (`-P -F '#{pane_id}'`), not by index, so a
  `pane-base-index` or `base-index` setting in your tmux config can't move the
  targets out from under the script.

### Notes

- By default the right-hand panes print a one-line hint; set `SERVER_CMD`,
  `LOGS_CMD` and `GIT_CMD` in the config to run your own commands instead.
- Styling (mouse mode, top status bar, borders, yellow accents) is applied to
  this session and window only — your other sessions are untouched.
- The editor is chosen at launch. Panes you open later get whatever your shell
  starts.
- tmux shares space added by a terminal resize evenly between panes rather than
  scaling the 65/35 split, so a much wider window drifts from the diagram; drag
  the border to put it back.
- Re-running attaches to the existing session, so it won't re-tile a layout you
  have since rearranged.

### Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `devdeck: no such directory` | Pass a path that exists; it's resolved before tmux starts. |
| `devdeck: editor width must be…` | `EDITOR_WIDTH` in the config isn't a whole number from 1 to 99. |
| `devdeck: no session 'devdeck' to close` | Nothing was running; `--kill` is a no-op with status 1. |
| `command not found: tmux` | Install tmux, or check it's on the `PATH` of the shell running the script. |
| Borders show `0 ● hostname` | tmux older than 3.0, where `select-pane -T` doesn't set titles; upgrade, or drop the `pane-border-status` lines. |
| `●` or the emoji render as boxes | Use a UTF-8 terminal and a font that has those glyphs. |
| Right column feels cramped | It's fixed at 35%; widen the terminal, or drag the border with the mouse (mouse mode is on). |
| `Permission denied` | `chmod +x devdeck.sh`. |
