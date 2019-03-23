#!/usr/bin/bash

if [ -e ~/.vimrc ]; then
    mv ~/.vimrc ~/.vimrc_backup
fi

if [ -e ~/.vim ]; then
    mv ~/.vim ~/.vim_backup
fi

ln -s $(dirname $(readlink -f $0))/.vimrc ~/.vimrc
ln -s $(dirname $(readlink -f $0))/.vim ~/.vim
