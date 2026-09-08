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
- `toolchains.node`: default `true`; pnpm installs the latest Node.js LTS release.
- `toolchains.rustup`: default `none`; choose `minimal`, `default`, or `complete` to install rustup with that profile.
- `git.signingkeyFile`: choose a public key found in `~/.ssh/*.pub` by filename stem, such as `id_ed25519`, or choose `none` to leave signing off.
- `tailscale.ipv4`: default empty. Enter this machine's Tailscale IPv4 address to publish the Samba container on that address. An empty value leaves SMB unpublished.

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

- Portable standalone CLI packages are declared in `home/.chezmoidata/portable-pkgs.yaml` and installed by chezmoi externals on macOS and Linux.
- `uv` and `uvx` are installed together from the pinned `uv` release archive and can install or run Python ecosystem CLIs.
- pnpm is installed as a standalone portable binary, then installs the latest Node.js LTS release and provides `pnpm dlx` for one-off JavaScript or TypeScript CLIs.
- `rustup` defaults to `none`. Choose `minimal`, `default`, or `complete` to install it with the official installer and that profile.

The portable package manifest renders a managed block in `home/.chezmoiexternal.toml.tmpl` when chezmoi applies templates.

Homebrew can still be installed and used manually for macOS-specific software, GUI applications, or system packages, but it is not used by this bootstrap to install portable CLI packages.

### Portable Packages

`portable-pkgs` is a small uv/Python helper for standalone release packages that can be installed directly by chezmoi without an aqua shim. A package can own one binary or multiple real binaries from the same archive. Its manifest lives in `home/.chezmoidata/portable-pkgs.yaml`. The helper only maintains that manifest; `home/.chezmoiexternal.toml.tmpl` reads the chezmoi data directly and renders the external entries itself.

Smart `add` downloads selected archives when it must infer or verify member paths. `update --verify` downloads, checks, and extracts every target touched by an update before writing the manifest; multi-binary updates always perform this member verification even without `--verify`. Because each package has one release tag, `update` refreshes all targets for the selected package; `inspect` and `verify` can still select one target. Markdown update reports link each updated tag to its GitHub release notes. An implicit update reports and skips a GitHub `latest` release whose SemVer is older than the configured tag; pass `--tag` to request a downgrade explicitly. Run `verify` separately when you want to check existing manifest entries. If the selected release asset is missing a GitHub `sha256` digest or the archive path needs manual inspection, use `inspect --save` for that explicit download-and-record path.

The manifest separates input rules from resolved release metadata. A single-binary package uses `bin` and an optional `path_pattern`; a multi-binary package uses `bins` to map each command to its archive path pattern. Per target, `asset_pattern` selects the GitHub release asset. Resolved metadata records the shared asset and checksum plus either one path or a command-to-member mapping; chezmoi renders only resolved targets. Manifest fields are strictly checked so typos, invalid regexes, unsafe relative paths, destination collisions, and mismatched binary sets fail before chezmoi renders them. The helper defaults to `~/.local/share/chezmoi/home/.chezmoidata/portable-pkgs.yaml`; set `PORTABLE_PKGS_MANIFEST` to use a different file.

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

portable-pkgs add uv astral-sh/uv \
  --bin uv \
  --bin uvx \
  --verify \
  --non-interactive
```

## Containers

All custom container images are pinned to Fedora 44 to follow the workstation host's release. `dev-box` and `codex-box` share the base in `dev-box/Containerfile`; Samba uses `smb-box/Containerfile`. When upgrading the host to a new Fedora release, update both `FROM` tags together and update the release references in the container documentation. This is a maintenance convention; host upgrades do not automatically edit these files or rebuild containers.

After updating the sources, rebuild and restart on the host: `dev-box-build.service` then `dev-box.service`, `box-base-build.service` then `codex-box.service`, and `smb-box-build.service` then `smb-box.service`, using `systemctl --user restart` for each unit. Confirm each build succeeds before restarting its container, then verify SSH access, Codex connectivity, and SMB login and file access. See the [development container guide](docs/dev-containers.md) and [Samba guide](smb-box/README.md) for their operational checks.

The workstation uses user-level Podman Quadlets under `home/dot_config/containers/systemd/`. The [Samba container](smb-box/README.md) provides a `public` share over Tailscale, with host directories such as `~/Documents` mounted beneath it through Quadlet. It uses a Fedora image, native Samba configuration, and a persistent account database. Its build context and rootfs live in `smb-box/`.

For an existing chezmoi configuration, run `chezmoi edit-config` and add `ipv4 = "<your Tailscale IPv4>"` to the existing `[data.tailscale]` table. Alternatively, run `chezmoi init --prompt` to fill the new prompt while retaining existing answers. Missing or empty `tailscale.ipv4` values leave the Samba port unpublished, so existing configurations continue to render. After setting or changing the address, inspect the diff, apply the Samba network drop-in, reload the user manager, and restart the container as described in the Samba guide. The template reads this saved value without invoking Tailscale.

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell and leave `shell.fish.auto = true`; interactive bash/zsh sessions will automatically enter fish when it is available. On machines where the login shell is already fish, set `shell.fish.auto = false`.

Auto-fish is only for fallback bash/zsh sessions. Fish sessions do not source it, and fish exports `_CHEZMOI_FISH_SESSION=1` so child bash/zsh shells stay in the shell that was explicitly started.

To start a shell without this automatic handoff:

```sh
bash --norc
zsh -f
```
