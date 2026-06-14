# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Bootstrap

On a new machine, install `chezmoi` into the user directory, then apply this repo:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/share/aquaproj-aqua/bin:$HOME/.local/bin:$PATH"
chezmoi init --apply https://github.com/wangl-cc/dotfiles.git
```

The bootstrap always installs `aqua` rootlessly and uses it for portable CLI packages on macOS and Linux. The normal package manifest is `~/.config/aquaproj-aqua/aqua.yaml`.

Git SSH commit signing can be configured during bootstrap. The interactive prompt lists public keys found in `~/.ssh/*.pub` by filename stem, such as `id_ed25519`; choose `none` to leave signing off. For scripted or non-standard paths, set `git.signingkeyFile` to this machine's public signing key path, for example `$HOME/.ssh/id_ed25519.pub` or `~/.ssh/id_ed25519.pub`.

`fish` is not installed by default. Set `portable_fish=true` if this machine should use the aqua-managed fish binary and the bash/zsh automatic handoff should be allowed to enter it.

For a non-interactive bootstrap, pass the public key file path:

```sh
chezmoi init --apply \
  --override-data '{"portable_fish":false,"git":{"signingkeyFile":"$HOME/.ssh/id_ed25519.pub"}}' \
  https://github.com/wangl-cc/dotfiles.git
```

Without overrides, `chezmoi init` prompts for machine-local options. Use `--promptDefaults` to choose defaults non-interactively, including leaving portable fish and Git SSH commit signing disabled. Prefer `--override-data` for scripted bootstraps; chezmoi's `--prompt...` flags match the human prompt text.

After the first bootstrap, normal updates usually only need:

```sh
chezmoi update
```

To change machine-local options later, run:

```sh
chezmoi edit-config
chezmoi apply
```

Older local configs may still contain `packages.provider`; it is ignored and can be removed with `chezmoi edit-config`.

## Package Strategy

- `aqua` is bootstrapped into the user directory and installs common CLI packages on macOS and Linux.
- `portable_fish = true` opts this machine into installing fish through aqua.
- `bun`, `uv`, and `rustup` are language toolchains installed with their official installers when requested.

To opt in to language toolchains during the first init:

```sh
chezmoi init --apply \
  --override-data '{"portable_fish":false,"toolchains":{"uv":true,"rustup":true,"bun":false},"git":{"signingkeyFile":""}}' \
  https://github.com/wangl-cc/dotfiles.git
```

Aqua packages are declared directly in `~/.config/aquaproj-aqua/aqua.yaml` so Renovate can update that file in GitHub. Optional portable fish lives in `~/.config/aquaproj-aqua/fish.yaml` and is only enabled when `portable_fish = true`.

When `chezmoi update` or `chezmoi apply` sees that an aqua manifest changed, it runs `aqua install --all --only-link` before applying templates for the normal package set. When portable fish is enabled, fish is installed eagerly from `fish.yaml` so the automatic bash/zsh handoff does not depend on a lazy aqua shim. Set `CHEZMOI_AQUA_EAGER_INSTALL=1` to download all enabled aqua packages instead of relying on lazy install.

The package set uses `lsd` as the `ls` replacement. It publishes macOS and Linux release binaries, which keeps rootless aqua installs independent of Rust or Cargo.

Homebrew can still be installed and used manually for macOS-specific software, GUI applications, or system packages, but it is not used by this bootstrap to install portable CLI packages.

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell; interactive bash/zsh sessions will automatically enter fish when it is available.

By default, auto-fish uses fish provided by the system, Homebrew, Nix, or another non-aqua install. Set `portable_fish = true` with `chezmoi edit-config` when this machine should use fish from aqua. This sets `DOT_AUTO_FISH_PORTABLE=1` for fallback bash/zsh sessions.

To start a shell without this automatic handoff:

```sh
DOT_AUTO_FISH=0 bash
```
