# hacker Vim theme (NOT tokyo)

Custom green-on-black CRT theme. It lives in `vim-theme/` inside this repo
(`owenbcoding/tmux-scripts`), so cloning that clone brings the theme with it and
`./install.sh` sets it as the default colorscheme.

Files:
- `hacker.vim` = the colorscheme (`~/.vim/colors/hacker.vim`)
- `vimrc` = full reference `~/.vimrc`
- `install.sh` = safe installer (backs up `~/.vimrc`, appends theme block only if missing)
- `copy-me.txt` = copy-paste commands

## Install from this clone (no network)

From the repo root:

```bash
bash vim-theme/install.sh
```

`../install.sh` runs that for you, unless you pass `--no-vim-theme`.

Or copy-paste by hand:

```bash
mkdir -p ~/.vim/colors
cp vim-theme/hacker.vim ~/.vim/colors/hacker.vim
grep -q "colorscheme hacker" ~/.vimrc 2>/dev/null || cat vim-theme/vimrc >> ~/.vimrc
```

## One-line install elsewhere

```bash
git clone git@github.com:owenbcoding/tmux-scripts.git ~/code/tmux-scripts
~/code/tmux-scripts/install.sh
```

Nothing is downloaded any more: the theme is part of the repo and installed from
the clone, so no GitHub token is needed.

## Neovim

`~/.vimrc` is Vim's config, not Neovim's. To use the same colorscheme in `nvim`:

```bash
mkdir -p ~/.config/nvim/colors
cp vim-theme/hacker.vim ~/.config/nvim/colors/hacker.vim
echo 'colorscheme hacker' >> ~/.config/nvim/init.vim
```

## Check in Vim

```vim
:colorscheme hacker
:echo g:colors_name
" -> hacker
```
