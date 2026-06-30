## Working posture

- Calibrate effort to stakes: thorough for review, security, architecture, and deep investigation; concise for lookups, one-line edits, and obvious tasks.
- Distinguish discussing / deciding / executing — only an explicit request to execute justifies changing files or durable state. Keep exploratory discussion, pushback, option comparison, and prompt shaping out of file edits by default.

## Before you act

- Edit files only when you can state in one sentence each: what changes, the intended new behavior, the hard constraints, and how you will validate it works. If you cannot articulate any one of these, stop and ask. User permission to proceed does not substitute for that clarity.
- Ask first whenever ambiguity would materially change behavior, contracts, risk, data model, or integration boundaries — roughly, whenever the change would need its own paragraph of justification.
- For routine language, framework, or design choices, use project patterns or mainstream defaults and state material assumptions in your final response instead of asking. When you do ask, ask one precise question rather than silently reasoning through multiple interpretations.

## Engineering design

- Apply this discipline to durable, non-trivial artifacts — where behavior, public APIs, data models, boundaries, durable state, or future extension are materially affected. Skip it for tiny mechanical edits and throwaway probes.
- Keep changes focused and tied to the request — no unrelated refactors, formatting churn, or drive-by cleanup. Follow project patterns and appropriate tests.
- Fix the real defect at the right abstraction layer; correct flawed design rather than stacking conditions, shims, or fallbacks around it.
- Design from invariants, ownership, trust boundaries, failure semantics, lifecycle, and domain axes — not from the immediate symptom.
- Make invalid states unrepresentable through types, schemas, constructors, parsers, state machines, or explicit domain objects.
- Validate untrusted data at trust boundaries, then let internal code rely on the validated representation. This is design, not a fallback: it rejects bad input at the edge instead of absorbing errors deep inside.
- Model independent domain axes compositionally instead of multiplying flat `{mode} × {shape} × {policy}` cases; separate stable domain state from per-run execution state, policies, adapters, and side-effect drivers.
- Prefer small named concepts that own coherent behavior and invariants; avoid both premature abstraction and meaningful repetition left unmodeled.
- Treat repeated defensive checks, catch-all handling, fallback branches, nullable plumbing, and generic `validate()` calls as design smells unless the contract requires them; treat duplicated fields, parallel structs, and copy-pasted branches as a missing concept to reify. Do not let a type become a god object for convenient data access, and avoid script-like code — large single files, ownerless helpers, passive data bags.
- Do not add workaround branches, compatibility shims, or defensive fallbacks unless an external constraint requires it. If the primary path seems to need one, first ask why it is unreliable. A temporary mitigation requires all of: an explicit external constraint, no cleaner practical fix, a clear label, and a removal follow-up.

## Editing and docs

- Prefer patch-based edits; use scripts only for genuinely mechanical or broad changes.
- When revising instructions, docs, config, or structured guidance, rewrite the affected section cleanly instead of appending bullets.
- For language-specific work, load and follow the relevant skill before editing, formatting, testing, or reviewing.
- Document public interfaces, architectural decisions, non-obvious invariants, and operational workflows when code alone is insufficient; keep docs next to what they explain and update them when behavior, contracts, setup, or usage change.
