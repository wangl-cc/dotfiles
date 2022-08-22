#!/bin/zsh

PREFIX=${PREFIX-"$HOME/.local"}
BINPATH=${BINPATH-"$PREFIX/bin"}
if ! [ -d "$BINPATH" ]; then
    mkdir -p "$BINPATH"
fi
MANPATH=${MANPATH-"$PREFIX/share/man"}
COMPPATH=${COMPPATH-"$PREFIX/share/zsh/site-functions"}
if ! [ -d $COMPPATH ]; then
    mkdir -p $COMPPATH
fi
CACHEPATH=${CACHEPATH-"$HOME/.cache/zshrc"}
if ! [ -d $CACHEPATH ]; then
    mkdir -p $CACHEPATH
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
    curl -sSLo "$CACHEPATH/$name" "$url" && \
        install -m $mod "$CACHEPATH/$name" "$dest" && \
        print -P "Installation successful.%b" || \
        print -P "Installation failed.%b"
}
install_bin() { install_base $1 $BINPATH 755; }
install_comp() { install_base $1 $COMPPATH 644; }
install_man() {
    man="$MANPATH/man${1##*.}"
    if ! [ -d $man]; then
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
path=("$BINPATH" "$path[@]")
export PATH

# clone repo
if [ -d "$HOME/.git" ]; then
    source $HOME/.zshrc
    yadm --yadm-repo "$HOME/.git" pull
else
    if [ -f "$HOME/.zshrc" ]; then
        echo "Found existing .zshrc file, backing up to .zshrc.bak"
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi
    GITHUB=${GITHUB-"https://github.com/"}
    OWNER=${OWNER-"wangl-cc"}
    REPO=${REPO-"dotfiles"}
    REPO_URL=${REPO_URL-"$GITHUB$OWNER/$REPO.git"}
    yadm clone $REPO_URL --no-bootstrap
    source $HOME/.zshrc
    # move repo
    mv $HOME/.local/share/yadm/repo.git $HOME/.git
    yadm --yadm-repo $HOME/.git bootstrap
fi
