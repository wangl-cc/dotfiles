#!/usr/bin/bash

mv ~/.vimrc ~/.vimrc_backup
mv ~/.vim ~/.vim_backup
ln -s $(dirname $(readlink -f $0))/.vimrc ~/.vimrc
ln -s $(dirname $(readlink -f $0))/.vim ~/.vim
