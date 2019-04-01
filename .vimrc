if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" vim-plig
call plug#begin('~/.vim/plugged')
    " NERD tree plugin
    Plug 'scrooloose/nerdtree'
    " Git
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'airblade/vim-gitgutter'
    " julia-vim plugin
    Plug 'JuliaEditorSupport/julia-vim'
    " Plug 'autozimu/LanguageClient-neovim', {'branch': 'next', 'do': 'bash install.sh'}
    " auto pairs plugin
    Plug 'jiangmiao/auto-pairs'
    " juliacomplete
    Plug 'wangl-cc/juliatools-nvim', { 'do' : ':UpdateRemotePlugins' }
    " vim-indent-guides
    Plug 'nathanaelkane/vim-indent-guides'
    " BioSyntax
    Plug 'bioSyntax/bioSyntax-vim'
    " vim-airline
    Plug 'vim-airline/vim-airline'
    " vimtex
    Plug 'lervag/vimtex'
    " lsc
    " Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
    Plug 'Shougo/denite.nvim'
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
call plug#end()

" filetype
filetype indent plugin on

" line number
set number
set relativenumber

" syntax highlight
syntax on

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
    if l:char == '}' || l:char == ')' || l:char == ']' || l:char == ';' || l:char == "'" || l:char == '`' || l:char == '"'
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

" quickly write and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>wq :wq<CR>

" NERDTree
let NERDTreeShowHidden = 1
augroup NERDTreeAutoClose
    autocmd!
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END
nnoremap <leader>t :NERDTreeToggle<CR>

" Git
nnoremap <leader>g :GitGutterToggle<CR>

" Indent guide
let g:indent_guides_enable_on_vim_startup = 1

" deoplete
let g:deoplete#enable_at_startup = 1

" tex
let g:tex_flavor='latex'
