# Project Agent Instructions

## Project Context

This repository is a personal dotfiles project managed with chezmoi.
Most changes are configuration updates, bootstrap tweaks, or tool
settings rather than product features.

Keep edits focused and preserve the existing chezmoi layout and naming
conventions. Prefer changing the source files in this repository instead
of describing changes to the generated home-directory paths.

## Commit Messages

This project does not use Conventional Commits.

Use a direct scope prefix that names the area being changed:

```text
scope: concise imperative summary
```

Examples:

```text
fish: simplify prompt setup
aqua: add shared typst package
chezmoi: refresh bootstrap prompts
opencode: tighten agent response rules
docs: clarify update workflow
```

Choose the scope from the configuration area, tool, or directory most
responsible for the change. Good scopes include `fish`, `aqua`,
`chezmoi`, `opencode`, `git`, `shell`, `dev-box`, and `docs`.

Do not rewrite these into `feat:`, `fix:`, `chore:`, or other
Conventional Commit types. Dotfiles changes often do not map cleanly to
those categories, so the direct scope is the reviewable unit here.
