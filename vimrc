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
    " Custom plugs
    if filereadable($HOME . "/.vim/plugs.vim")
        source ~/.vim/plugs.vim
    endif
call plug#end()
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

" leader
let mapleader=","
let maplocalleader=";"

" highlight search
set hlsearch
nnoremap <silent> <leader>n :nohlsearch<CR>

" Show match
set showmatch

" Show cmd
set showcmd

" File encoding
set encoding=utf-8

" Split flavor
set splitbelow
set splitright

" Quickfix toggle
nnoremap <silent> <leader>tq :call quickfixtoggle#ToggleQuickfixList()<CR>

" Remove all tariling blanks
nnoremap <silent> <leader>tb :%s/[ \t]+$//<CR>

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
nmap <silent> <leader>[ <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>] <Plug>(coc-diagnostic-next)
nmap <silent> <leader>d <plug>(coc-definition)
nmap <leader>rn <Plug>(coc-rename)
vmap <silent> <leader>f <Plug>(coc-format-selected)
nmap <silent> <leader>f <Plug>(coc-format)
" }}}

" Lightline config {{{
set laststatus=2

function! LightlineGitStatus() abort
    let status = get(b:, 'coc_git_status', '')
    " return blame
    return winwidth(0) > 120 ? status : ''
endfunction

function! LightlineReadonly()
      return &readonly && &filetype !~# '\v(help|vimfiler|unite)' ? 'RO' : ''
endfunction

function! LightlineFilename()
    let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
    let modified = &modified ? '*' : ''
    return filename . modified
endfunction

let g:lightline = {
    \ 'colorscheme' : 'one',
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'cocstatus', 'filename', 'readonly'] ],
    \   'right' : [
    \     [ 'gitstatus'],
    \     [ 'filetype', 'fileformat', 'fileencoding', 'spell',
    \       'lineinfo', 'percent' ],
    \   ],
    \ },
    \ 'component_function': {
    \   'cocstatus': 'coc#status',
    \   'gitstatus' : 'LightlineGitStatus',
    \   'readonly' : 'LightlineReadonly',
    \   'filename' : 'LightlineFilename',
    \ },
    \ }
" }}}

" custom config {{{
if filereadable($HOME . "/.vim/config.vim")
    source ~/.vim/config.vim
endif
" }}}

" vim:tw=76:tw=4:sw=4:et:fdm=marker
