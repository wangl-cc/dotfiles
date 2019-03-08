#!/usr/bin/bash

mv ~/.vimrc ~/.vimrc_backup
ln -s $(dirname $(readlink -f $0))/.vimrc ~/.vimrc
