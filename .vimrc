" Nvim compatibility {{{
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

" Plugs load {{{
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
    " plugs disable for vim code
    if !exists("g:vscode")
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
        " Github Copilot
        if has('nvim-0.6')
            Plug 'github/copilot.vim'
        endif
        if has('nvim') && has('mac') &&
            \ (!has('nvim-0.7') || $TERM_PROGRAM != 'iTerm.app')
            Plug 'f-person/auto-dark-mode.nvim'
        endif
    endif
    " Custom plugs
    if filereadable($HOME . "/.vim/custom/plugs.vim")
        source ~/.vim/custom/plugs.vim
    endif
call plug#end()
" }}}

" automatically install missing plugs {{{
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

" Leader config {{{
if filereadable($HOME . "/.vim/custom/leader.vim")
    source ~/.vim/custom/leader.vim
endif
if !exists("mapleader")
    let mapleader=","
endif
" }}}

" General config {{{

" misc {{{
" Filetype
filetype indent plugin on

" Line number config
set number
set relativenumber

" Confirm when quit
set confirm

" Show match
set showmatch

" Show cmd
set showcmd

" File encoding
set encoding=utf-8

" modeline
set modelines=1

" highlight search
set hlsearch
set incsearch

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

" always show tab line
set showtabline=2
" }}}

" color scheme related {{{

" use gui color
if !($TERM_PROGRAM =~ "Apple_Terminal")
    set termguicolors
endif

" Syntax highlight
syntax enable

" colorscheme
if !($TERM_PROGRAM =~ "Apple_Terminal")
    colorscheme one
endif

" italic comments
let &t_ZH="\e[3m"
let &t_ZR="\e[23m"
highlight Comment cterm=italic

" set background color {{{
function SetBackGround(...)
    let init = get(a:, 1, 0) " init only the argument is given
    if has('mac')
        if system('defaults read -g AppleInterfaceStyle') =~ "Dark"
            " don't change background if already set or not init
            if &background != 'dark' || !init
                doautocmd User BackGroundDark
            endif
        elseif &background != 'light' || !init " the same for dark
            doautocmd User BackGroundLight
        endif
    endif
endfunction
" }}}

" }}}

" Indent config{{{
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set smartindent
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

" vscode only configs " {{{
if exists("g:vscode")
    " Language features
    nmap <silent> <leader>]  <Cmd>call VSCodeCall("editor.action.marker.next")<CR>
    nmap <silent> <leader>[  <Cmd>call VSCodeCall("editor.action.marker.prev")<CR>
    nmap <silent> <leader>-  <Cmd>call VSCodeCall("editor.action.dirtydiff.prev")<CR>
    nmap <silent> <leader>+  <Cmd>call VSCodeCall("editor.action.dirtydiff.next")<CR>
    nmap <silent> <leader>gd <Cmd>call VSCodeCall("editor.action.revealDefinition")<CR>
    nmap <silent> <leader>gD <Cmd>call VSCodeCall("editor.action.goToDeclaration")<CR>
    nmap <silent> <leader>gr <Cmd>call VSCodeCall("editor.action.goToReferences")<CR>
    nmap <silent> <leader>pd <Cmd>call VSCodeCall("editor.action.peekDefinition")<CR>
    nmap <silent> <leader>ph <Cmd>call VSCodeCall("editor.action.showHover")<CR>
    nmap          <leader>rn <Cmd>call VSCodeCall("editor.action.rename")<CR>
    nmap <silent> <leader>fd <Cmd>call VSCodeCall("editor.action.formatDocument")<CR>
    vmap <silent> <leader>fd <Cmd>call VSCodeCall("editor.action.formatDocument")<CR>
    " Comments
    xmap <silent> <leader>c<space> <Plug>VSCodeCommentary
    nmap <silent> <leader>c<space> <Plug>VSCodeCommentary
    omap <silent> <leader>c<space> <Plug>VSCodeCommentary
    " Explore
    nmap <silent> <leader>tt <Plug>call VSCodeCall("workbench.view.explorer")<CR>
else
" }}}

" One color scheme {{{
let g:one_allow_italics = 1
" }}}

" rainbow configs {{{
let g:rainbow_active = 1
if !&termguicolors
    " term colors for termguicolors is off
    let g:rainbow_colors_dark = [
    \   'lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'
    \ ]
    let g:rainbow_colors_light = [
    \   'darkblue', 'darkyellow', 'darkcyan', 'darkmagenta'
    \ ]
    if &background == 'dark'
        let g:rainbow_conf = {'ctermfgs': g:rainbow_colors_dark}
    else
        let g:rainbow_conf = {'ctermfgs': g:rainbow_colors_light}
    endif
    function s:rainbow_set_dark()
        g:rainbow_conf['ctermfgs'] = g:rainbow_colors_dark
        call rainbow_main#load()
    endfunction
    function s:rainbow_set_light()
        g:rainbow_conf['ctermfgs'] = g:rainbow_colors_light
        call rainbow_main#load()
    endfunction
endif
" }}}

" NERDTree config {{{
let NERDTreeShowHidden = 1
nnoremap <silent> <leader>tt :NERDTreeToggle<CR>
" }}}

" Comment config{{{
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

" Coc config {{{
set hidden
set nobackup
set nowritebackup
set cmdheight=2
set updatetime=300
set shortmess+=c
set signcolumn=yes
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
nnoremap <silent> <leader>l :CocList<CR>
nmap <silent> <leader>[ <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>] <Plug>(coc-diagnostic-next)
nmap <silent> <leader>- <Plug>(coc-git-prevchunk)
nmap <silent> <leader>+ <Plug>(coc-git-nextchunk)
nmap <silent> <leader>gd <plug>(coc-definition)
nmap <silent> <leader>gD <Plug>(coc-declaration)
nmap <silent> <leader>gr <Plug>(coc-references)
nmap          <leader>cn <Plug>(coc-rename)
vmap <silent> <leader>f <Plug>(coc-format-selected)
nmap <silent> <leader>f <Plug>(coc-format)
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
" }}}

" Lightline config {{{
if has('nvim-0.7')
    set laststatus=3
else
    set laststatus=2
endif

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
    \ 'colorscheme': 'one_auto',
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'gitstatus' , 'fileinfo'],
    \             [ 'cocstatus' ] ],
    \   'right' : [
    \     [ 'percent' ],
    \     [ 'lineinfo' ],
    \     [ 'filetype', 'fileformat', 'fileencoding', 'spell' ]
    \   ],
    \ },
    \ 'inactive': {
    \   'left': [ [ 'fileinfo' ] ],
    \   'right' : [
    \     [ 'percent' ],
    \     [ 'lineinfo' ]
    \   ],
    \ },
    \ 'component_function': {
    \   'cocstatus': 'LightlineCocStatus',
    \   'gitstatus': 'LightlineGitStatus',
    \   'fileinfo' : 'LightlineFileInfo',
    \ },
    \ 'separator':  { 'left': '', 'right': ''},
    \ 'subseparator':  { 'left': '', 'right': '|' }
    \ }

augroup LightlineUpdate
    autocmd!
    autocmd User CocStatusChange,CocDiagnosticChange call lightline#update()
augroup END
" }}}

" Slime config {{{
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

" endif exists(g:vscode) {{{
endif "
" }}}

" }}}

" Language configs {{{
" LaTeX
let g:tex_flavor = "latex"
let g:vimtex_fold_enabled = 1
" }}}

" Custom config {{{
if filereadable($HOME . "/.vim/custom/config.vim")
    source ~/.vim/custom/config.vim
endif
" }}}

" auto dark mode {{{
" reset lightline color when background changed {{{
function s:lightline_update()
    if g:lightline['colorscheme'] == 'one_auto'
        call lightline#colorscheme#one_auto#set_paletten()
        call lightline#init()
        call lightline#colorscheme()
        call lightline#update()
    endif
endfunction
" }}}

" autocmd when background changed {{{
augroup BackGroundChange
    autocmd!
    autocmd User BackGroundDark set background=dark
    autocmd User BackGroundLight set background=light
    autocmd User BackGroundDark,BackGroundLight call s:lightline_update()
    if !&termguicolors && exists('g:rainbow_conf')
        autocmd User BackGroundDark call s:rainbow_set_dark()
        autocmd User BackGroundLight call s:rainbow_set_light()
    endif
augroup END
" }}}

" auto SetBackGround {{{
" if SIGWINCH is supported
if has('nvim-0.7') && $TERM_PROGRAM =~ "iTerm.app"
    augroup CatchBackGround
        autocmd!
        autocmd Signal SIGWINCH call SetBackGround()
    augroup END
elseif has('nvim') && has('mac')
" this is the alternative way to set background
" when SIGWINCH is not supported or terminal is not iTerm
" this require the plug 'auto_dark_mode'
lua << EOF
local auto_dark_mode = require('auto-dark-mode')
auto_dark_mode.setup({
    update_interval = 3000,
    set_dark_mode = function()
        vim.call('SetBackGround')
    end,
    set_light_mode = function()
        vim.call('SetBackGround')
    end,
})
auto_dark_mode.init()
EOF
endif
" }}} end of auto SetBackGround

" }}} end of auto dark mode

" init background color {{{
call SetBackGround(1)
" }}}

" vim:tw=76:ts=4:sw=4:et:fdm=marker
