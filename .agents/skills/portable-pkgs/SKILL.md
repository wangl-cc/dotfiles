---
name: portable-pkgs
description: Maintain this chezmoi repo's portable GitHub release packages, including packages that install one or more real CLI binaries. Use when adding, updating, removing, inspecting, verifying, or changing the rendering of entries in home/.chezmoidata/portable-pkgs.yaml.
---

# Portable Packages

## When to Use This Skill

Use this skill in this chezmoi repo when the task involves:

- adding one or more standalone CLI binaries from a GitHub release package
- updating, removing, inspecting, or verifying an entry in `home/.chezmoidata/portable-pkgs.yaml`
- changing `home/.chezmoiexternal.toml.tmpl` behavior for portable packages
- discussing how portable package installation should work on new machines

## Rules

- Use `portable-pkgs` as the manifest maintenance interface by default.
- Do not hand-edit `home/.chezmoidata/portable-pkgs.yaml` for ordinary add, update, remove, inspect, or verify operations.
- Hand-edit the manifest only when the helper cannot express the required change. In that case, state why the helper was insufficient and keep the diff minimal.
- Keep `home/.chezmoiexternal.toml.tmpl` as the renderer. The helper maintains the manifest; the template reads resolved manifest metadata.
- Treat a package as the owner of its repository, tag, release asset, checksum, and real executable outputs. Keep binaries from one archive in one package so they resolve and update together.
- Use repeated `--bin` options for a package that ships multiple real binaries. Do not model those binaries as separate top-level packages.
- Keep invocation aliases outside `bins`. In this repository's symlink source mode, use a chezmoi symlink source for an alias that only changes the command name, such as `symlink_pn -> pnpm`; use an executable wrapper source for an alias that injects arguments, such as `dot_local/bin/pnx` executing `pnpm dlx`.
- Do not partially change the binary set or path patterns of an existing multi-binary package. The helper rejects these shape changes; remove and re-add the package so every target is rebuilt together.
- Prefer GitHub release assets with stable `sha256` metadata. Use `inspect --save` when the archive path needs explicit confirmation.
- Treat `default_targets` and `targets` in the manifest as the global target policy for intelligent adds. Do not duplicate target matching rules in docs or prompts.

Schema v5 stores a single binary in `bin` with an `archive-file` or `file` resolution. It stores multiple binaries in `bins` with one shared `archive-members` resolution; the renderer expands the resolved members into separate chezmoi `archive-file` entries with the same URL and checksum.

## Workflow

1. Read the current manifest entry and release asset shape, distinguishing real archive members from invocation aliases.
2. Use a JSON dry-run when repository, asset, binary membership, or path inference needs confirmation.
3. Use the helper command that matches the operation.
4. Review the generated diff before making follow-up edits.
5. Verify the touched package and every binary it owns.
6. Verify the chezmoi render for relevant install targets when practical.

## Commands

Inspect package candidates when the repository or release assets are unclear:

```bash
portable-pkgs search <query> --format json
portable-pkgs assets <owner/repo> --format json
```

Use the default table output only for human inspection. Agent-run discovery should use JSON so candidate selection does not depend on terminal formatting.

Add a package with intelligent asset and archive path inference:

```bash
portable-pkgs add <name> --repo <owner/repo> --verify --non-interactive
rtk git diff -- home/.chezmoidata/portable-pkgs.yaml
```

Add multiple real binaries from the same release archive by repeating `--bin`:

```bash
portable-pkgs add uv --repo astral-sh/uv \
  --bin uv \
  --bin uvx \
  --verify \
  --non-interactive
```

Use `--non-interactive` for agent-run commands. It disables prompts and makes ambiguous inference fail with candidates. Report the candidate list and rerun with explicit `--repo`, `--target`, `--bin`, or manual `--target-asset` values instead of using interactive prompts.

Use `--dry-run --format json` when the inferred repository, target assets, binary members, or archive paths need inspection before editing the manifest. Ordinary unambiguous single-binary adds can be reviewed directly through the manifest diff.

Use the manual escape hatch when inference cannot express the release layout:

```bash
portable-pkgs add <name> --repo <owner/repo> --non-interactive \
  -Tdarwin-aarch64='<darwin asset regex>' \
  -Tlinux-x86_64='<linux asset regex>' \
  --path-pattern '<archive member path>' \
  --bin <command>
```

For a multi-binary manual add, repeat `--bin` and provide one shared `--path-pattern` containing `{bin}` when the archive layout permits it:

```bash
portable-pkgs add <name> --repo <owner/repo> --non-interactive \
  -Tdarwin-aarch64='<darwin asset regex>' \
  -Tlinux-x86_64='<linux asset regex>' \
  --path-pattern '{assetStem}/{bin}' \
  --bin <command-a> \
  --bin <command-b>
```

Update a package:

```bash
portable-pkgs update <name> --verify
```

Multi-binary updates always verify every resolved archive member before saving, even without `--verify`. Keep `--verify` when the selected operation may also include single-binary packages.

Inspect an archive when the binary path is unclear:

```bash
portable-pkgs inspect <name> --target <target>
portable-pkgs inspect <name> --target <target> --save
```

For a multi-binary package, `inspect` checks every configured path together. Do not use the single-binary `--path-regex` escape hatch for it.

Verify an entry:

```bash
portable-pkgs verify <name>
```

Remove an entry:

```bash
portable-pkgs remove <name>
```

## Validation

For package manifest changes, prefer:

```bash
portable-pkgs verify <name>
chezmoi execute-template --file home/.chezmoiexternal.toml.tmpl
rtk chezmoi diff ~/.local/bin/<command-a> ~/.local/bin/<command-b>
rtk git diff --check
```

Validate every binary owned by the package. For a multi-binary archive, confirm that the rendered entries share the expected URL and checksum, use distinct member paths, and produce real executable files. When practical, apply into an isolated temporary destination and run each binary's version command.

If `chezmoi` is blocked by the persistent state lock, do not delete the lock file casually. Use a temporary `--persistent-state` and `--cache` path for render verification, and report that the real state lock prevented a normal diff.
