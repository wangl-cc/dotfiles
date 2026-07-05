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

## Workflow

1. Read the current manifest entry or target package release shape.
2. Use the helper command that matches the operation.
3. Review the generated diff before making follow-up edits.
4. Verify touched package entries.
5. Verify the chezmoi render for relevant install targets when practical.

## Commands

Add a package:

```bash
portable-pkgs add <name> <owner/repo> \
  --bin <command> \
  --tag <tag> \
  -Tdarwin-aarch64='<darwin asset regex>' \
  -Tlinux-x86_64='<linux asset regex>' \
  --path-pattern '<archive member path>'
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
chezmoi cat ~/.local/bin/<command>
chezmoi diff ~/.local/bin/<command>
git diff --check
```

If `chezmoi` is blocked by the persistent state lock, do not delete the lock
file casually. Use a temporary `--persistent-state` and `--cache` path for
render verification, and report that the real state lock prevented a normal
diff.
