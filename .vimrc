" Nvim Compatibility {{{
if has('nvim')
    set runtimepath^=~/.vim runtimepath+=~/.vim/after
    let &packpath = &runtimepath
endif
" }}}

" Install vim-plug {{{
" If there is not plug.vim, install it and install plugins
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ http//raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" }}}

" Install and Load Plugs {{{
" force use ssh to download plugs
let g:plug_url_format = 'git@github.com:%s.git'
call plug#begin('~/.vim/plugged')
    " Some file commands like rename
    Plug 'tpope/vim-eunuch'
    " Some operations text object
    Plug 'wellle/targets.vim'
    " Text alignment
    Plug 'godlygeek/tabular'
    " fuzzy finder
    Plug 'ctrlpvim/ctrlp.vim'
    " Tree explorer
    Plug 'scrooloose/nerdtree'
    " Comment
    Plug 'scrooloose/nerdcommenter'
    " LSP
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    " Indent guides
    Plug 'nathanaelkane/vim-indent-guides'
    " Statusline
    Plug 'itchyny/lightline.vim'
    " JuliaLang
    Plug 'JuliaEditorSupport/julia-vim'
    " Brackets pair colorizer
    Plug 'luochen1990/rainbow'
    " Color scheme
    Plug 'rakr/vim-one'
    " wakaTime
    Plug 'wakatime/vim-wakatime'
    " vim-sneak
    Plug 'justinmk/vim-sneak'
    " zinit highlight
    Plug 'zdharma-continuum/zinit-vim-syntax'
    " Github Copilot
    if has('nvim-0.6')
        Plug 'github/copilot.vim'
    endif
    " Custom plugs
    if filereadable($HOME . "/.vim/custom/plugs.vim")
        source ~/.vim/custom/plugs.vim
    endif
call plug#end()

" Install missing plugs {{{
" install missing plugs should before any plug config
function s:install_missing_plugs()
    if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
        PlugInstall --sync | q
    endif
endfunction

augroup AutoPlugInstall
    autocmd!
    autocmd VimEnter * call s:install_missing_plugs()
augroup END
" }}}

" }}}

" Vim config {{{

" Leader {{{
if filereadable($HOME . "/.vim/custom/leader.vim")
    source ~/.vim/custom/leader.vim
endif
if !exists("mapleader")
    let mapleader=","
endif
if !exists("maplocalleader")
    let maplocalleader=";"
endif
" }}}

" misc {{{
" filetype
filetype indent plugin on

" line number config
set number
set relativenumber

" confirm when quit
set confirm

" show match
set showmatch

" show cmd
set showcmd

" file encoding
set encoding=utf-8

" highlight search
set hlsearch
set incsearch
nohlsearch " don't highlight last search after load this file

" Split flavor
set splitbelow
set splitright

" allow backspace in insert mode
set backspace=indent,eol,start

" enhance command-line completion
set wildmenu

" highlight current line
set cursorline

" keep 3 lines above and below the cursor
set scrolloff=3

" disable error bell
set noerrorbells

" check modeline
set modelines=1

" always show tab line
set showtabline=2

" status line
if has('nvim-0.7')
    " always show a global status line, requir nvim-0.7
    set laststatus=3
else
    " always show status line
    set laststatus=2
endif

" disable backup, required by coc.nvim
set nobackup
set nowritebackup

" shorter update time to aviod noticeable delay
set updatetime=300

" don't give ins-completion-menu messages, required by coc.nvim
set shortmess+=c

if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" tex flavor
let g:tex_flavor = "latex"
" }}}

" Syntax highlight & Colors {{{

" use gui color
if !($TERM_PROGRAM =~ "Apple_Terminal")
    set termguicolors
endif

" syntax highlight
syntax enable

" colorscheme
if !($TERM_PROGRAM =~ "Apple_Terminal")
    colorscheme one
endif

" italic comments
let &t_ZH="\e[3m"
let &t_ZR="\e[23m"
highlight Comment cterm=italic
let g:one_allow_italics = 1 " for vim-one

" set background color {{{
" add a lock for SetBackground to aviod recursive call
" if we send a SIGWINCH signal to nvim inside of SetBackground
let s:set_background_lock = 0
function! SetBackground(...)
    let init = get(a:, 1, 0) " init only the argument is given
    if has('mac') && !s:set_background_lock
        let s:set_background_lock = 1
        if system('defaults read -g AppleInterfaceStyle') =~ "Dark"
            " don't change background if already set or not init
            if &background != 'dark' || !init
                doautocmd User BackGroundDark
            endif
        elseif &background != 'light' || !init " the same for dark
            doautocmd User BackGroundLight
        endif
        let s:set_background_lock = 0
    endif
endfunction
" if SIGWINCH is supported, trigger it when receive a SIGWINCH signal
" otherwise, it's needed to call SetBackground manually
if has('nvim-0.7') && $TERM_PROGRAM =~ "iTerm.app"
    augroup AutoSetBackground
        autocmd!
        autocmd Signal SIGWINCH call SetBackground()
    augroup END
endif
" }}}

" }}}

" Indent config{{{
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
" }}}

" custom commands {{{
" disable highlight for search
nnoremap <silent> <leader>n :nohlsearch<CR>

" Remove all tariling blanks
nnoremap <silent> <leader>tb :%s/[ \t]\+$//<CR>

" Indent guides toggle
nnoremap <silent> <leader>ti :IndentGuidesToggle<CR>

" highlight all matches of current word
nnoremap <silent> <leader>hw :exec 'match Search /\V\<' . expand('<cword>') . '\>/'<CR>
nnoremap <silent> <leader>ha :exec 'match Search /\V' . expand('<cWORD>') . '/'<CR>

" replace all matches of current word
"" replace current word for all
nnoremap <leader>ca :<C-u>%s/\V\<<C-r><C-w>\>/<C-r><C-w>
nnoremap <leader>cA :<C-u>%s/\V<C-r><C-a>/<C-r><C-a>
nnoremap <leader>cw :s/\V\<<C-r><C-w>\>/<C-r><C-w>
nnoremap <leader>cW :s/\V<C-r><C-a>/<C-r><C-a>
" }}}

" }}}

" Plugs configs {{{

" Rainbow {{{
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'separately': {
\       'julia': {
\           'parentheses_options': 'containedin=ALLBUT,juliaCommentL,juliaCommentM',
\       },
\       'latex': {
\           'parentheses': [
\               'start=/{/ end=/}/ fold',
\           ]
\       },
\       'help': 0,
\   }
\ }
" term colors for termguicolors is off
let g:rainbow_colors_dark = [
\   'lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'
\ ]
let g:rainbow_colors_light = [
\   'darkblue', 'darkyellow', 'darkcyan', 'darkmagenta'
\ ]
function! s:rainbow_set_dark()
    if !&termguicolors
        g:rainbow_conf['ctermfgs'] = g:rainbow_colors_dark
    endif
    call rainbow_main#load()
endfunction
function! s:rainbow_set_light()
    if !&termguicolors
        g:rainbow_conf['ctermfgs'] = g:rainbow_colors_light
    endif
    call rainbow_main#load()
endfunction
" }}}

" NERDTree {{{
let NERDTreeShowHidden = 1
nnoremap <silent> <leader>tt :NERDTreeToggle<CR>
" }}}

" NERDCommenter {{{
" disbale default mappings
let g:NERDCreateDefaultMappings = 0
nnoremap <silent> <leader>c<space> <Plug>NERDCommenterToggle
onoremap <silent> <leader>c<space> <Plug>NERDCommenterToggle
xnoremap <silent> <leader>c<space> <Plug>NERDCommenterToggle

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1
" }}}

" COC {{{
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <C-x><C-z> coc#pum#visible() ? coc#pum#stop() : "\<C-x>\<C-z>"

nnoremap <silent> <leader>ll :CocList<CR>
nnoremap <silent> <leader>lc :CocList commands<CR>
nnoremap <silent> <leader>ld :CocList diagnostics<CR>
nnoremap <silent> <leader>le :CocList extensions<CR>

nmap <silent> <leader>[  <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>]  <Plug>(coc-diagnostic-next)
nmap <silent> <leader>-  <Plug>(coc-git-prevchunk)
nmap <silent> <leader>+  <Plug>(coc-git-nextchunk)
nmap <silent> <leader>gd <plug>(coc-definition)
nmap <silent> <leader>gD <Plug>(coc-declaration)
nmap <silent> <leader>gr <Plug>(coc-references)
nmap          <leader>cn <Plug>(coc-rename)
vmap <silent> <leader>f  <Plug>(coc-format-selected)
nmap <silent> <leader>f  <Plug>(coc-format)
" disable latex to unicode via tab for `julia-vim`
" which does not work well with the `coc.nvim`
let g:latex_to_unicode_tab = "off"
" extensions
let g:coc_global_extensions = [
\    "coc-marketplace",
\    "coc-git",
\    "coc-json",
\    "coc-snippets",
\    "coc-pairs",
\    "coc-vimlsp",
\ ]

augroup DisableCoc
    autocmd!
    autocmd BufEnter *.jl if $JULIA_COC_NVIM_DISABLE == "false" | let b:coc_enabled=0 | endif
augroup END
" }}}

" Lightline {{{
function! LightlineCocStatus() abort
    let status = coc#status()
    return (winwidth(0) - len(status)) >= 80 ? status : ''
endfunction

function! LightlineGitStatus() abort
    let status = get(g:, 'coc_git_status', '')
    return winwidth(0) - len(status) >= 70 ? status : ''
endfunction

function! LightlineFileInfo()
    let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
    let modified = &modified ? '*' : ''
    let RO = &readonly && &filetype !~# '\v(help|vimfiler|unite)' ? ' [RO]' : ''
    let status = get(b:, 'coc_git_status', '')
    return RO . filename . modified .
        \ ((winwidth(0) - len(status)) >= 70 ? status : '')
endfunction

let g:lightline = {
\   'colorscheme': 'one_dynamic',
\   'active': {
\     'left': [ [ 'mode', 'paste' ],
\               [ 'gitstatus', 'fileinfo'],
\               [ 'cocstatus' ] ],
\     'right' : [
\       [ 'percent' ],
\       [ 'lineinfo' ],
\       [ 'filetype', 'fileformat', 'fileencoding', 'spell' ]
\     ],
\   },
\   'inactive': {
\     'left': [ [ 'fileinfo' ] ],
\     'right' : [
\       [ 'percent' ],
\       [ 'lineinfo' ]
\     ],
\   },
\   'component_function': {
\     'cocstatus': 'LightlineCocStatus',
\     'gitstatus': 'LightlineGitStatus',
\     'fileinfo' : 'LightlineFileInfo',
\   },
\   'separator':  { 'left': '', 'right': ''},
\   'subseparator':  { 'left': '', 'right': '|' }
\ }

augroup LightlineUpdate
    autocmd!
    autocmd User CocStatusChange,CocDiagnosticChange call lightline#update()
augroup END
" }}}

" Slime {{{
if has('nvim')
    let g:slime_target = "neovim"
else
    let g:slime_target = "vimterminal"
    let g:slime_vimterminal_config = {
    \   "term_finish": "close",
    \   "term_name"  : "Slime",
    \   "term_rows"  : 20,
    \ }
end
let g:slime_no_mappings = 1
xmap <leader><CR> <Plug>SlimeRegionSend
nmap <leader><CR> <Plug>SlimeParagraphSend
" }}}

" Copilot {{{
if has('mac') " default node in brew is too new for copilot
    let g:copilot_node_command = $HOMEBREW_PREFIX . "/opt/node@16/bin/node"
endif
" }}}

" }}}

" Custom config {{{
if filereadable($HOME . "/.vim/custom/config.vim")
    source ~/.vim/custom/config.vim
endif
" }}}

" auto dark mode {{{
" reset lightline color when background changed {{{
function s:lightline_update()
    if g:lightline['colorscheme'] == 'one_dynamic'
        call lightline#colorscheme#one_dynamic#set_paletten()
        call lightline#init()
        call lightline#colorscheme()
        call lightline#update()
    endif
endfunction
" }}}

" autocmd when background changed {{{
augroup BackgroundChange
    autocmd!
    autocmd User BackGroundDark set background=dark
    autocmd User BackGroundLight set background=light
    autocmd User BackGroundDark,BackGroundLight call s:lightline_update()
    autocmd User BackGroundDark call s:rainbow_set_dark()
    autocmd User BackGroundLight call s:rainbow_set_light()
augroup END
" }}}
" }}} end of auto dark mode

" init background color {{{
call SetBackground(1)
" }}}

" vim:tw=76:ts=4:sw=4:et:fdm=marker
