# Portable packages

- Portable standalone CLI packages are declared in `home/.chezmoidata/portable-pkgs.yaml` and installed by chezmoi externals on macOS and Linux.
- `uv` and `uvx` are installed together from the pinned `uv` release archive and can install or run Python ecosystem CLIs.
- pnpm is installed as a standalone portable binary, then installs the latest Node.js LTS release and provides `pnpm dlx` for one-off JavaScript or TypeScript CLIs.
- `rustup` defaults to `none`. Choose `minimal`, `default`, or `complete` to install it with the official installer and that profile.

The portable package manifest renders a managed block in `home/.chezmoiexternal.toml.tmpl` when chezmoi applies templates.

Homebrew can still be installed and used manually for macOS-specific software, GUI applications, or system packages, but it is not used by this bootstrap to install portable CLI packages.

## Manifest helper

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
