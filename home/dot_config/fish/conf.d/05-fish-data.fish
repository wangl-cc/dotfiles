# Wire up completions and functions for rootless fish installs whose bundled
# data directory is not discovered automatically.
set -l fish_data_dir

if not set -q __fish_data_dir; or not test -d "$__fish_data_dir"
    set -l fish_bin (status fish-path 2>/dev/null)

    if test -n "$fish_bin"
        set -l bundled_data_dir (path normalize (path dirname "$fish_bin")/../share/fish)
        if test -d "$bundled_data_dir"
            set fish_data_dir "$bundled_data_dir"
        end
    end

    if test -z "$fish_data_dir"
        set -l aqua_root
        if set -q AQUA_ROOT_DIR
            set aqua_root $AQUA_ROOT_DIR
        else if set -q XDG_DATA_HOME
            set aqua_root $XDG_DATA_HOME/aquaproj-aqua
        else
            set aqua_root $HOME/.local/share/aquaproj-aqua
        end

        if test -d "$aqua_root/pkgs/github_release/github.com/fish-shell/fish-shell"
            for candidate_dir in "$aqua_root"/pkgs/github_release/github.com/fish-shell/fish-shell/*/*/fish.pkg/Payload/usr/local/share/fish
                if test -d "$candidate_dir"
                    set fish_data_dir "$candidate_dir"
                    break
                end
            end
        end
    end

    if test -n "$fish_data_dir"; and test -d "$fish_data_dir"
        set -g __fish_data_dir "$fish_data_dir"

        function __chezmoi_add_fish_completion_path
            set -l completions_dir $argv[1]
            if not test -d "$completions_dir"; or contains -- "$completions_dir" $fish_complete_path
                return
            end

            set -l generated_index
            for index in (seq (count $fish_complete_path))
                switch $fish_complete_path[$index]
                    case '*/generated_completions'
                        set generated_index $index
                        break
                end
            end

            if test -z "$generated_index"
                set --global --append fish_complete_path "$completions_dir"
            else if test "$generated_index" -eq 1
                set --global fish_complete_path "$completions_dir" $fish_complete_path
            else
                set --global fish_complete_path \
                    $fish_complete_path[1..(math $generated_index - 1)] \
                    "$completions_dir" \
                    $fish_complete_path[$generated_index..-1]
            end
        end

        for completions_dir in "$fish_data_dir/completions" "$fish_data_dir/vendor_completions.d"
            __chezmoi_add_fish_completion_path "$completions_dir"
        end

        for functions_dir in "$fish_data_dir/functions" "$fish_data_dir/vendor_functions.d"
            if test -d "$functions_dir"; and not contains -- "$functions_dir" $fish_function_path
                set --global --append fish_function_path "$functions_dir"
            end
        end

        functions --erase __chezmoi_add_fish_completion_path
    end
end
