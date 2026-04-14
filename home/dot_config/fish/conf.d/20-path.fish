function try_add_path
    set -l path $argv[1]
    if test -d $path; and not contains -- "$path" $PATH
        fish_add_path -g $path
    end
end

try_add_path $HOME/.local/bin
try_add_path $HOME/.cargo/bin
try_add_path $HOME/.bun/bin
