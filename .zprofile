typeset -U INFOPATH
export INFOPATH="$HOMEBREW_PREFIX/share/info${INFOPATH+:$INFOPATH}"

if [ -z ${GPG_TTY+x} ]; then
    export GPG_TTY=$(tty)
fi
