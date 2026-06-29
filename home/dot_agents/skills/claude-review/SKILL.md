---
name: claude-review
description: Independent read-only review through the bundled uv/Python Claude Agent SDK runner. Use when an important, high-impact, high-uncertainty, disputed, or final pre-merge decision benefits from an external Claude review and context exposure is acceptable.
---

# Claude Review

Use this skill when an important decision benefits from an independent review
through the bundled Claude Agent SDK runner.

## When to Use

Use for review, not routine implementation:

- High-impact or high-uncertainty work.
- Security, privacy, data-loss, migration, or irreversible-state concerns.
- Large or subtle diffs where local review burden is high.
- Before recommending merge, release, or apply for consequential changes.
- When existing reviewers disagree or return `INCONCLUSIVE`.
- When the user explicitly asks for Claude, the Claude CLI, or an external
  Claude review.

Do not use for small routine edits, routine lint fixes, purely conversational
answers, or when sending repository context to an external CLI is not acceptable.

## Safety Gate

Before running the review script, state that the review may send repository
context and diff content to Claude, then get explicit user approval unless the
user has already asked for Claude review in the current task.

Run Claude in review-only mode. Do not ask it to edit files, commit, push,
install dependencies, run migrations, deploy, or modify durable state.

## Recommended Command

Run the script from this skill directory. It uses uv inline script metadata to
pin and install the Python Claude Agent SDK dependency:

```bash
uv run --script scripts/claude_review.py --cwd <repo> --prompt-file <prompt-file> --diff working-tree
```

The runner script is `scripts/claude_review.py`. In chezmoi-managed dotfiles,
do not name it with a `run_` prefix, because chezmoi treats that prefix as an
apply-time script marker.

The script injects git status and the selected diff, uses the Claude Agent SDK
runner, and restricts Claude to `Read`, `Glob`, and `Grep` tools with
`permissionMode: "dontAsk"`. It also disables
filesystem setting sources so repository settings and guidance are review
context, not controlling instructions.

Assistant review text streams to stdout as it arrives, using SDK partial
messages by default for a reviewer-like live display. Short progress status
lines are written to stderr; use `--quiet-status` when only review text should
be displayed, or `--no-stream-partials` to fall back to complete assistant
messages.

Use `--diff staged`, `--diff unstaged`, `--diff head`, or `--diff none` when the
default working-tree diff is not the right review target.

Use `--dry-run` first when you need to inspect the constructed prompt without
sending anything to Claude.

Do not set `--max-turns` for normal reviews unless a hard cap is needed. Large
reviews may require many read and reasoning turns; use the flag mainly for
smoke tests, CI, or intentionally bounded checks.

## Review Prompt Template

Include the minimum context needed for review:

```text
You are doing an independent, read-only code/config review.

Intent:
- <user goal>

Risk level:
- <risk level and why>

Scope:
- In scope: <files/components>
- Out of scope: <non-goals>

Evidence already available:
- <tests/validation commands and results>
- <known reviewer findings or disagreements>

Repository instructions:
- Read AGENTS.md/CLAUDE.md/project guidance before judging style.

Review target:
- Inspect the supplied diff, patch, selected files, or named target and relevant
  surrounding files.
- Stay read-only. Do not edit files, install dependencies, run migrations,
  deploy, commit, push, or modify durable state.

Return:
- BLOCKER findings: correctness, safety, security, data-loss, or irreversible
  problems that must be fixed.
- IMPORTANT findings: likely defects or maintainability hazards worth fixing.
- NICE-TO-HAVE findings: optional improvements only if clearly valuable.
- Validation gaps: missing checks that would materially change confidence.
- Final recommendation: proceed / proceed after fixes / do not proceed.

For every finding, cite file paths and line numbers when possible, explain why
it matters, and give a concrete fix direction. If no material findings exist,
say what you inspected and why confidence is reasonable.
```

## Integration Rules

- Treat Claude output as review evidence, not as deterministic truth.
- Verify concrete claims against the repository before acting on them.
- Do not paste secrets into the prompt. Redacted placeholders are real values;
  do not try to reconstruct them.
- If Claude asks for broader context, decide whether that context is safe and
  relevant before rerunning.
- Summarize accepted findings separately from rejected or unverified findings.
