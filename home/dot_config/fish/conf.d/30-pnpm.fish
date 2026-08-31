# pnpm home: global installs, bins, and store.
set -gx PNPM_HOME $HOME/.pnpm

try_add_path $PNPM_HOME/bin
