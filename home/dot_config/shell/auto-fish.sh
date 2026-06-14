# Enter fish for interactive fallback shells without requiring chsh.

case "$-" in
    *i*) ;;
    *) return 0 2>/dev/null || exit 0 ;;
esac

if [ "${DOT_AUTO_FISH:-1}" = "0" ] || [ "${DOT_AUTO_FISH_ENTERED:-}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi

if [ "${DOT_IN_FISH:-}" = "1" ] || [ -n "${FISH_VERSION:-}" ]; then
    return 0 2>/dev/null || exit 0
fi

_dot_auto_fish_portable_enabled() {
    case "${DOT_AUTO_FISH_PORTABLE:-0}" in
        1|true|yes|on) return 0 ;;
        *) return 1 ;;
    esac
}

_dot_auto_fish_aqua_path() {
    if [ -n "${AQUA_ROOT_DIR:-}" ]; then
        printf '%s\n' "$AQUA_ROOT_DIR/bin/fish"
    else
        printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua/bin/fish"
    fi
}

_dot_auto_fish_is_aqua_path() {
    [ "$1" = "$(_dot_auto_fish_aqua_path)" ] ||
        [ "$1" = "$HOME/.local/share/aquaproj-aqua/bin/fish" ]
}

_dot_auto_fish_aqua_root() {
    if [ -n "${AQUA_ROOT_DIR:-}" ]; then
        printf '%s\n' "$AQUA_ROOT_DIR"
    else
        printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua"
    fi
}

_dot_auto_fish_find() {
    if [ -n "${DOT_FISH:-}" ] && [ -x "$DOT_FISH" ]; then
        printf '%s\n' "$DOT_FISH"
        return 0
    fi

    if command -v fish >/dev/null 2>&1; then
        fish_path=$(command -v fish)
        if _dot_auto_fish_portable_enabled || ! _dot_auto_fish_is_aqua_path "$fish_path"; then
            printf '%s\n' "$fish_path"
            return 0
        fi
    fi

    for fish_path in \
        "${HOMEBREW_PREFIX:-}/bin/fish" \
        "$HOME/.local/bin/fish" \
        "$HOME/.nix-profile/bin/fish" \
        "/opt/homebrew/bin/fish" \
        "/usr/local/bin/fish" \
        "/home/linuxbrew/.linuxbrew/bin/fish" \
        "/usr/bin/fish" \
        "/bin/fish"
    do
        if [ -x "$fish_path" ]; then
            printf '%s\n' "$fish_path"
            return 0
        fi
    done

    if _dot_auto_fish_portable_enabled; then
        for fish_path in \
            "$(_dot_auto_fish_aqua_path)" \
            "$HOME/.local/share/aquaproj-aqua/bin/fish"
        do
            if [ -x "$fish_path" ]; then
                printf '%s\n' "$fish_path"
                return 0
            fi
        done
    fi

    return 1
}

_dot_auto_fish_data_dir() {
    for data_dir in "${DOT_FISH_DATA_DIR:-}" "$(dirname "$_dot_auto_fish")/../share/fish"; do
        if [ -d "$data_dir" ]; then
            printf '%s\n' "$data_dir"
            return 0
        fi
    done

    if _dot_auto_fish_is_aqua_path "$_dot_auto_fish"; then
        aqua_root=$(_dot_auto_fish_aqua_root)
        for data_dir in "$aqua_root"/pkgs/github_release/github.com/fish-shell/fish-shell/*/*/fish.pkg/Payload/usr/local/share/fish; do
            if [ -d "$data_dir" ]; then
                printf '%s\n' "$data_dir"
                return 0
            fi
        done
    fi

    return 1
}

if ! _dot_auto_fish="$(_dot_auto_fish_find)"; then
    return 0 2>/dev/null || exit 0
fi

if _dot_auto_fish_data="$(_dot_auto_fish_data_dir)"; then
    export DOT_FISH_DATA_DIR="$_dot_auto_fish_data"
fi

export DOT_AUTO_FISH_ENTERED=1
export SHELL="$_dot_auto_fish"
exec "$_dot_auto_fish" -l
