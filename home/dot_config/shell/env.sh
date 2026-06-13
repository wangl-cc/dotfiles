# Shared interactive-shell environment for bash and zsh.
# Prepends aqua's bin directory to PATH and hands off to fish for
# interactive fallback shells. Sourced from .bashrc and .zshrc.

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
export XDG_CONFIG_HOME XDG_DATA_HOME

export AQUA_GLOBAL_CONFIG="${AQUA_GLOBAL_CONFIG:-$XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml}"

if [ -z "${AQUA_ROOT_DIR:-}" ]; then
    aqua_root="$XDG_DATA_HOME/aquaproj-aqua"
else
    aqua_root="$AQUA_ROOT_DIR"
fi
if [ -d "$aqua_root/bin" ]; then
    PATH="$aqua_root/bin:$PATH"
fi
unset aqua_root
export PATH

# Enter fish for interactive fallback shells without requiring chsh.
auto_fish="$HOME/.config/shell/auto-fish.sh"
if [ -r "$auto_fish" ]; then
    . "$auto_fish"
fi
unset auto_fish
