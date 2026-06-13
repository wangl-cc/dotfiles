# Wire up completions and functions for a rootless/portable fish install
# launched from a non-standard prefix (e.g. via auto-fish from aqua or
# Homebrew). Their bundled data lives next to the extracted package.
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
