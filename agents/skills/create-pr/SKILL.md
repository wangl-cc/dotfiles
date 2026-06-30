---
name: create-pr
description: Create a GitHub pull request for the current branch. Use when the user wants to open a PR, optionally specifying a target branch (defaults to 'main'). The PR title and body should describe the branch's net change relative to the target branch, not the branch's internal history.
---

# Create Pull Request

## Overview

Use this skill to create a GitHub pull request from the current branch. The PR title and body should describe the end-state of the branch relative to the target branch (default `main`), not as a chronology of individual commits.

Default to the repository's commit title style when writing the PR title. Do not treat PR titles as a separate style system unless the repository clearly does so.

## Target Branch

- **Default**: `main`
- **User can specify**: Any branch name (e.g., `develop`, `master`, `release/v1.0`)
- If user mentions a specific branch, use that as the target instead of `main`

## Workflow

### 1. Verify prerequisites

- Ensure `gh` CLI is installed and authenticated (`gh auth status`)
- If not authenticated, prompt user to run `gh auth login` first
- Check if current branch has commits not in the target branch

### 2. Inspect the branch diff against target branch

- Determine target branch (default: `main`, user can specify another)
- Refresh target branch locally if needed: `git fetch origin <target-branch>`
- Review changes relative to target:
  - `git log --oneline <target>..HEAD`
  - `git diff --stat <target>...HEAD`
  - `git diff <target>...HEAD`
- Summarize the net effect of all changes, not the internal refactor steps

### 3. Check for existing PR

- Check if a PR already exists for this branch: `gh pr view --json number,url`
- If exists, inform user and offer to update instead

### 4. Draft PR title and body

**Title**: Use the repository's normal commit title style to describe the net change
**Body structure**:

```markdown
## Summary

Brief description of what changed and why.

## Changes

- Key change 1
- Key change 2

## Validation

- Commands/tests that were run (if known)
```

Guidelines:

- Describe end-state relative to target branch, not chronology
- Collapse intermediate steps ("refactor after fix", "rename during cleanup") into final outcome
- Default to the same style you would use for a good commit title in this repository
- Only use Conventional Commit format if the repository clearly uses it for commit titles
- If repository has PR template (`.github/pull_request_template.md`), respect its structure

### 5. Create the PR with shell-safe handling

```bash
gh pr create \
  --base '<target-branch>' \
  --title 'type(scope): short title' \
  --body "$(cat <<'EOF'
## Summary

...

## Changes

- ...

## Validation

- ...
EOF
)"
```

## Writing Guidelines

- PR title: Match the repository's normal commit title style
- PR body: Focus on user-visible outcomes, reviewer context
- Do not list file-by-file changes
- Mention the target branch explicitly in your response

## Example Requests

- "Create a PR for this branch" → target: `main`
- "Open a PR against develop" → target: `develop`
- "PR to merge into master" → target: `master`
- "Create PR for release/v1.2" → target: `release/v1.2`
