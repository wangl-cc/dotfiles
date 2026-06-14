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

During the first init, chezmoi prompts once for machine-local options and stores the answers in `~/.config/chezmoi/chezmoi.toml`:

- `portable_fish`: default `false`. Enable it if this machine should use the aqua-managed fish binary and the bash/zsh automatic handoff should be allowed to enter it.
- `toolchains.uv`: default `true`.
- `toolchains.bun`: default `true`.
- `toolchains.rustup`: default `false`.
- `git.signingkeyFile`: choose a public key found in `~/.ssh/*.pub` by filename stem, such as `id_ed25519`, or choose `none` to leave signing off.

For scripted bootstrap only, pass machine-local answers with `--override-data`:

```sh
chezmoi init --apply \
  --override-data '{"portable_fish":false,"toolchains":{"uv":true,"rustup":false,"bun":true},"git":{"signingkeyFile":"$HOME/.ssh/id_ed25519.pub"}}' \
  https://github.com/wangl-cc/dotfiles.git
```

Use `--promptDefaults` to choose defaults non-interactively. Prefer `--override-data` when scripted bootstrap needs non-default answers; chezmoi's `--prompt...` flags match the human prompt text and are more brittle.

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
- `uv` and `bun` default to installed with their official installers and can be used to install ecosystem CLIs.
- `rustup` defaults to off and installs the Rust toolchain with the official installer when enabled.

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
