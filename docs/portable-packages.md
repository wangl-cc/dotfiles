# Portable packages

- Portable standalone CLI packages are declared in `home/.chezmoidata/portable-pkgs.yaml` and installed by chezmoi externals on macOS and Linux.
- `uv` and `uvx` are installed together from the pinned `uv` release archive and can install or run Python ecosystem CLIs.
- pnpm is installed as a standalone portable binary, then installs the latest Node.js LTS release and provides `pnpm dlx` for one-off JavaScript or TypeScript CLIs.
- `rustup` defaults to `none`. Choose `minimal`, `default`, or `complete` to install it with the official installer and that profile.

The portable package manifest renders a managed block in `home/.chezmoiexternal.toml.tmpl` when chezmoi applies templates.

Homebrew can still be installed and used manually for macOS-specific software, GUI applications, or system packages, but it is not used by this bootstrap to install portable CLI packages.

## Manifest helper

`portable-pkgs` maintains this repository's standalone release packages and the chezmoi sources they need. It is a local uv project at `portable-pkgs/`, run from the repository root and never installed globally:

```sh
uv run --locked --project portable-pkgs portable-pkgs list
uv run --locked --project portable-pkgs portable-pkgs inspect sharkdp/fd
uv run --locked --project portable-pkgs portable-pkgs update --verify
```

Its manifest is `home/.chezmoidata/portable-pkgs.yaml`, resolved relative to the checkout containing `src/portable_pkgs/` rather than the current directory; `PORTABLE_PKGS_MANIFEST` overrides it. See [the project README](../portable-pkgs/README.md) for the command surface, structure, and validation commands, and the [agent skill](../.agents/skills/portable-pkgs/SKILL.md) for argument syntax.

The commands report facts and apply explicit input: `search` and `inspect` never choose a repository or asset for you, and `add` requires `--type`, a per-target asset regex, and the command list.

```sh
uv run --locked --project portable-pkgs portable-pkgs add fd \
  --repo sharkdp/fd --type archive-files --bin fd \
  -Tdarwin-aarch64='aarch64-apple-darwin.*\.tar\.gz$' \
  -Tlinux-x86_64='x86_64-unknown-linux-musl.*\.tar\.gz$' \
  --path-pattern '{assetStem}/fd' --dry-run --format json
```

A package is `file` (one bare binary), `archive-files` (named members of an archive), or `bundle` (a whole archive under `~/.local/share/portable-pkgs/<name>` plus one symlink per command). The manifest separates input rules from resolved metadata: each target's `asset_pattern` must match exactly one release asset, and the helper records the matched asset, its `sha256`, and the resolved member paths. Fields are strictly validated, so typos, invalid regexes, unsafe relative paths, and duplicate command destinations fail before chezmoi renders anything.

`home/.chezmoiexternal.toml.tmpl` reads the chezmoi data directly and renders the external entries for the current `os-arch` target. Beyond the manifest, the helper generates the `symlink_*.tmpl` sources that point each bundle command at its installed file (through `home/.chezmoitemplates/portable-pkgs-link.tmpl`) and `remove_literal_*.literal` sources that retire the destinations of a removed package. Hand-edit the manifest only when the helper cannot express the change.

Resolving or verifying a release does not install it: installation is `chezmoi apply` followed by checking the managed targets. Multi-command packages and bundles always verify their archive members, `update --verify` verifies every target it touches before writing, and an implicit `update` reports and skips a GitHub `latest` release whose SemVer is older than the configured tag.
