---
name: portable-pkgs
description: Maintain this chezmoi repo's portable package manifest. Use when adding, updating, removing, or verifying standalone GitHub release CLI packages in home/.chezmoidata/portable-pkgs.yaml.
---

# Portable Packages

## When to Use This Skill

Use this skill in this chezmoi repo when the task involves:

- adding a standalone CLI binary to the portable package set
- updating, removing, inspecting, or verifying an entry in
  `home/.chezmoidata/portable-pkgs.yaml`
- changing `home/.chezmoiexternal.toml.tmpl` behavior for portable packages
- discussing how portable package installation should work on new machines

## Rules

- Use `portable-pkgs` as the manifest maintenance interface by default.
- Do not hand-edit `home/.chezmoidata/portable-pkgs.yaml` for ordinary add,
  update, remove, inspect, or verify operations.
- Hand-edit the manifest only when the helper cannot express the required
  change. In that case, state why the helper was insufficient and keep the diff
  minimal.
- Keep `home/.chezmoiexternal.toml.tmpl` as the renderer. The helper maintains
  the manifest; the template reads resolved manifest metadata.
- Prefer GitHub release assets with stable `sha256` metadata. Use
  `inspect --save` when the archive path needs explicit confirmation.
- Treat `default_targets` and `targets` in the manifest as the global target
  policy for intelligent adds. Do not duplicate target matching rules in docs
  or prompts.

## Workflow

1. Read the current manifest entry or target package release shape.
2. Use the helper command that matches the operation.
3. Review the generated diff before making follow-up edits.
4. Verify touched package entries.
5. Verify the chezmoi render for relevant install targets when practical.

## Commands

Inspect package candidates when the repository or release assets are unclear:

```bash
portable-pkgs search <query> --format json
portable-pkgs assets <owner/repo> --format json
```

Use the default table output only for human inspection. Agent-run discovery
should use JSON so candidate selection does not depend on terminal formatting.

Add a package with intelligent asset and archive path inference:

```bash
portable-pkgs add <name> --repo <owner/repo> --verify --non-interactive
rtk git diff -- home/.chezmoidata/portable-pkgs.yaml
```

Use `--non-interactive` for agent-run commands. It disables prompts and makes
ambiguous inference fail with candidates. Report the candidate list and rerun
with explicit `--repo`, `--target`, `--bin`, or manual `--target-asset` values
instead of using interactive prompts.

Use `--dry-run --format json` only when the inferred repo, target assets, or
archive paths need inspection before editing the manifest. Ordinary successful
adds are easy to review and revert through the manifest diff.

Use the manual escape hatch when inference cannot express the release layout:

```bash
portable-pkgs add <name> --repo <owner/repo> --non-interactive \
  -Tdarwin-aarch64='<darwin asset regex>' \
  -Tlinux-x86_64='<linux asset regex>' \
  --path-pattern '<archive member path>' \
  --bin <command>
```

Update a package:

```bash
portable-pkgs update <name> --verify
```

Inspect an archive when the binary path is unclear:

```bash
portable-pkgs inspect <name> --target <target>
portable-pkgs inspect <name> --target <target> --save
```

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
rtk chezmoi cat ~/.local/bin/<command>
rtk chezmoi diff ~/.local/bin/<command>
rtk git diff --check
```

If `chezmoi` is blocked by the persistent state lock, do not delete the lock
file casually. Use a temporary `--persistent-state` and `--cache` path for
render verification, and report that the real state lock prevented a normal
diff.
