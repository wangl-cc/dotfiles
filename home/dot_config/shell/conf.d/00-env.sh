# Shared environment for interactive bash and zsh.

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
export XDG_CONFIG_HOME XDG_DATA_HOME

export WAKATIME_HOME="$XDG_CONFIG_HOME/wakatime"
export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"

# Prevent tar from creating ._ files on macOS.
export COPYFILE_DISABLE=1

export LS_COLORS="${LS_COLORS:-di=1;34:ex=1;32:fi=39:pi=33:so=1;31:bd=1;33:cd=1;33:ln=36:or=31}"
export VISUAL="${VISUAL:-vi}"
