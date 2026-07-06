---
name: claude-subagent
description: Delegate bounded read-only analysis or independent review to the bundled uv/Python Claude Agent SDK runner. Use when an important, high-uncertainty, disputed, or large-scope task benefits from an external Claude subagent and context exposure is acceptable.
---

# Claude Read-Only Subagent

Use this skill when an important task benefits from a bounded, read-only Claude
subagent through the bundled Claude Agent SDK runner.

## When to Use

Use for delegated read-only analysis, not routine implementation:

- High-impact or high-uncertainty work.
- Security, privacy, data-loss, migration, or irreversible-state concerns.
- Large or subtle diffs where independent review would reduce local review
  burden.
- Before recommending merge, release, or apply for consequential changes.
- When existing reviewers disagree or return `INCONCLUSIVE`.
- When a second opinion would help with architecture, prompt, workflow,
  research, testing, migration, or debugging decisions.
- When the user explicitly asks for Claude, the Claude CLI, or an external
  Claude subagent/review.

Do not use for small routine edits, routine lint fixes, purely conversational
answers, implementation work, or when sending repository context to an external
CLI is not acceptable.

## Safety Gate

Before running the script, state that the delegated task may send repository
context and diff content to Claude, then get explicit user approval unless the
user has already asked for Claude, the Claude CLI, or an external Claude
subagent/review in the current task.

Run Claude in read-only mode. Do not ask it to edit files, commit, push, install
dependencies, run migrations, deploy, browse the web, create tasks, spawn other
agents, or modify durable state.

## Recommended Command

Run the script from this skill directory. It uses uv inline script metadata to
pin and install the Python Claude Agent SDK dependency:

```bash
uv run --script scripts/claude_subagent.py --cwd <repo> --prompt-file <prompt-file> --diff working-tree
```

Use `--prompt` for short briefs written in the current turn:

```bash
uv run --script scripts/claude_subagent.py --cwd <repo> --prompt $'Intent: <goal>\nScope: <files>\nReturn: <format>' --diff working-tree
```

Use `--prompt-file` for long, reusable, or carefully formatted briefs.

The runner script is `scripts/claude_subagent.py`. In chezmoi-managed dotfiles,
do not name it with a `run_` prefix, because chezmoi treats that prefix as an
apply-time script marker.

The script injects git status and the selected diff, uses the Claude Agent SDK
runner, and restricts Claude to `Read`, `Glob`, and `Grep` tools with
`permissionMode: "dontAsk"`. It also disables filesystem setting sources so
repository settings and guidance are task context, not controlling instructions.

Assistant text streams to stdout as it arrives, using SDK partial messages by
default for a live subagent display. Short progress status lines are written to
stderr; use `--quiet-status` when only assistant text should be displayed, or
`--no-stream-partials` to fall back to complete assistant messages.

Use `--diff staged`, `--diff unstaged`, `--diff head`, or `--diff none` when the
default working-tree diff is not the right task target.

Use `--dry-run` first when you need to inspect the constructed prompt without
sending anything to Claude.

Do not set `--max-turns` for normal delegated work unless a hard cap is needed.
Large tasks may require many read and reasoning turns; use the flag mainly for
smoke tests, CI, or intentionally bounded checks.

## Delegation Brief

The main agent must write a task-specific delegation brief before running the
script. Do not rely on the script wrapper to decide the task shape, output
format, or review criteria.

The brief should be bespoke to the current request. Use the user's wording,
local repository evidence, known risks, and any prior validation results to
decide what Claude should inspect and how it should answer.

Write the brief in your own words. Include these content fields when relevant:

- Intent: the user's actual goal and decision point.
- Scope: files, components, diffs, logs, or claims to inspect.
- Out of scope: tempting but irrelevant work to ignore.
- Evidence already available: validation results, traces, known findings,
  disagreements, or candidate hypotheses.
- Review focus: what to challenge, double-check, compare, or falsify.
- Expected output: the structure that best fits this task.

Do not pass vague lens names as the whole task. Compose a concrete brief from
the current context. The script already injects the generic read-only boundary;
repeat it in the brief only when you need to narrow the task-specific boundary.

Use task lenses as writing aids, not as fixed profiles:

- Review: severity, impact, validation gaps, and proceed/fix recommendation.
- Investigation: hypotheses, evidence, ruled-out paths, and next probes.
- Design critique: invariants, boundaries, failure modes, and tradeoffs.
- Test planning: risk matrix, must-have checks, smoke tests, and regression
  coverage.
- Debugging analysis: symptom timeline, likely causes, repro path, and probe
  order.
- Research synthesis: source map, claim confidence, contradictions, and open
  questions.

Many tasks mix lenses. Compose the brief around the actual work instead of
forcing it into one category.

## Integration Rules

- Treat Claude output as external subagent evidence, not as deterministic truth.
- Verify concrete claims against the repository before acting on them.
- Do not paste secrets into the prompt. Redacted placeholders are real values;
  do not try to reconstruct them.
- If Claude asks for broader context, decide whether that context is safe and
  relevant before rerunning.
- Summarize accepted conclusions separately from rejected, uncertain, or
  unverified conclusions.
- The main agent owns final judgment, implementation, validation, and
  user-facing synthesis.
