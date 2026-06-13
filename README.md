# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Bootstrap

On a new machine, install `chezmoi` into the user directory, then apply this
repo:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
chezmoi init --apply --promptDefaults --promptChoice packages.provider=aqua https://github.com/wangl-cc/dotfiles.git
```

`packages.provider` is stored in `~/.config/chezmoi/chezmoi.toml` and controls
how portable CLI packages are installed on this machine:

- `aqua`: install `aqua` rootlessly and use it for portable CLI packages.
- `brew`: use Homebrew for portable CLI packages.
- `none`: do not install portable CLI packages automatically.

Without `--promptChoice`, `chezmoi init` prompts for the provider. Use
`--promptDefaults` to choose `none` non-interactively.

After the first bootstrap, normal updates usually only need:

```sh
chezmoi update
```

To change the provider later, run:

```sh
chezmoi edit-config
chezmoi apply
```

Older local configs from the experimental `mise` provider are not migrated
automatically. If `~/.config/chezmoi/chezmoi.toml` contains
`packages.provider = "mise"`, change it to `aqua`, `brew`, or `none` with
`chezmoi edit-config`, then run `chezmoi apply`.

## Package Strategy

- `packages.provider = "brew"` uses Homebrew for common CLI packages.
- `packages.provider = "aqua"` uses `aqua` for common CLI packages.
- `packages.provider = "none"` skips automatic CLI package installation.
- `bun`, `uv`, and `rustup` are language toolchains installed with their
  official installers when requested.

To opt in to language toolchains during the first init:

```sh
chezmoi init --apply \
  --promptChoice packages.provider=aqua \
  --promptBool toolchains.uv=true \
  --promptBool toolchains.rustup=true \
  --promptBool toolchains.bun=false \
  https://github.com/wangl-cc/dotfiles.git
```

Aqua packages are declared in `~/.config/aquaproj-aqua/aqua.yaml`. Renovate
updates that file in GitHub. When `chezmoi update` or `chezmoi apply` sees that
`aqua.yaml` changed, it runs `aqua install --all --only-link` automatically.
Set `CHEZMOI_AQUA_EAGER_INSTALL=1` to download all declared aqua packages
instead of relying on lazy install.

The package set uses `lsd` as the `ls` replacement for both Homebrew and aqua.
It publishes macOS and Linux release binaries, which keeps rootless aqua
installs independent of Rust or Cargo.

Homebrew itself is not installed by default. To allow chezmoi to install it on
machines where that is appropriate, choose the `brew` provider and set:

```sh
CHEZMOI_AUTO_INSTALL_HOMEBREW=1 chezmoi init --apply --promptChoice packages.provider=brew https://github.com/wangl-cc/dotfiles.git
```

## Fish

`fish` is the primary interactive shell. On systems where changing the login
shell is not allowed, keep the system login shell; interactive bash/zsh sessions
will automatically enter fish when it is available.

To start a shell without this automatic handoff:

```sh
DOT_AUTO_FISH=0 bash
```
