# User-local tool paths.

for shell_path in \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.bun/bin"
do
    case ":$PATH:" in
        *":$shell_path:"*) ;;
        *) [ -d "$shell_path" ] && PATH="$shell_path:$PATH" ;;
    esac
done

unset shell_path
export PATH
