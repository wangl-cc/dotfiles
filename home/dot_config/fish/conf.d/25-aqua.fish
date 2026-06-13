# Aqua global config location and PATH entry.
# Relies on try_add_path, defined in 20-path.fish (must run after it).
set -gx AQUA_GLOBAL_CONFIG $XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml

set -l aqua_root
if set -q AQUA_ROOT_DIR
    set aqua_root $AQUA_ROOT_DIR
else if set -q XDG_DATA_HOME
    set aqua_root $XDG_DATA_HOME/aquaproj-aqua
else
    set aqua_root $HOME/.local/share/aquaproj-aqua
end

try_add_path $aqua_root/bin
