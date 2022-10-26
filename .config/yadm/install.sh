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
CACHEDIR=${CACHEDIR-"$HOME/.cache/dotfiles_install"}
if ! [ -d $CACHEDIR ]; then
    mkdir -p $CACHEDIR
fi

# install functions
install_base() {
    url="$1"
    mod="$3"
    name=$(basename $url)
    cache="$CACHEDIR/$name"
    dest="$2/$name"
    [ -f $dest ] && return 0
    print -P "Installing %F{33}$name%F{34}%f:"
    print -P "Destination: %F{33}$dest%f"
    print -P "Mode: %F{33}$mod%f"
    if [ ! -f $cache ]; then
        print -P "Download form %F{33}$url%f..."
        curl -sSLo "$cache" "$url" && \
            print -P "Download successful." || \
            print -P "Download failed."
    fi
    install -m $mod "$cache" "$dest" && \
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
if [[ ! $(command -v yadm) || $(command -v yadm) = "$BINDIR/yadm" ]]; then
    install_bin "$YADM_RAW/$YADM_TAG/yadm"
    install_comp "$YADM_RAW/$YADM_TAG/completion/zsh/_yadm"
    install_man "$YADM_RAW/$YADM_TAG/yadm.1"
fi
# install esh
ESH_TAG=${ESH_TAG-"v0.3.2"}
ESH_RAW=${ESH_RAW-'https://raw.githubusercontent.com/jirutka/esh'}
if test ! $(command -v esh); then
    install_bin "$ESH_RAW/$ESH_TAG/esh"
fi

# set PATH
typeset -U PATH path
path=("$BINDIR" "$path[@]")
export PATH

# clone repo
REPO_DEST=${REPO_DEST-"$HOME/.git"}
if [ -d "$REPO_DEST" ]; then
    print -P "Repository already exists, pull latest changes."
    yadm --yadm-repo "$HOME/.git" pull
else
    print -P "Clone repository."
    GITHUB=${GITHUB-"https://github.com/"}
    OWNER=${OWNER-"wangl-cc"}
    REPO=${REPO-"dotfiles"}
    REPO_URL=${REPO_URL-"$GITHUB$OWNER/$REPO.git"}
    yadm --yadm-repo "$REPO_DEST" clone $REPO_URL --bootstrap
fi

# fake git for yadm
YADM_DIR="$HOME/.local/share/yadm"
if ! [ -e "$YADM_DIR/repo.git" ]; then
    print -P "Create fake git for yadm."
    if ! [ -d "$YADM_DIR" ]; then
        mkdir -p "$YADM_DIR"
    fi
    ln -s "$REPO_DEST" "$YADM_DIR/repo.git"
fi
