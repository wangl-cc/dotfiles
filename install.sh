#!/bin/zsh

PREFIX=${PREFIX-"$HOME/.local"}
BINDIR=${BINDIR-"$PREFIX/bin"}
if ! [ -d "$BINDIR" ]; then
    mkdir -p "$BINDIR"
fi
MANDIR=${MANDIR-"$PREFIX/share/man"}
COMDIR=${COMDIR-"$PREFIX/share/zsh/site-functions"}
if ! [ -d $COMDIR ]; then
    mkdir -p $COMDIR
fi
CACHEDIR=${CACHEDIR-"$(mktemp -d)"}
if ! [ -d $CACHEDIR ]; then
    mkdir -p $CACHEDIR
fi

# install functions
install_base() {
    url="$1"
    dest="$2"
    mod="$3"
    name=$(basename $url)
    print -P "Installing %F{33}$name%F{34}%f:"
    print -P "URL: %F{33}$url%f"
    print -P "Destination: %F{33}$dest/$name%f"
    print -P "Mode: %F{33}$mod%f"
    curl -sSLo "$CACHEDIR/$name" "$url" && \
        install -m $mod "$CACHEDIR/$name" "$dest" && \
        print -P "Installation successful.%b" || \
        print -P "Installation failed.%b"
}
install_bin() { install_base $1 $BINDIR 755; }
install_comp() { install_base $1 $COMDIR 644; }
install_man() {
    man="$MANDIR/man${1##*.}"
    if ! [ -d $man ]; then
        mkdir -p $man
    fi
    install_base $1 $man 644
}

# install yadm
YADM_TAG=${YADM_TAG-"3.2.1"}
YADM_RAW=${YADM_RAW-'https://raw.githubusercontent.com/TheLocehiliosan/yadm'}
install_yadm() {
    install_bin "$YADM_RAW/$YADM_TAG/yadm"
    install_comp "$YADM_RAW/$YADM_TAG/completion/zsh/_yadm"
    install_man "$YADM_RAW/$YADM_TAG/yadm.1"
}
if test ! $(command -v yadm); then
    install_yadm
fi
# install esh
ESH_TAG=${ESH_TAG-"v0.3.2"}
ESH_RAW=${ESH_RAW-'https://raw.githubusercontent.com/jirutka/esh'}
install_esh() {
    install_bin "$ESH_RAW/$ESH_TAG/esh"
}
if test ! $(command -v esh); then
    install_esh
fi

# set PATH
typeset -U PATH path
path=("$BINDIR" "$path[@]")
export PATH

# clone repo
REPO_DEST=${REPO_DEST-"$HOME/.git"}
if [ -d "$REPO_DEST" ]; then
    yadm --yadm-repo "$HOME/.git" pull
else
    GITHUB=${GITHUB-"https://github.com/"}
    OWNER=${OWNER-"wangl-cc"}
    REPO=${REPO-"dotfiles"}
    REPO_URL=${REPO_URL-"$GITHUB$OWNER/$REPO.git"}
    yadm --yadm-repo "$REPO_DEST" clone $REPO_URL --bootstrap
fi
