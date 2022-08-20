#!/bin/sh

__RC_PREFIX="$HOME/.local"
__RC_BINPATH="$__RC_PREFIX/bin"
__RC_MANPATH="$__RC_PREFIX/share/man"
__RC_COMPPATH="$__RC_PREFIX/share/zsh/site-functions"
if ! [ -d $__RC_COMPPATH ]; then
    mkdir -p $__RC_COMPPATH
fi
__RC_CACHEPATH="$HOME/.cache/zshrc"
if ! [ -d $__RC_CACHEPATH ]; then
    mkdir -p $__RC_CACHEPATH
fi
__rc_install() {
    url="$1"
    dest="$2"
    mod="$3"
    name=$(basename $url)
    print -P "Installing %F{33}$name%F{34}%f:"
    print -P "URL: %F{33}$url%f"
    print -P "Destination: %F{33}$dest/$name%f"
    print -P "Mode: %F{33}$mod%f"
    curl -sSLo "$__RC_CACHEPATH/$name" "$url" && \
        install -m $mod "$__RC_CACHEPATH/$name" "$dest" && \
        print -P "Installation successful.%b" || \
        print -P "Installation failed.%b"
}
__rc_install_bin() { __rc_install $1 $__RC_BINPATH 755 }
__rc_install_comp() { __rc_install $1 $__RC_COMPPATH 644 }
__rc_install_man() {
    __rc_manpath="$__RC_MANPATH/man${1##*.}"
    if ! [ -d $__rc_manpath ]; then
        mkdir -p $__rc_manpath
    fi
    __rc_install $1 $__rc_manpath 644
}
# install yadm
__RC_YADM_TAG="3.2.1"
__rc_install_yadm() {
    __rc_install_bin "$(__github_url_raw TheLocehiliosan yadm)/$__RC_YADM_TAG/yadm"
    __rc_install_comp "$(__github_url_raw TheLocehiliosan yadm)/$__RC_YADM_TAG/completion/zsh/_yadm"
    __rc_install_man "$(__github_url_raw TheLocehiliosan yadm)/$__RC_YADM_TAG/yadm.1"
}
if test ! $(command -v yadm); then
    read -q "__RC_YADM_INSTALL?Install yadm? [y/n]"
    if [ $__RC_YADM_INSTALL = "y" ]; then
        __rc_install_yadm
    else
        echo "yadm not installed."
    fi
fi
# install esh
__RC_ESH_TAG="v0.3.2"
__rc_install_esh() {
    __rc_install_bin "$(__github_url_raw jirutka esh)/$__RC_ESH_TAG/esh"
}
if test ! $(command -v esh); then
    read -q "__RC_ESH_INSTALL?Install esh? [y/n]"
    if [ $__RC_ESH_INSTALL = "y" ]; then
        __rc_install_esh
    else
        echo "esh not installed."
    fi
fi
typeset -U PATH path
path=("$__RC_BINPATH" "$path[@]")
export PATH

yadm clone git@github.com:wangl-cc/dotfiles.git --bootstrap
