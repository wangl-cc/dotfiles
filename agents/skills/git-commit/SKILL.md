---
name: git-commit
description: Create a git commit when the user explicitly asks for one. Use when the user wants to commit changes, create a commit message, or group and stage related changes before committing.
---

# Git Commit

Create a safe, well-scoped commit that matches the repository's existing history.

## When to Use This Skill

Use this skill when the user wants to:

- create a commit
- generate or refine a commit message
- stage related files for one logical commit
- review what should be included before committing

## Core Rule

Do not commit unless the user explicitly asks.

## Workflow

### 1. Inspect the repository state

Always check:

- `git status`
- staged diff
- unstaged diff
- recent commit messages

Start by understanding both the current changes and the repository's existing commit style.

## 2. Match repository style first

Default to the style already used in recent commits.

If the repository uses Conventional Commits, follow that format. Otherwise, stay consistent with the local history.

Reference: <https://www.conventionalcommits.org/>

## 3. Decide what belongs in this commit

Use these rules:

- if files are already staged, assume the user staged them intentionally
- do not automatically add unrelated unstaged changes
- if staged and unstaged changes appear to be separate logical changes, ask what should be included
- if additional files need staging, only add files that belong to the same logical change
- use explicit file paths; avoid interactive staging and broad globs

## 4. Draft the commit message

The message should:

- match repository style
- describe the final change, not the editing process
- be concise and specific
- focus on why when that context is clear from the diff

If the change spans multiple unrelated concerns, ask the user to split it or choose one scope.

## 5. Create the commit

When committing:

- use the staged set unless the user asked for regrouping
- create one logical commit at a time
- avoid empty commits

## 6. Verify afterward

After the commit:

- run `git status` again
- confirm whether anything remains unstaged or uncommitted
- if hooks modified files, report that clearly

## Safety Rules

- do not commit secrets, credentials, keys, tokens, or machine-private configuration
- do not skip hooks unless the user explicitly asks
- do not push as part of this skill
- do not create an empty commit
- if there is nothing relevant to commit, say so plainly

## Amend Rule

Avoid amend by default.

Only consider amending when all of these are true:

- the previous commit was just created by the agent
- it has not been pushed
- a hook or automatic formatter changed files that belong in that same commit

Otherwise, create a new commit or ask the user.

## Anti-Patterns

Avoid these:

- committing without checking recent message style
- staging unrelated files just to make the commit pass
- using interactive git commands that require terminal input
- committing suspicious files without warning the user
- describing the work as a chronology instead of the final result
