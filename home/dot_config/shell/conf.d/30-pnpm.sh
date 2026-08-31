# pnpm home: global installs, bins, and store.

export PNPM_HOME="$HOME/.pnpm"

case ":$PATH:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) [ -d "$PNPM_HOME/bin" ] && PATH="$PNPM_HOME/bin:$PATH" ;;
esac
export PATH
