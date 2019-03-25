if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" vim-plig
call plug#begin('~/.vim/plugged')
    " NERD tree plugin
    Plug 'scrooloose/nerdtree'
    " julia-vim plugin
    Plug 'JuliaEditorSupport/julia-vim'
    " auto pairs plugin
    Plug 'jiangmiao/auto-pairs'
    " juliacomplete-nvim-client
    Plug 'wangl-cc/juliacomplete-nvim-client', { 'do' : ':UpdateRemotePlugins' }
call plug#end()

" line number
set number
set relativenumber

" syntax highlight
syntax on

" nobackup
set nobackup

" confirm when quit
set confirm

" indent
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set smartindent

" leader
let mapleader=","

" tab skip the brackets
inoremap <Tab> <C-R>=TabSkip()<CR>

function TabSkip()
    let l:char = getline('.')[col('.') - 1]
    if l:char == '}' || l:char == ')' || l:char == ']' || l:char == ';'
        return "\<Right>"
    else
        return "\<Tab>"
    endif
endf

" hlsearch
set hlsearch
nnoremap <leader>c :nohlsearch<cr>

" background
set background=dark

" showmatch
set showmatch

" show coordinate of cursor
set ruler

" novisualbell
set novisualbell

" showcmd
set showcmd

" encoding
set encoding=utf-8

" shell
set shell=/bin/bash

" quickly write and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>wq :wq<CR>

" NERDTree
augroup NERDTreeAutoClose
    autocmd!
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END
nnoremap <leader>t :NERDTreeToggle<CR>
