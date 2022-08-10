typeset -U PATH path

export CONDARC_MIRROR="bfsu.edu.cn"

export HOMEBREW_PREFIX=$(/opt/homebrew/bin/brew --prefix)
export HOMEBREW_CELLAR=$(/opt/homebrew/bin/brew --cellar)
export HOMEBREW_REPOSITORY=$(/opt/homebrew/bin/brew --repository)
path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "$path[@]")

path=("$HOME/.local/bin" "$path[@]")
export PATH
