---
name: portable-pkgs
description: Maintain this chezmoi repo's portable GitHub release packages, including selected CLI binaries and complete bundles with command symlinks. Use when adding, updating, removing, inspecting, verifying, or changing the rendering of entries in home/.chezmoidata/portable-pkgs.yaml.
---

# Portable Packages

Run commands from this repository root. The helper is a local uv project, not a global command. From another directory, pass the absolute path to this checkout’s `portable-pkgs` project with `--project`.

Use this skill for packages in `home/.chezmoidata/portable-pkgs.yaml`, their installer template `home/.chezmoiexternal.toml.tmpl`, and the `portable-pkgs` helper.

## Contract

- Use the helper for ordinary package changes. Hand-edit only when it cannot express a necessary change, and state why.
- `inspect` provides read-only facts; the agent chooses the repository, assets, command membership, and paths. The tool has no interactive prompts or heuristic selection.
- Specify the installation `--type`: `file` for one bare binary, `archive-files` for selected archive members, `bundle` for complete extraction with command symlinks. An archive does not automatically mean bundle.
- Declare every real executable with `--bin`. Keep binaries from one release archive in one package. Invocation aliases remain separate chezmoi symlinks or wrappers.
- Keep rendering in the external template. The helper owns the manifest and generated bundle symlink/removal sources.
- Use JSON for agent discovery and dry-run review. Do not infer successful installation from successful resolution or verification: installation requires chezmoi apply and checking the managed targets.

## Discover and Add

```sh
uv run --locked --project portable-pkgs portable-pkgs search <query> --format json
uv run --locked --project portable-pkgs portable-pkgs inspect <owner/repo> --tag <release-tag>
uv run --locked --project portable-pkgs portable-pkgs inspect <owner/repo> --tag <release-tag> --asset <exact-archive-name>
```

`inspect` does not require a configured package. It lists release assets or raw archive member paths, types, permission bits, sizes, and link targets. It does not extract, select members, or save anything. Use `--path-regex` with `--asset` to filter rows; names and permissions are evidence for the agent to inspect, not proof that an archive is installable. There is no `assets` command or `inspect --save`.

New packages require `--repo`, `--type`, and explicit platform asset regexes. Archives require a shared `--path-pattern` or a complete `--paths` mapping. Asset rules must match exactly one asset. Resolve ambiguity by inspecting the returned list and making the rule more precise.

```sh
uv run --locked --project portable-pkgs portable-pkgs add <name> --repo <owner/repo> --type archive-files \
  --bin <command> \
  -Tdarwin-aarch64='<macOS asset regex>' \
  -Tlinux-x86_64='<Linux asset regex>' \
  --path-pattern '{assetStem}/{bin}' --dry-run --format json
```

Review the JSON and rerun without `--dry-run` to save. For multiple binaries repeat `--bin`; use `--paths '{"tool":"bin/tool","helper":"libexec/helper"}'` when one pattern cannot express all shared paths. `--paths` and `--path-pattern` are mutually exclusive. Path variables are `{asset}`, `{assetStem}`, `{bin}`, `{repo}`, `{tag}`, `{version}` (leading `v` removed), and `{target}`.

Existing packages reuse omitted repository, pinned tag, commands, and rules. Changing the repository without specifying a tag selects that repository's latest release. `--target-paths '{"linux-x86_64":{"helper":"libexec/helper"}}'` replaces that target's overrides; an empty map clears them. It does not normalize or rewrite other targets. Remove and re-add when changing existing command membership, type, stripping, or multi-command shared paths.

```sh
uv run --locked --project portable-pkgs portable-pkgs add codex --repo openai/codex --type bundle \
  --bin codex --bin codex-code-mode-host --path-pattern 'bin/{bin}' \
  -Tdarwin-aarch64='^codex-package-aarch64-apple-darwin\.tar\.gz$' \
  -Tlinux-x86_64='^codex-package-x86_64-unknown-linux-musl\.tar\.gz$'
```

There are no `--interactive`, `--non-interactive`, or inferred `add --target` options. Bare `file` packages have exactly one command and no archive path options. Bundle stripping defaults to zero; patterns refer to paths after stripping.

## Update, Verify, and Remove

```sh
uv run --locked --project portable-pkgs portable-pkgs update <name> --verify
uv run --locked --project portable-pkgs portable-pkgs update <name> --tag <explicit-tag> --verify
uv run --locked --project portable-pkgs portable-pkgs verify <name>
uv run --locked --project portable-pkgs portable-pkgs remove <name>
```

`update` uses saved rules for every target and skips implicit SemVer downgrades. Explicit `--tag` permits a deliberate downgrade. `add` always verifies selected assets and archive members, including on dry runs; it has no `--verify` flag. Multi-command and bundle updates always verify; `update --verify` also verifies single-command packages. A shared metadata change on add refreshes retained targets and verifies every target. `verify` uses pinned checksums without updating configuration.

Checksums come from the current release or current downloaded bytes. GitHub API access and downloads go through githubkit/httpx with 30-second timeouts and automatic rate-limit and server-error retries; downloads reject declared Content-Length truncation, and httpx strips credentials when a redirect crosses origins. Bundle verification checks the complete archive tree and executable commands; tar hardlinks are rejected. Installation uses an exact bundle directory and updates in place, without atomic replacement or rollback.

Progress is written to stderr; stdout remains the selected JSON, human, or Markdown report. Update and verify report how many targets passed, including unchanged releases. SHA256-addressed assets are reused across commands from `$XDG_CACHE_HOME/portable-pkgs/assets` (default `~/.cache/portable-pkgs/assets`) after rehashing; corrupt entries are downloaded again. Without an expected SHA256, commands download afresh. Release discovery and resolution do not cache API metadata. The cache has no automatic eviction and can be deleted to reclaim space. Saving preserves existing manifest field order.

Generated symlink sources use the common link template. Removing packages generates owned native `remove_` sources; bundles also retire their directory. Before saving, the helper checks that files at the generated source paths still have their expected content and that source paths stay inside the source root. It does not invoke chezmoi or check other sources, external declarations, or installed destination files. Review source changes and the manifest together with `chezmoi diff` before applying. Source generation requires a manifest under the source `.chezmoidata` directory.

The per-manifest lock remains held through verification and save; competing writers fail immediately. Never delete the lock file. Each source is replaced atomically, the manifest last; after interruption retry the same operation. Avoid applying or hand-editing sources during a save because the multi-file operation is not a transaction with chezmoi.

## CLI Argument Syntax

Pydantic Settings parses the CLI. Only package name (or repository for `inspect`) is positional. `-T` / `--target-asset` accepts repeated `TARGET=REGEX` values or JSON; repeated target keys use the last value. Shell quoting removes its outer quotes, so preserve inner double quotes around regex values containing commas:

```sh
-T 'linux-x86_64="^tool[0-9]{1,3}\.tar\.gz$"'
--target-asset '{"linux-x86_64":"^tool[0-9]{1,3}\\.tar\\.gz$"}'
```

Use the same inner quoting or JSON for special list strings. Attach option values starting with `-` using `=`. Native scalar `None` means unset, not a literal release tag.

```sh
--bin '"true"' --bin '"a,b"'
--bin '["true","a,b"]'
--tag=-preview
```

## Implementation and Validation

The uv project is `portable-pkgs/`, with `pyproject.toml`, `uv.lock`, `src/portable_pkgs/`, and `tests/`. Its console entry is `portable_pkgs.cli:cli`; no global installation or import-path modification is needed. The default manifest is located relative to this checkout’s source package, so worktrees maintain their own configuration. Domain models and nested mappings are immutable. `AddCommand` inherits the single `AddOptions` schema. `requests.py` owns pure configuration inheritance; `operations.py` owns release I/O and resolution; `installation.py` owns archive installation policy; `PackageStore` coordinates source/manifest saving.

Schema v8 keeps package entries unchanged and removes the global `default_targets` and inference `targets` fields. Upgrade v7 with an external one-off migration that removes those fields and sets `schema_version: 8`; do not add migration logic to the helper. Earlier schemas are rejected. `PORTABLE_PKGS_MANIFEST` overrides the default manifest location.

Run these commands from the repository root:

```sh
uv run --locked --project portable-pkgs python -m unittest discover -s portable-pkgs/tests
uv run --locked --project portable-pkgs ty check portable-pkgs
uv run --locked --project portable-pkgs ruff check portable-pkgs
uv run --locked --project portable-pkgs ruff format --check portable-pkgs
```

Append `-k <test-name>` to the unittest command for a subset. `[tool.ruff]` in `pyproject.toml` selects the enforced lint rules and `ruff format` owns layout; no CI job runs these checks, so run all four commands before handing work back. Keep `pyproject.toml` and `uv.lock` together when changing dependencies. Inspect affected package targets with `chezmoi cat` and `chezmoi diff` before a focused apply; verify every executable owned by the changed package afterward. Isolated package installation tests are not a real-home installation. The helper itself is repository-local and is no longer deployed by chezmoi.
