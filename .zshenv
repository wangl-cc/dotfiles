export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export ZDOTDIR=$XDG_CONFIG_HOME/zsh
export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime
export GNUPGHOME=$XDG_CONFIG_HOME/gnupg

# Set up Homebrew environment variables and paths
if [ "$(uname -s)" = 'Darwin' ]; then
  if [ "$(uname -m)" = 'arm64' ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  else
    HOMEBREW_PREFIX="/usr/local"
  fi
  if [ -d "$HOMEBREW_PREFIX" ]; then
    export HOMEBREW_PREFIX
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
    path+=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin")
  fi
fi
# Set up local paths
if [ -d "$HOME/.local/bin" ]; then
  path+=("$HOME/.local/bin")
fi
# Set up Cargo paths
if [ -d "$HOME/.cargo/bin" ]; then
  path+=("$HOME/.cargo/bin")
fi
export PATH
