# Force some programs use XDG_CONFIG_HOME
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx WAKATIME_HOME $XDG_CONFIG_HOME/wakatime
set -gx GNUPGHOME $XDG_CONFIG_HOME/gnupg

# Some rootless fish packages are launched from a non-standard prefix while
# their bundled functions and completions live next to the extracted package.
if test -n "$DOT_FISH_DATA_DIR"; and test -d "$DOT_FISH_DATA_DIR"
    set -g __fish_data_dir "$DOT_FISH_DATA_DIR"

    for completions_dir in "$DOT_FISH_DATA_DIR/completions" "$DOT_FISH_DATA_DIR/vendor_completions.d"
        if test -d "$completions_dir"; and not contains -- "$completions_dir" $fish_complete_path
            set -g fish_complete_path $fish_complete_path "$completions_dir"
        end
    end

    for functions_dir in "$DOT_FISH_DATA_DIR/functions" "$DOT_FISH_DATA_DIR/vendor_functions.d"
        if test -d "$functions_dir"; and not contains -- "$functions_dir" $fish_function_path
            set -g fish_function_path $fish_function_path "$functions_dir"
        end
    end
end

# Prevent tar from creating ._ files on macOS
set -gx COPYFILE_DISABLE 1

# Color for ls and friends (eza or other ls alternatives)
set -gx LS_COLORS "di=1;34:ex=1;32:fi=39:pi=33:so=1;31:bd=1;33:cd=1;33:ln=36:or=31"

set -gx VISUAL vi

# Let fallback shells know they were launched from fish.
set -gx DOT_IN_FISH 1
