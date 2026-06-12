function try_add_path
    set -l path $argv[1]
    if test -d $path; and not contains -- "$path" $PATH
        fish_add_path -g $path
    end
end

set -l aqua_root
if set -q AQUA_ROOT_DIR
    set aqua_root $AQUA_ROOT_DIR
else if set -q XDG_DATA_HOME
    set aqua_root $XDG_DATA_HOME/aquaproj-aqua
else
    set aqua_root $HOME/.local/share/aquaproj-aqua
end

try_add_path $aqua_root/bin
try_add_path $HOME/.local/bin
try_add_path $HOME/.cargo/bin
try_add_path $HOME/.bun/bin
