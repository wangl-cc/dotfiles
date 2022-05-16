typeset -U manpath MANPATH INFOPATH
manpath=("" "$HOMEBREW_PREFIX/share/man" "$manpath[@]")
export MANPATH
export INFOPATH="$HOMEBREW_PREFIX/share/info${INFOPATH+:$INFOPATH}"
