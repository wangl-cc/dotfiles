#!/bin/bash

realpath() {
    local oldpwd=$PWD
    local dir=$(dirname $1)
    local base=$(basename $1)
    cd -P $dir
    local path=$PWD/$base
    cd $oldpwd
    echo $path
} 
backup() {
    if [ -e $1 ]; then
        mv $1 $1"_backup"
        echo "  Backed up $1."
    fi
}

recover() {
    if [ -e $1 ]; then
		rm $1
		echo "  Removed link $1."
		if [ -e $1"_backup" ]; then
			mv $1"_backup" $1
			echo "  Recovered $1"
		fi
	fi
}

readonly REALPWD=$(dirname $(realpath $0))
readonly VIMRC_SRC=$REALPWD/vimrc
readonly VIMDIR_SRC=$REALPWD/vim
readonly VIMRC=$HOME/.vimrc
readonly VIMDIR=$HOME/.vim
readonly NVIMRC=$HOME/.config/nvim/init.vim
readonly VIMCONFIG_SRC=$VIMDIR_SRC/coc-settings.json
readonly NVIMCONFIG=$HOME/.config/nvim/coc-settings.json
readonly COC_EXTS="coc-marketplace coc-git coc-json coc-pairs coc-snippets"
readonly USAGE="
Usage:
    $(basename $0) <command> [options]

Commands:
    install         Install this vim config.
    uninstall       Uninstall this vim config.
    clean           Clean backup files.
    help            Show this help message and exit.

Install options:
    --nvim          Install for neovim.
    --plug          Install with plugs.
"

install() {
    echo "Begin install:"
    local vim=vim
    backup $VIMRC
    backup $VIMDIR
    ln -s $VIMRC_SRC $VIMRC
    ln -s $VIMDIR_SRC $VIMDIR
    if [[ $* =~ "--nvim" ]]; then
        backup $NVIMRC
        ln -s $VIMRC_SRC $NVIMRC
        ln -s $VIMCONFIG $NVIMCONFIG
        local vim=nvim
    fi
    if [[ $* =~ "--plug" ]]; then
        echo "  Install plugs."
        $vim -c PlugInstall\
             -c "CocInstall -sync $COC_EXTS"\
             +qall
    fi
    echo "Install finnish!"
}

uninstall() {
    echo "Begin uninstall:"
    for var in $VIMRC $NVIMRC $VIMDIR; do
        recover $var
    done
    echo "Uninstall finnish!"
}

clean() {
    echo "Begin clean backup file:"
    for var in $VIMRC $NVIMRC $VIMDIR; do
        local backupfile=$var"_backup"
        if [ -e $backupfile ]; then
            rm -rf $backupfile
            echo "  Removed $backupfile."
        fi
    done
    echo "Clean finnish!"
}

help() {
    echo "$USAGE"
}

if [ $# -gt 0 ]; then
    $*
else
    help
fi

# vim:ts=4:sw=4:tw=74
