set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set runtimepath+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
" NERD tree plugin
Plugin 'scrooloose/nerdtree'
" julia-vim plugin
Plugin 'JuliaEditorSupport/julia-vim'
" auto pairs plugin
Plugin 'jiangmiao/auto-pairs.git'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

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

" quickly run
" nnoremap <leader>r :call QuickRun()<cr>
func! QuickRun()
    exec "w"
    if &filetype == 'c'
        exec "!gcc % -o %r.o"
        exec "!time %r.o"
    elseif &filetype == 'cpp'
        exec "!g++ % -o %r.o"
        exec "!time %r.o"
    elseif &filetype == 'julia'
        exec "!time julia --color=yes %"
    elseif &filetype == 'python'
        exec "!time python %"
    elseif &filetype == 'markdown'
        exec "google-chrome-stable %"
    endif
endfunc

" NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
nnoremap <leader>t :NERDTreeToggle<CR>
