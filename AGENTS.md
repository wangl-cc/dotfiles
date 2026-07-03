# Project Agent Instructions

## Project Context

This repository is a personal dotfiles project managed with chezmoi.
Most changes are configuration updates, bootstrap tweaks, or tool
settings rather than product features.

Keep edits focused and preserve the existing chezmoi layout and naming
conventions. Prefer changing the source files in this repository instead
of describing changes to the generated home-directory paths.

Files under `home/dot_config/opencode/` are source files for the user's
global opencode configuration. Changes there affect global opencode
behavior after chezmoi applies them, not just this dotfiles repository.
When editing opencode agents, skills, plugins, MCP servers, permissions,
or `opencode.jsonc`, avoid baking repo-specific assumptions into reusable
global prompts unless the behavior is explicitly intended to be project
scoped.

## Commit Messages

This project does not use Conventional Commits.

Use a direct scope prefix that names the area being changed:

```text
scope: concise imperative summary
```

Examples:

```text
fish: simplify prompt setup
packages: add shared typst package
chezmoi: refresh bootstrap prompts
opencode: tighten agent response rules
docs: clarify update workflow
```

Choose the scope from the configuration area, tool, or directory most
responsible for the change. Good scopes include `fish`, `packages`,
`chezmoi`, `opencode`, `git`, `shell`, `dev-box`, and `docs`.

Do not rewrite these into `feat:`, `fix:`, `chore:`, or other
Conventional Commit types. Dotfiles changes often do not map cleanly to
those categories, so the direct scope is the reviewable unit here.
