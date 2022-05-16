typeset -U PATH path

if [ -f /opt/homebrew/bin/brew ]; then
    export HOMEBREW_PREFIX=$(/opt/homebrew/bin/brew --prefix)
    export HOMEBREW_CELLAR=$(/opt/homebrew/bin/brew --cellar)
    export HOMEBREW_REPOSITORY=$(/opt/homebrew/bin/brew --repository)
elif [ -f /usr/local/bin/brew ]; then
    export HOMEBREW_PREFIX=$(/usr/local/bin/brew --prefix)
    export HOMEBREW_CELLAR=$(/usr/local/bin/brew --cellar)
    export HOMEBREW_REPOSITORY=$(/usr/local/bin/brew --repository)
fi

path=("$HOME/.local/bin" "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "$path[@]")
export PATH
