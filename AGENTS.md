# Project Agent Instructions

## Project Context

This repository is a personal dotfiles project managed with chezmoi. Most changes are configuration updates, bootstrap tweaks, or tool settings rather than product features.

Keep edits focused and preserve the existing chezmoi layout and naming conventions. Prefer changing the source files in this repository instead of describing changes to the generated home-directory paths.

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
