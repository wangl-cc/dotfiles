#!/usr/bin/env bash

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
    nvim -c PlugInstall
else
    vim -c PlugInstall
fi
