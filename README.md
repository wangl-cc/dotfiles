# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Bootstrap

On a new machine, install `chezmoi` into the user directory and apply this repo:

```sh
curl -fsLS https://get.chezmoi.io | sh -s -- \
  -b "$HOME/.local/bin" \
  init --apply https://github.com/wangl-cc/dotfiles.git
```

The bootstrap installs standalone portable CLI packages with chezmoi externals.

During the first init, chezmoi prompts once for machine-local options and stores the answers in `~/.config/chezmoi/chezmoi.toml`:

- `shell.fish.auto`: default `true`. Enter fish automatically from fallback bash/zsh sessions.
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

- Portable standalone CLI packages are declared in
  `home/.chezmoidata/portable-pkgs.yaml` and installed by chezmoi externals on
  macOS and Linux.
- `uv` and `bun` default to installed with their official installers and can be used to install ecosystem CLIs.
- `rustup` defaults to `none`. Choose `minimal`, `default`, or `complete` to install it with the official installer and that profile.

The portable package manifest renders a managed block in
`home/.chezmoiexternal.toml.tmpl` when chezmoi applies templates.

Homebrew can still be installed and used manually for macOS-specific software, GUI applications, or system packages, but it is not used by this bootstrap to install portable CLI packages.

### Portable Packages

`portable-pkgs` is a small uv/Python helper for standalone release
binaries that can be installed directly by chezmoi without an aqua shim. Its
manifest lives in `home/.chezmoidata/portable-pkgs.yaml`. The helper only
maintains that manifest; `home/.chezmoiexternal.toml.tmpl` reads the chezmoi data
directly and renders the external entries itself.

Normal `add` and `update` commands use GitHub release metadata only and do not
download assets. Use `update --verify` to update metadata and then download,
check, and extract every target touched by that update before writing the
manifest. Because each tool has one release tag, `update` refreshes all targets
for the selected tool; `inspect` and `verify` can still select one target. Run
`verify` separately when you want to check existing manifest entries. If the
selected release asset is missing a GitHub `sha256` digest or the archive path
needs manual inspection, use `inspect --save` for that explicit
download-and-record path:

The manifest separates input rules from resolved release metadata. Per tool,
`path_pattern` describes the usual archive layout. Per target, `asset_pattern`
selects the GitHub release asset. `resolved.type`, `resolved.asset`,
`resolved.path`, and `resolved.sha256` are the real values written by `add`,
`update`, or
`inspect --save`; chezmoi renders only resolved targets. Manifest fields are
strictly checked so typos, invalid regexes, unsafe relative paths, and mismatched
asset types fail before chezmoi renders them. The helper defaults to
`~/.local/share/chezmoi/home/.chezmoidata/portable-pkgs.yaml`; set
`PORTABLE_PKGS_MANIFEST` to use a different file.

```sh
portable-pkgs add fd sharkdp/fd \
  --bin fd \
  -Tdarwin-aarch64='aarch64-apple-darwin.*\.tar\.gz$' \
  -Tlinux-x86_64='x86_64-unknown-linux-gnu.*\.tar\.gz$' \
  --path-pattern '{assetStem}/fd'

portable-pkgs inspect fd --target darwin-aarch64 --save
portable-pkgs verify fd
portable-pkgs update fd
portable-pkgs update fd --verify
portable-pkgs update fd --tag v10.4.2
portable-pkgs remove fd
```

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell and leave `shell.fish.auto = true`; interactive bash/zsh sessions will automatically enter fish when it is available. On machines where the login shell is already fish, set `shell.fish.auto = false`.

Auto-fish is only for fallback bash/zsh sessions. Fish sessions do not source it, and fish exports `_CHEZMOI_FISH_SESSION=1` so child bash/zsh shells stay in the shell that was explicitly started.

To start a shell without this automatic handoff:

```sh
bash --norc
zsh -f
```
