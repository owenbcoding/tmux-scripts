#!/usr/bin/env bash
# Install the custom `hacker` Vim theme (NOT tokyonight).
# Copies hacker.vim from this folder, so a plain clone installs with no network.
# Safe to re-run: backs up ~/.vimrc, never wipes it.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLOR_DIR="$HOME/.vim/colors"
TARGET="$COLOR_DIR/hacker.vim"
VIMRC="$HOME/.vimrc"

mkdir -p "$COLOR_DIR"

echo "-> copying hacker.vim -> $TARGET"
cp "$HERE/hacker.vim" "$TARGET"

# backup existing vimrc once
if [ -f "$VIMRC" ] && ! grep -q "colorscheme hacker" "$VIMRC" 2>/dev/null; then
  cp "$VIMRC" "$VIMRC.bak.$(date +%Y%m%d-%H%M%S)"
  echo "-> backed up $VIMRC"
fi

# ensure theme block exists (append only if missing)
if ! grep -q "colorscheme hacker" "$VIMRC" 2>/dev/null; then
  cat >> "$VIMRC" <<'VIMEOF'

" --- hacker theme (green-on-black CRT look) ---
syntax on
set background=dark
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
  set termguicolors
endif
colorscheme hacker
VIMEOF
  echo "-> appended hacker block to $VIMRC"
else
  echo "-> $VIMRC already enables hacker"
fi

# verify (headless, no plugins)
if ! command -v vim >/dev/null 2>&1; then
  echo "OK: hacker installed ($TARGET); vim not found, so nothing verified"
elif vim -Nu "$VIMRC" -es -S /dev/stdin >/dev/null 2>&1 <<'VIMTEST'
set nomore
if get(g:, 'colors_name', '') !=# 'hacker'
  cquit 1
endif
qa!
VIMTEST
then
  echo "OK: hacker installed ($TARGET) and colors_name=hacker"
else
  echo "WARNING: installed but vim did not report g:colors_name=hacker" >&2
  echo "Run: vim -c 'colorscheme hacker' -c 'echo g:colors_name'" >&2
fi
