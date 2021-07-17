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
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" }}}

" Plugs load {{{
call plug#begin('~/.vim/plugged')
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
    " Some file commands like rename
    Plug 'tpope/vim-eunuch'
    " Send code to terminal
    Plug 'jpalardy/vim-slime'
    " Some operations text object
    Plug 'wellle/targets.vim'
    " Text alignment
    Plug 'godlygeek/tabular'
    " fuzzy finder
    Plug 'ctrlpvim/ctrlp.vim'
    " Custom plugs
    if filereadable($HOME . "/.vim/custom/plugs.vim")
        source ~/.vim/custom/plugs.vim
    endif
call plug#end()
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

" Filetype
filetype indent plugin on

" Line number config
set number
set relativenumber

" Syntax highlight
syntax on

" Confirm when quit
set confirm

" Indent config{{{
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set smartindent
" }}}

" highlight search
set hlsearch
nnoremap <silent> <leader>n :nohlsearch<CR>

" Show match
set showmatch

" Show cmd
set showcmd

" File encoding
set encoding=utf-8

" modeline
set modelines=1

" Split flavor
set splitbelow
set splitright

" Remove all tariling blanks
nnoremap <silent> <leader>tb :%s/[ \t]\+$//<CR>

" Indent guides toggle
nnoremap <silent> <leader>ti :IndentGuidesToggle<CR>

" }}}

" NERDTree config {{{
let NERDTreeShowHidden = 1
nnoremap <silent> <leader>tt :NERDTreeToggle<CR>
" }}}

" Comment config{{{
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
nmap <silent> <leader>[l <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>]l <Plug>(coc-diagnostic-next)
nmap <silent> <leader>[g <Plug>(coc-git-prevchunk)
nmap <silent> <leader>]g <Plug>(coc-git-nextchunk)
nmap <silent> <leader>gd <plug>(coc-definition)
nmap <leader>cw <Plug>(coc-rename)
vmap <silent> <leader>f <Plug>(coc-format-selected)
nmap <silent> <leader>f <Plug>(coc-format)
" extensions
let g:coc_global_extensions = [
\    "coc-marketplace",
\    "coc-git",
\    "coc-json",
\    "coc-snippets",
\    "coc-pairs",
\    "coc-julia",
\ ]
" }}}

" Lightline config {{{
set laststatus=2

function! LightlineCocStatus() abort
    let status = coc#status()
    return (winwidth(0) - len(status)) >= 80 ? status : ''
endfunction

function! LightlineGitStatus() abort
    let status = get(g:, 'coc_git_status', '')
    return winwidth(0) >= 75 ? status : ''
endfunction

function! LightlineFileInfo()
    let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
    let modified = &modified ? '*' : ''
    let RO = &readonly && &filetype !~# '\v(help|vimfiler|unite)' ? ' [RO]' : ''
    let status = winwidth(0) >=  100 ? get(b:, 'coc_git_status', '') : ''
    return RO . filename . modified . status
endfunction

let g:lightline = {
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

" Custom config {{{
if filereadable($HOME . "/.vim/custom/config.vim")
    source ~/.vim/custom/config.vim
endif
" }}}

" vim:tw=76:ts=4:sw=4:et:fdm=marker
