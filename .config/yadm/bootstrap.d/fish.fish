function colorize
    echo "\033[1;$argv[1]m$argv[2]\033[0m"
end

not set -q CURRENT_INDENT; and set -g CURRENT_INDENT 0

function echo_indent
    echo -n (string repeat -n $CURRENT_INDENT "  ")
    echo -e $argv
end

function echo_title
    echo_indent (colorize $ACTION_COLOR $argv[1]) (colorize $TARGET_COLOR $argv[2])
    set -g CURRENT_INDENT (math $CURRENT_INDENT + 1)
end

function echo_done
    set -g CURRENT_INDENT (math $CURRENT_INDENT - 1)
    echo_indent (colorize $ACTION_COLOR Done)"!"
end

function echo_setup
    echo_title "Setting up" $argv[1]
end

echo
echo_setup "fish shell"

function set_Ux_verbose
    set -l var $argv[1]
    set -l val $argv[2..-1]

    test "$$var" = "$val"
    and set -Uq "$var"
    and return

    echo_indent "Set universal variable $(colorize 34 $var) to $(colorize 33 $val)"
    set -Ux $var $val
end

set -g newpaths

if type -q brew
    echo_setup "Homebrew environment variables"
    set_Ux_verbose HOMEBREW_PREFIX (brew --prefix)
    set_Ux_verbose HOMEBREW_CELLAR (brew --cellar)
    set_Ux_verbose HOMEBREW_REPOSITORY (brew --repo)
    echo_done

    set -a newpaths $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin

    # Check if we need to set up Homebrew mirrors (HOMEBREW_MIRROR_DOMAIN is set)
    if test -n "$HOMEBREW_MIRROR_DOMAIN"
        echo_setup "Homebrew mirrors"
        set_Ux_verbose HOMEBREW_API_DOMAIN "$HOMEBREW_MIRROR_DOMAIN/homebrew-bottles/api"
        set_Ux_verbose HOMEBREW_BOTTLE_DOMAIN "$HOMEBREW_MIRROR_DOMAIN/homebrew-bottles"
        echo_done
    end
end

set -a newpaths $HOME/.local/bin $HOME/.cargo/bin $HOME/.local/share/bob/nvim-bin

if set -q newpaths[1]
    set -l to_add

    echo_setup fish_user_paths

    for path in $newpaths
        not test -d "$path"; and continue

        contains -- $path $fish_user_paths; and continue
        or contains -- $path $to_add; and continue

        set -a to_add $path
        echo_indent "Detact path: $(colorize 33 $path)"
    end

    if set -q to_add[1]
        echo_indent "Prepending detected paths to $(colorize 34 fish_user_paths)"
        set -Upx --path fish_user_paths $to_add
    end

    echo_done
end

echo_done
