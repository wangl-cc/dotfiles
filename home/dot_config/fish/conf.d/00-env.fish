# Force some programs use XDG_CONFIG_HOME
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx WAKATIME_HOME $XDG_CONFIG_HOME/wakatime
set -gx GNUPGHOME $XDG_CONFIG_HOME/gnupg

# Prevent tar from creating ._ files on macOS
set -gx COPYFILE_DISABLE 1

# Color for ls and friends (eza or other ls alternatives)
set -gx LS_COLORS "di=1;34:ex=1;32:fi=39:pi=33:so=1;31:bd=1;33:cd=1;33:ln=36:or=31"

set -gx VISUAL vi
