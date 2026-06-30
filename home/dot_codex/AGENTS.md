# Engineering Contract

## Evidence and Scope

- Ground factual claims in observed evidence; mark inference explicitly when evidence is incomplete.
- When challenged or contradicted by new facts, re-examine from first principles instead of defending the original answer.
- Treat unsupported claims, missing evidence, unresolved risks, and semantic gaps as first-class outputs.
- Keep changes focused, coherent, tied to the user's request, and free of unrelated refactors, formatting churn, or cleanup.
- Ask for guidance when ambiguity would materially change behavior, contracts, risk, workflow, data model, or integration boundaries.

## Engineering Design

- Fix real defects at the right abstraction layer; correct flawed design instead of stacking conditions around it.
- For durable non-trivial artifacts, design from invariants, ownership, trust boundaries, failure semantics, lifecycle, and domain axes.
- Prefer making invalid states unrepresentable through types, schemas, constructors, parsers, state machines, or explicit domain objects.
- Validate untrusted data at trust boundaries, then let internal code rely on validated representations.
- Model independent domain axes compositionally instead of multiplying flat `{mode} x {shape} x {policy}` cases.
- Separate stable domain or model state from per-run execution state, policies, adapters, and side-effect drivers.
- Prefer small named concepts that own coherent behavior and invariants; avoid both premature abstraction and meaningful repetition left unmodeled.

## No Patchwork

- Do not add workaround branches, compatibility shims, defensive fallbacks, or special cases unless an explicit external constraint requires them.
- Do not preserve a broken path "just in case" when a single correct path can be designed.
- If code seems to need a fallback, first question why the primary path is unreliable instead of silently absorbing the error.
- Temporary mitigations require an explicit external constraint, no cleaner practical fix, a clear label, and a removal follow-up.

## Edits and Validation

- Prefer project patterns, established best practices, and appropriate tests.
- Prefer patch-based file edits for manual changes; use scripts only for genuinely mechanical or broad edits.
- When updating instructions, documentation, configuration, or structured guidance, rewrite the relevant section cleanly instead of mechanically appending bullets.
- For language-specific work, load and follow the relevant skill before editing, formatting, testing, or reviewing code.
- Prefer project-native validation commands. Deterministic tool results determine mechanical pass or fail; an LLM summary cannot override an exit code.
- Do not install or pin validation tools unless the user asks or the project already standardizes on them.

## Documentation and PRs

- Document public interfaces, architectural decisions, non-obvious invariants, and operational workflows when code alone is insufficient.
- Keep documentation close to what it explains and update it when behavior, contracts, setup, or usage changes.
- Write PR titles as final-quality commit titles without `[codex]`, `[Codex]`, or similar source markers.
