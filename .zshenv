typeset -U PATH path

if [ $(uname -s) = "Darwin" ]; then
    if [[ $(uname -m) = "arm64" && -f /opt/homebrew/bin/brew ]]; then
        export HOMEBREW_PREFIX=$(/opt/homebrew/bin/brew --prefix)
        export HOMEBREW_CELLAR=$(/opt/homebrew/bin/brew --cellar)
        export HOMEBREW_REPOSITORY=$(/opt/homebrew/bin/brew --repository)
        path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "$path[@]")
    elif [ -f /usr/local/bin/brew ]; then
        export HOMEBREW_PREFIX=$(/usr/local/bin/brew --prefix)
        export HOMEBREW_CELLAR=$(/usr/local/bin/brew --cellar)
        export HOMEBREW_REPOSITORY=$(/usr/local/bin/brew --repository)
        path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "$path[@]")
    else
        echo "Homebrew is not installed."
    fi
fi
path=("$HOME/.local/bin" "$path[@]")

export PATH
