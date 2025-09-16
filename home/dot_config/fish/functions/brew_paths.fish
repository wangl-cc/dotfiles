# There are multiple sources of function/completion paths
#
# - user defined
# - system defined
# - vendored
# - fish shipped
# - generated (completion only)
#
# For vendored functions, there might be multiple source:
#
# - installed by user
# - installed by homebrew
# - installed by system package manager
#
# So the final function path order should be:
#
# - user
# - system
# - vendored (user)
# - vendored (homebrew)
# - vendored (system)
# - shipped
# - generated (completion only)

function brew_paths
    set --path fish_function_path \
        $HOME/.config/fish/functions \
        /etc/fish/functions \
        $HOME/.local/share/fish/vendor_functions.d \
        $HOMEBREW_PREFIX/share/fish/vendor_functions.d \
        /usr/share/fish/vendor_functions.d \
        /usr/share/fish/functions

    set --path fish_complete_path \
        $HOME/.config/fish/completions \
        /etc/fish/completions \
        $HOME/.local/share/fish/vendor_completions.d \
        $HOMEBREW_PREFIX/share/fish/vendor_completions.d \
        /usr/share/fish/vendor_completions.d \
        /usr/share/fish/completions \
        $HOME/.cache/fish/generated_completions
end
