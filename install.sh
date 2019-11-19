#!/usr/bin/env sh

realpath() {
    local OLDPWD=$PWD
    local DIR=$(dirname $1)
    local FILE=$(basename $1)
    cd -P $DIR
    local REALPATH="$PWD/$(basename "$1")"
    cd $OLDPWD
    echo "$REALPATH"
}

if [ -e ~/.vimrc ]; then
    mv ~/.vimrc ~/.vimrc_backup
fi

if [ -e ~/.vim ]; then
    mv ~/.vim ~/.vim_backup
fi

ln -s $(dirname $(realpath $0))/.vimrc ~/.vimrc
ln -s $(dirname $(realpath $0))/.vim ~/.vim

# nvim config
if [ -e ~/.config/nvim/init.vim ]; then
    echo "set runtimepath^=~/.vim runtimepath+=~/.vim/after
    let &packpath = &runtimepath
    source ~/.vimrc" >> ~/.config/nvim/init.vim
    nvim -c PlugInstall +qall
    nvim -c "CocInstall coc-git coc-vimlsp coc-json coc-vimtex coc-pairs" +qall
    nvim -c "call joinjson#Update()" +qall
else
    vim -c PlugInstall +qall
    vim -c "CocInstall coc-git coc-vimlsp coc-json coc-vimtex coc-pairs" +qall
    vim -c "call joinjson#Update()" +qall
fi
