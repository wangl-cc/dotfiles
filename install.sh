#!/usr/bin/bash

if [ -e ~/.vimrc ]; then
    mv ~/.vimrc ~/.vimrc_backup
fi

if [ -e ~/.vim ]; then
    mv ~/.vim ~/.vim_backup
fi

ln -s $(dirname $(readlink -f $0))/.vimrc ~/.vimrc
ln -s $(dirname $(readlink -f $0))/.vim ~/.vim

# nvim config
if [ -e ~/.config/nvim/init.vim ]; then
    echo "set runtimepath^=~/.vim runtimepath+=~/.vim/after
    let &packpath = &runtimepath
    source ~/.vimrc" >> ~/.config/nvim/init.vim
fi

# pip
pip install --user -U pynvim

# Plug install
nvim -c PlugInstall
