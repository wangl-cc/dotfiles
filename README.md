# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Bootstrap

On a new machine, install `chezmoi` into the user directory and apply this repo:

```sh
curl -fsLS https://get.chezmoi.io | sh -s -- \
  -b "$HOME/.local/bin" \
  init --apply https://github.com/wangl-cc/dotfiles.git
```

The bootstrap always installs `aqua` rootlessly and uses it for portable CLI packages on macOS and Linux. The normal package manifest is `~/.config/aquaproj-aqua/aqua.yaml`.

During the first init, chezmoi prompts once for machine-local options and stores the answers in `~/.config/chezmoi/chezmoi.toml`:

- `shell.fish.auto`: default `true`. Enter fish automatically from fallback bash/zsh sessions.
- `shell.fish.portable`: default `false`. Install fish with aqua and allow auto-fish to use it.
- `toolchains.uv`: default `true`.
- `toolchains.bun`: default `true`.
- `toolchains.rustup`: default `none`; choose `minimal`, `default`, or `complete` to install rustup with that profile.
- `git.signingkeyFile`: choose a public key found in `~/.ssh/*.pub` by filename stem, such as `id_ed25519`, or choose `none` to leave signing off.

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

If the local config schema changes, regenerate the machine-local config:

```sh
chezmoi init --prompt --apply https://github.com/wangl-cc/dotfiles.git
```

## Package Strategy

- `aqua` is bootstrapped into the user directory and installs common CLI packages on macOS and Linux.
- `shell.fish.portable = true` opts this machine into installing fish through aqua.
- `uv` and `bun` default to installed with their official installers and can be used to install ecosystem CLIs.
- `rustup` defaults to `none`. Choose `minimal`, `default`, or `complete` to install it with the official installer and that profile.

Aqua packages are declared directly in `~/.config/aquaproj-aqua/aqua.yaml` so Renovate can update that file in GitHub. Optional portable fish lives in `~/.config/aquaproj-aqua/fish.yaml` and is only enabled when `shell.fish.portable = true`.

When `chezmoi update` or `chezmoi apply` sees that an aqua manifest changed, it runs `aqua install --all` before applying templates for the enabled aqua manifests.

Homebrew can still be installed and used manually for macOS-specific software, GUI applications, or system packages, but it is not used by this bootstrap to install portable CLI packages.

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell and leave `shell.fish.auto = true`; interactive bash/zsh sessions will automatically enter fish when it is available. On machines where the login shell is already fish, set `shell.fish.auto = false`.

Auto-fish is only for fallback bash/zsh sessions. Fish sessions do not source it, and fish exports `_CHEZMOI_FISH_SESSION=1` so child bash/zsh shells stay in the shell that was explicitly started.

Auto-fish uses the first `fish` found in `PATH`. Set `shell.fish.portable = true` with `chezmoi edit-config` when this machine should install fish with aqua; aqua's bin directory is added to `PATH` before auto-fish runs.

To start a shell without this automatic handoff:

```sh
bash --norc
zsh -f
```
