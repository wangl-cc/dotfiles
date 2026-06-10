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

_dot_auto_fish_find() {
    if [ -n "${DOT_FISH:-}" ] && [ -x "$DOT_FISH" ]; then
        printf '%s\n' "$DOT_FISH"
        return 0
    fi

    if command -v fish >/dev/null 2>&1; then
        command -v fish
        return 0
    fi

    for fish_path in \
        "${HOMEBREW_PREFIX:-}/bin/fish" \
        "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims/fish" \
        "$HOME/.local/share/mise/shims/fish" \
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

    return 1
}

_dot_auto_fish_data_dir() {
    for data_dir in \
        "${DOT_FISH_DATA_DIR:-}" \
        "${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/aqua-fish-shell-fish-shell/latest/fish.pkg/Payload/usr/local/share/fish" \
        "$HOME/.local/share/mise/installs/aqua-fish-shell-fish-shell/latest/fish.pkg/Payload/usr/local/share/fish" \
        "$(dirname "$_dot_auto_fish")/../share/fish" \
        "${HOMEBREW_PREFIX:-}/share/fish" \
        "/opt/homebrew/share/fish" \
        "/usr/local/share/fish" \
        "/usr/share/fish"
    do
        if [ -d "$data_dir" ]; then
            printf '%s\n' "$data_dir"
            return 0
        fi
    done

    return 1
}

if ! _dot_auto_fish="$(_dot_auto_fish_find)"; then
    return 0 2>/dev/null || exit 0
fi

if _dot_auto_fish_data="$(_dot_auto_fish_data_dir)"; then
    export DOT_FISH_DATA_DIR="$_dot_auto_fish_data"
fi

export DOT_AUTO_FISH_ENTERED=1
exec "$_dot_auto_fish" -l
