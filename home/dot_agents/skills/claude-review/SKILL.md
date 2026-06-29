---
name: claude-review
description: Independent read-only review through the Claude CLI. Use when an important, high-impact, high-uncertainty, disputed, or final pre-merge decision benefits from an external Claude review and context exposure is acceptable.
---

# Claude Review

Use this skill when an important decision benefits from an independent review
through the `claude` CLI.

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

Before running `claude`, state that the review may send repository context and
diff content to Claude, then get explicit user approval unless the user has
already asked for Claude review in the current task.

Run Claude in review-only mode. Do not ask it to edit files, commit, push,
install dependencies, run migrations, deploy, or modify durable state.

## Recommended Command

Prefer non-interactive print mode. Use `--permission-mode plan` when available
so the Claude CLI stays read-only, and request plain text output for easier
integration:

```bash
claude -p --permission-mode plan --output-format text '<review prompt>'
```

If the local Claude CLI does not support a flag, remove only that unsupported
flag and keep the review prompt read-only. Do not use
`--dangerously-skip-permissions` for this workflow.

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
- Inspect the current git diff and relevant surrounding files.
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
