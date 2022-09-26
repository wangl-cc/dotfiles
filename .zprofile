typeset -U INFOPATH
export INFOPATH="$HOMEBREW_PREFIX/share/info${INFOPATH+:$INFOPATH}"

export GPG_TTY=${GPG_TTY-$(tty)}
