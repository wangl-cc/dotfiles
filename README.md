# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Bootstrap

On a new machine, install `chezmoi` into the user directory, then apply this
repo:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
CHEZMOI_BOOTSTRAP_TOOLCHAINS=1 chezmoi init --apply https://github.com/wangl-cc/dotfiles.git
```

`CHEZMOI_BOOTSTRAP_TOOLCHAINS=1` allows the first apply to install rootless
toolchain managers with their official installers:

- `uv`
- `rustup`
- `mise`

After the first bootstrap, normal updates usually only need:

```sh
chezmoi update
```

## Package Strategy

- If Homebrew is already installed, chezmoi uses it for common CLI packages.
- If Homebrew is not installed, chezmoi skips Homebrew and uses `mise` for the
  portable CLI tools.
- `node` and `bun` are managed by `mise`.
- Python is managed with `uv`.
- Rust is managed with `rustup`.

Homebrew itself is not installed by default. To allow chezmoi to install it on
machines where that is appropriate:

```sh
CHEZMOI_AUTO_INSTALL_HOMEBREW=1 chezmoi apply
```

To combine Homebrew installation with first-time toolchain bootstrap:

```sh
CHEZMOI_BOOTSTRAP_TOOLCHAINS=1 CHEZMOI_AUTO_INSTALL_HOMEBREW=1 chezmoi apply
```

## Fish

`fish` is the primary interactive shell. On systems where changing the login
shell is not allowed, keep the system login shell; interactive bash/zsh sessions
will automatically enter fish when it is available.

To start a shell without this automatic handoff:

```sh
DOT_AUTO_FISH=0 bash
```
