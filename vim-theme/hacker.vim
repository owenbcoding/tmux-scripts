" hacker.vim - green-on-black CRT theme for Vim
" A self-contained colorscheme: no plugins, no external dependencies.
" Works with 256-color terminals and true-color terminals alike.

hi clear
if exists('syntax_on')
  syntax reset
endif

set background=dark
let g:colors_name = 'hacker'

" ---------- palette ----------
" bg        #0a0f0a   near-black with a green cast
" bg alt    #101a12   cursorline / popups
" fg        #c7f9cc   soft phosphor white-green
" dim       #4f7a5a   comments, punctuation
" green     #00ff9c   keywords, accents
" lime      #9cff57   functions
" amber     #ffcc66   constants, numbers, warnings
" cyan      #6cf0ff   types, specials
" red       #ff5f5f   errors

" ---------- editor chrome ----------
hi Normal        guifg=#c7f9cc guibg=#0a0f0a ctermfg=194 ctermbg=232
hi Cursor        guifg=#0a0f0a guibg=#00ff9c ctermfg=232 ctermbg=47
hi lCursor       guifg=#0a0f0a guibg=#00ff9c ctermfg=232 ctermbg=47
hi CursorLine    guibg=#101a12              ctermbg=233
hi CursorColumn  guibg=#101a12              ctermbg=233
hi CursorLineNr  guifg=#00ff9c guibg=#101a12 ctermfg=47 ctermbg=233 cterm=bold gui=bold
hi LineNr        guifg=#2f5c3c              ctermfg=22
hi SignColumn    guifg=#2f5c3c guibg=#0a0f0a ctermfg=22 ctermbg=232
hi ColorColumn   guibg=#101a12              ctermbg=233
hi VertSplit     guifg=#1f3a28 guibg=#0a0f0a ctermfg=22 ctermbg=232
hi WinSeparator  guifg=#1f3a28 guibg=#0a0f0a ctermfg=22 ctermbg=232
hi Folded        guifg=#4f7a5a guibg=#101a12 ctermfg=65 ctermbg=233 cterm=NONE gui=NONE term=NONE
hi FoldColumn    guifg=#2f5c3c guibg=#0a0f0a ctermfg=22 ctermbg=232
hi NonText       guifg=#1f3a28              ctermfg=22
hi EndOfBuffer   guifg=#0a0f0a              ctermfg=232
hi SpecialKey    guifg=#2f5c3c              ctermfg=22
hi Whitespace    guifg=#1f3a28              ctermfg=22
hi Conceal       guifg=#4f7a5a guibg=#0a0f0a ctermfg=65 ctermbg=232

" ---------- statusline / tabs / popups ----------
hi StatusLine    guifg=#0a0f0a guibg=#00ff9c ctermfg=232 ctermbg=47 cterm=bold gui=bold
hi StatusLineNC  guifg=#4f7a5a guibg=#101a12 ctermfg=65 ctermbg=233
hi HackerBanner  guifg=#00ff9c guibg=#0a0f0a ctermfg=47 ctermbg=232 cterm=bold gui=bold
hi HackerBannerFill guifg=#1f3a28 guibg=#0a0f0a ctermfg=22 ctermbg=232
hi TabLine       guifg=#4f7a5a guibg=#0a0f0a ctermfg=65 ctermbg=232
hi TabLineFill   guifg=#0a0f0a guibg=#0a0f0a ctermfg=232 ctermbg=232
hi TabLineSel    guifg=#0a0f0a guibg=#00ff9c ctermfg=232 ctermbg=47 cterm=bold gui=bold
hi Pmenu         guifg=#c7f9cc guibg=#101a12 ctermfg=194 ctermbg=233
hi PmenuSel      guifg=#0a0f0a guibg=#00ff9c ctermfg=232 ctermbg=47 cterm=bold gui=bold
hi PmenuSbar     guibg=#101a12              ctermbg=233
hi PmenuThumb    guibg=#2f5c3c              ctermbg=22
hi WildMenu      guifg=#0a0f0a guibg=#00ff9c ctermfg=232 ctermbg=47 cterm=bold gui=bold

" ---------- search / selection ----------
hi Search        guifg=#0a0f0a guibg=#00ff9c ctermfg=232 ctermbg=47
hi IncSearch     guifg=#0a0f0a guibg=#ffcc66 ctermfg=232 ctermbg=221 cterm=bold gui=bold
hi CurSearch     guifg=#0a0f0a guibg=#9cff57 ctermfg=232 ctermbg=155 cterm=bold gui=bold
hi Visual        guifg=NONE guibg=#10421f ctermfg=NONE ctermbg=22 cterm=NONE gui=NONE term=NONE
hi VisualNOS     guifg=NONE guibg=#10421f ctermfg=NONE ctermbg=22 cterm=NONE gui=NONE term=NONE
hi MatchParen    guifg=#ffcc66 guibg=#101a12 ctermfg=221 ctermbg=233 cterm=bold,underline gui=bold,underline

" ---------- messages ----------
hi ErrorMsg      guifg=#ff5f5f              ctermfg=203 cterm=bold gui=bold
hi WarningMsg    guifg=#ffcc66              ctermfg=221
hi MoreMsg       guifg=#7ee787              ctermfg=114
hi Question      guifg=#6cf0ff              ctermfg=81
hi ModeMsg       guifg=#00ff9c              ctermfg=47 cterm=bold gui=bold
hi Directory     guifg=#6cf0ff              ctermfg=81 cterm=bold gui=bold
hi Title         guifg=#00ff9c              ctermfg=47 cterm=bold gui=bold
hi Error         guifg=#ff5f5f              ctermfg=203

" ---------- diff / vcs ----------
hi DiffAdd       guifg=#9cff57 guibg=#0d2a14 ctermfg=155 ctermbg=22
hi DiffChange    guifg=#ffcc66 guibg=#2a2410 ctermfg=221 ctermbg=52
hi DiffDelete    guifg=#ff5f5f guibg=#2a0d0d ctermfg=203 ctermbg=52
hi DiffText      guifg=#0a0f0a guibg=#ffcc66 ctermfg=232 ctermbg=221 cterm=bold gui=bold
hi diffAdded     guifg=#9cff57 ctermfg=155
hi diffRemoved   guifg=#ff5f5f ctermfg=203
hi diffChanged   guifg=#ffcc66 ctermfg=221
hi diffFile      guifg=#6cf0ff ctermfg=81
hi diffLine      guifg=#4f7a5a ctermfg=65

" ---------- syntax ----------
hi Comment       guifg=#4f7a5a ctermfg=65 cterm=italic gui=italic

hi Constant      guifg=#ffcc66 ctermfg=221
hi String        guifg=#7ee787 ctermfg=114
hi Character     guifg=#7ee787 ctermfg=114
hi Number        guifg=#ffcc66 ctermfg=221
hi Float         guifg=#ffcc66 ctermfg=221
hi Boolean       guifg=#ffcc66 ctermfg=221 cterm=bold gui=bold

hi Identifier    guifg=#d4ffd8 ctermfg=194
hi Function      guifg=#9cff57 ctermfg=155 cterm=bold gui=bold

hi Statement     guifg=#00ff9c ctermfg=47 cterm=bold gui=bold
hi Conditional   guifg=#00ff9c ctermfg=47 cterm=bold gui=bold
hi Repeat        guifg=#00ff9c ctermfg=47 cterm=bold gui=bold
hi Label         guifg=#00ff9c ctermfg=47 cterm=bold gui=bold
hi Operator      guifg=#6cf0ff ctermfg=81
hi Keyword       guifg=#00ff9c ctermfg=47 cterm=bold gui=bold
hi Exception     guifg=#ff5f5f ctermfg=203 cterm=bold gui=bold

hi PreProc       guifg=#6cf0ff ctermfg=81
hi Include       guifg=#6cf0ff ctermfg=81
hi Define        guifg=#6cf0ff ctermfg=81
hi Macro         guifg=#6cf0ff ctermfg=81
hi PreCondit     guifg=#6cf0ff ctermfg=81

hi Type          guifg=#5fffd7 ctermfg=86 cterm=bold gui=bold
hi StorageClass  guifg=#5fffd7 ctermfg=86
hi Structure     guifg=#5fffd7 ctermfg=86
hi Typedef       guifg=#5fffd7 ctermfg=86

hi Special       guifg=#6cf0ff ctermfg=81
hi SpecialChar   guifg=#6cf0ff ctermfg=81
hi Tag           guifg=#9cff57 ctermfg=155
hi Delimiter     guifg=#4f7a5a ctermfg=65
hi SpecialComment guifg=#6cf0ff ctermfg=81 cterm=italic gui=italic
hi Debug         guifg=#ff5f5f ctermfg=203

hi Underlined    guifg=#6cf0ff ctermfg=81 cterm=underline gui=underline
hi Ignore        guifg=#0a0f0a ctermfg=232
hi Todo          guifg=#0a0f0a guibg=#ffcc66 ctermfg=232 ctermbg=221 cterm=bold gui=bold

" ---------- spell / diagnostics ----------
hi SpellBad      guisp=#ff5f5f ctermfg=203 cterm=undercurl gui=undercurl
hi SpellCap      guisp=#ffcc66 ctermfg=221 cterm=undercurl gui=undercurl
hi SpellRare     guisp=#6cf0ff ctermfg=81 cterm=undercurl gui=undercurl
hi SpellLocal    guisp=#00ff9c ctermfg=47 cterm=undercurl gui=undercurl
hi DiagnosticError guifg=#ff5f5f ctermfg=203
hi DiagnosticWarn  guifg=#ffcc66 ctermfg=221
hi DiagnosticInfo  guifg=#6cf0ff ctermfg=81
hi DiagnosticHint  guifg=#4f7a5a ctermfg=65

" ---------- common links ----------
hi! link QuickFixLine Search
hi! link qfLineNr LineNr
hi! link StatusLineTerm StatusLine
hi! link StatusLineTermNC StatusLineNC
hi! link Terminal Normal
hi! link NormalFloat Pmenu
hi! link FloatBorder VertSplit
hi! link FloatTitle Title
hi! link htmlTag Tag
hi! link htmlEndTag Tag
hi! link markdownH1 Title
hi! link markdownH2 Title
hi! link markdownH3 Title
