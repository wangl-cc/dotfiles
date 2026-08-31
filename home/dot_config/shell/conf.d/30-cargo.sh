# Cargo (Rust toolchain) bin directory.

case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *) [ -d "$HOME/.cargo/bin" ] && PATH="$HOME/.cargo/bin:$PATH" ;;
esac
export PATH
