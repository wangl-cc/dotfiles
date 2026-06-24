# Global Engineering Rules

## Engineering Goal

- Build for long-term maintainability, correctness, and reviewability rather than only immediate functionality.
- Prefer established best practices and project patterns, with clear ownership, simple invariants, explicit contracts, and appropriate tests.
- Fix real defects at the right abstraction layer. Prefer designs that simplify invariants, reduce branching, and clarify ownership of data and control flow.

## Working Style

### General

- Keep changes focused, coherent, tied to the user's request, and free of unrelated refactors, behavior changes, formatting churn, or cleanup.
- Explain meaningful design choices, tradeoffs, and verification performed.
- Prefer patch-based file edits over scripts for manual changes. Use scripts only when the edit is genuinely mechanical, very broad, or otherwise impractical to express clearly as a patch.
- When updating instructions, documentation, configuration, or structured guidance, integrate new preferences into the existing structure. Prefer rewriting the relevant section cleanly over mechanically appending bullets.

### Pull Requests

- When creating GitHub pull requests, never prefix PR titles with `[codex]`, `[Codex]`, or similar source markers.
- Write PR titles as final-quality commit titles that can be used directly for squash or merge commits.
- If Codex attribution or provenance is useful, put it in the PR body or metadata instead of the PR title.

### Fixing Bugs

- Identify the root cause before changing code.
- If the issue comes from a flawed design, correct the design rather than stacking conditions around it.

### Building Features

- If the current prototype or expected behavior is unclear, discuss it with the user and converge on the prototype before writing code.
- When ambiguity would materially change behavior, contracts, risk, user workflow, data model, or integration boundaries, ask the user for guidance before implementation.
- For routine language, framework, or design choices, use established project patterns or mainstream best practices and state meaningful assumptions in the final response.

### Language-Specific Guidance

- For language-specific work, load and follow the relevant skill before editing, formatting, testing, or reviewing code.
- During one continuous task or discussion, do not repeatedly reload the same skill unless the task direction changes or a specific detail needs to be checked again.
- For Rust work, load the `rust-engineering` skill if it is available.
- If no relevant skill or project policy exists, use project patterns or mainstream defaults. Ask the user only when the choice materially affects behavior, architecture, or risk.

### No Patchwork

- Do not add workaround branches, compatibility shims, defensive fallbacks, or special-case logic unless required by an explicit external constraint.
- Do not preserve a broken path "just in case" when a single correct path can be designed.
- Do not silently absorb errors to make failures disappear. If code seems to need a fallback, first question why the primary path is not reliable.

### Temporary Exceptions

- Allow temporary mitigations only when an explicit external constraint exists and no cleaner complete fix is practical within the requested scope.
- Label them temporary, explain the constraint, state the follow-up required to remove them, and do not present them as complete fixes.

## Sub-Agent Use

### When to Delegate

- Proactively use available sub-agent tools for review, exploration, research, library-usage discovery, and other clear tasks that can run in parallel without blocking the main path.
- Do not delegate small, direct tasks when coordination overhead would exceed the benefit. Keep tightly coupled, urgent, or ambiguous work in the main agent until the boundaries are clear.

### Model Choice

- For exploratory tasks, prefer the platform's currently available faster and more cost-efficient model overrides when suitable, such as `gpt-5.4` or `gpt-5.4-mini`, unless the task is unusually complex, high risk, or quality-sensitive.
- For coding worker tasks, consider the platform's currently available fast coding-oriented model overrides, such as `gpt-5.3-codex-spark`, but only after the main agent has produced a complete, rigorous implementation plan.

### Prompt Design

- Shape sub-agent prompts around the work to be done, not vague personality labels. Useful roles include API usage researcher, bug-focused reviewer, counterargument reviewer, test-gap analyst, security risk reviewer, and bounded implementation worker.
- Lightweight exploratory or review prompts should define the goal, scope, allowed actions, expected evidence, and output format. They should default to read-only investigation unless edits are explicitly assigned.
- Complex review, research, or implementation prompts should also define non-goals, verification criteria, risks to check, and decision criteria.
- Do not fork full conversation context by default. Prefer self-contained prompts with only the necessary background; fork context only when the sub-agent must understand prior discussion, user preferences, or existing decisions.
- Coding worker prompts must be self-contained when possible and include the goal, relevant context, owned files or modules, exact expected behavior, constraints, tests or checks to run, and the required final report. Tell workers they are not alone in the codebase and must not revert or overwrite unrelated changes.

### Accountability

- The main agent remains accountable for the final answer. Review sub-agent outputs, reconcile disagreements, verify important claims, integrate or revise delegated work, and make the final implementation or recommendation decisions.

## Documentation

- Document public interfaces, architectural decisions, non-obvious invariants, and operational workflows when code alone is insufficient.
- Keep documentation close to what it explains and update it when behavior, contracts, setup, or usage changes.
- Write user-facing documentation around final purpose, contract, and usage. Avoid design discussion or rejected alternatives unless the document is explicitly an ADR or design history.
