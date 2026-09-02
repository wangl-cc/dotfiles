# Project Agent Instructions

## Project Context

This repository is a personal dotfiles project managed with chezmoi. Most changes are configuration updates, bootstrap tweaks, or tool settings rather than product features.

`.chezmoiroot` makes `home/` the chezmoi source root. Files elsewhere in the repository are project resources unless a managed source explicitly exposes or consumes them.

Keep edits focused and preserve the existing chezmoi layout and naming conventions. Prefer changing the source files in this repository instead of describing changes to the generated home-directory paths.

Treat prompt keys and defaults in `home/.chezmoi.toml.tmpl` as the machine-local bootstrap schema. When they change, account for existing configurations, document any reinitialization or migration in `README.md`, and validate both default and overridden initialization.

When changing OS-, architecture-, hostname-, or machine-data-dependent templates, validate every affected branch that can be exercised locally and report any branch that remains unverified.

For changes to templates or other rendered configuration, inspect affected targets with `chezmoi cat` and inspect the complete `chezmoi diff` before applying. For a focused change, apply and verify only the affected targets. A full apply may refresh externals or run scripts that install tools and modify live configuration, so inspect those effects before applying the whole source state. After applying, verify the actual managed targets or paths and run the repository's relevant checks plus `git diff --check`.

## Commit Messages

This project does not use Conventional Commits.

Use a direct scope prefix that names the area being changed:

```text
scope: concise imperative summary
```

Examples:

```text
fish: simplify prompt setup
agy: add Antigravity harness configuration
agents: consolidate global contract
skills: streamline skill collection
packages: add shared typst package
meta: clarify repository layout in readme
meta: ignore markdown reformatting in blame
```

Choose the scope from the tool, directory, or configuration area most responsible for the change:

- **Specific tools/CLIs**: Use the tool's name (e.g. `agy`, `codex`, `zed`, `fish`, `git`, `uv`, `cargo`, `chezmoi`, `rime`).
- **Domains & collections**: Use the directory or domain name (e.g. `agents`, `skills`, `packages`, `shell`).
- **Repository meta**: Use `meta` for repository governance, project-level instructions (like `README.md` and `AGENTS.md`), and metadata outside specific tools (like `.git-blame-ignore-revs`).

Do not rewrite these into `feat:`, `fix:`, `chore:`, or other Conventional Commit types. Dotfiles changes often do not map cleanly to those categories, so the direct scope is the reviewable unit here.

## Managed Agent Configuration

This repository is the authoritative source for shared agent instructions and sub-agent configuration. Edit repository sources, never rendered targets under a tool's home-directory configuration.

- `home/.chezmoitemplates/agents/` owns the shared contract and optional harness partials. Per-tool `AGENTS.md.tmpl` files compose those sources and contain only the partials or residue that their harness requires.
- `agents/guidance/` owns language- or format-specific personal defaults, while `agents/skills/` owns reusable workflows exposed through the managed `~/.agents` root.
- `home/.chezmoidata/subagents/` owns portable role definitions. Keep caller routing in `description`, `when_to_use`, and `how_to_use`; keep spawned-role behavior in `prompt`; use `access` for portable capability intent; and put only genuine harness differences in nested harness tables.
- `home/.chezmoitemplates/subagents/` owns each harness's output schema and shared access mapping. Per-tool agent templates are one-line role bindings; adapter presence enables a binding.
- When moving shared guidance or skills, verify the repository source, the managed `~/.agents` root, and every affected harness discovery path; a correct source file alone does not establish runtime availability.
- When a managed binding must disappear from every machine, remove its adapter and add the appropriate native removal source or target to `home/.chezmoiremove`. Do not add a tombstone when retiring a whole harness while intentionally preserving its current local configuration.
