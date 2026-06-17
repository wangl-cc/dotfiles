# Aqua global config location and PATH entry.
# Keep the machine-local manifest first so `aqua generate -g -i` writes there.
set -gx --path AQUA_GLOBAL_CONFIG \
    $XDG_CONFIG_HOME/aquaproj-aqua/local.yaml \
    $XDG_CONFIG_HOME/aquaproj-aqua/shared.yaml

set -l aqua_root
if set -q AQUA_ROOT_DIR
    set aqua_root $AQUA_ROOT_DIR
else if set -q XDG_DATA_HOME
    set aqua_root $XDG_DATA_HOME/aquaproj-aqua
else
    set aqua_root $HOME/.local/share/aquaproj-aqua
end

try_add_path $aqua_root/bin

set -e aqua_root
