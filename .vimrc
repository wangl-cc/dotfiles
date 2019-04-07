" If there is not plug.vim, install it and install plugins.
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" vim-plig
call plug#begin('~/.vim/plugged')
    " tree
    Plug 'scrooloose/nerdtree'
    " Git
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'airblade/vim-gitgutter'
    " Comment
    Plug 'scrooloose/nerdcommenter'
    " julia plugins
    Plug 'JuliaEditorSupport/julia-vim'
    Plug 'wangl-cc/juliatools-nvim', { 'do' : ':UpdateRemotePlugins' }
    " auto pairs plugin
    Plug 'jiangmiao/auto-pairs'
    " vim-indent-guides
    Plug 'nathanaelkane/vim-indent-guides'
    " BioSyntax
    Plug 'bioSyntax/bioSyntax-vim'
    " vim-airline
    Plug 'vim-airline/vim-airline'
    " vimtex
    Plug 'lervag/vimtex'
    " Shougo{
        " Search at source
        Plug 'Shougo/denite.nvim'
        " Complelte
        Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    " }
call plug#end()

" filetype
filetype indent plugin on

" line number config
set number
set relativenumber

" syntax highlight
syntax on

" confirm when quit
set confirm

" indent config{
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set smartindent
" }

" leader
let mapleader=","

" tab skip the brackets{
inoremap <Tab> <C-R>=TabSkip()<CR>

function TabSkip()
    let l:char = getline('.')[col('.') - 1]
    if l:char == '}' || l:char == ')' || l:char == ']' || l:char == ';' || l:char == "'" || l:char == '`' || l:char == '"'
        return "\<Right>"
    else
        return "\<Tab>"
    endif
endf
" }

" hlsearch
set hlsearch
nnoremap <leader>nl :nohlsearch<cr>

" background
set background=dark

" showmatch
set showmatch

" novisualbell
set novisualbell

" showcmd
set showcmd

" encoding
set encoding=utf-8

" shell
set shell=/bin/zsh

" split
set splitbelow
set splitright

" quickly write and quit {
    nnoremap <leader>ww :w<CR>
    nnoremap <leader>qq :q<CR>
    nnoremap <leader>wq :wq<CR>
" }

" NERDTree{
    let NERDTreeShowHidden = 1
    nnoremap <leader>tt :NERDTreeToggle<CR>
" }

" Git Toggle map
nnoremap <leader>gt :GitGutterToggle<CR>

" Enable indent guide on startup
let g:indent_guides_enable_on_vim_startup = 1

" Enable deoplete at startup
let g:deoplete#enable_at_startup = 1

" .tex file flavor
let g:tex_flavor='latex'

" Comment config{
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
" }
