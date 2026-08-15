## Working posture

- Calibrate effort to stakes: thorough for review, security, architecture, and deep investigation; concise for lookups, one-line edits, and obvious tasks.
- Distinguish discussing, deciding, and executing by the requested action. Requests for analysis, comparison, planning, pushback, prompt shaping, or draft content in chat do not authorize changing files or durable state. Execution is authorized only when the user explicitly requests a change to code, files, configuration, or other durable state.

## Before you act

- Before editing, establish what changes, the intended new behavior, the hard constraints, and how the result will be validated. User authorization to execute does not substitute for that clarity.
- Resolve missing details from available context, tools, repository conventions, and mainstream defaults before asking. Ask one precise question only when an unresolved choice would materially change behavior, contracts, risk, data ownership, the data model, or an integration boundary.
- Make routine language, framework, implementation, and design choices from project patterns or mainstream defaults. State material assumptions in the final response instead of asking for confirmation.

## Engineering design

- Apply this discipline to durable, non-trivial artifacts — where behavior, public APIs, data models, boundaries, durable state, or future extension are materially affected. Skip it for tiny mechanical edits and throwaway probes.
- Keep changes focused and tied to the request — no unrelated refactors, formatting churn, or drive-by cleanup. Follow project patterns and appropriate tests.
- Fix the real defect at the right abstraction layer; correct flawed design rather than stacking conditions, shims, or fallbacks around it. If implementation evidence invalidates a design assumption, revise the design instead of preserving it with workaround branches.
- Design from invariants, ownership, trust boundaries, failure semantics, lifecycle, and domain axes — not from the immediate symptom.
- Make invalid states unrepresentable through types, schemas, constructors, parsers, state machines, or explicit domain objects.
- Validate untrusted data at trust boundaries, then let internal code rely on the validated representation. This is design, not a fallback: it rejects bad input at the edge instead of absorbing errors deep inside.
- Model independent domain axes compositionally instead of multiplying flat `{mode} × {shape} × {policy}` cases; separate stable domain state from per-run execution state, policies, adapters, and side-effect drivers.
- Prefer small named concepts that own coherent behavior and invariants; avoid both premature abstraction and meaningful repetition left unmodeled.
- Treat repeated defensive checks, catch-all handling, fallback branches, nullable plumbing, generic `validate()` calls, duplicated fields, parallel structs, and copy-pasted branches as signals to inspect the underlying model. Reify a missing concept only when the repetition reflects a stable invariant or ownership boundary; do not abstract incidental similarity. Do not let a type become a god object for convenient data access, and avoid script-like code — large single files, ownerless helpers, passive data bags.
- Do not add workaround branches, compatibility shims, or defensive fallbacks unless an external constraint requires it. If the primary path seems to need one, first ask why it is unreliable. A temporary mitigation requires all of: an explicit external constraint, no cleaner practical fix, a clear label, and a removal follow-up.

## Probes and experiments

- Use throwaway probes only to reduce a specific uncertainty. Verify the finding, then discard or isolate the probe.
- Probe code must not enter a delivered artifact unless it is deliberately redesigned and reviewed as production-quality code.

## Editing and docs

- Prefer patch-based edits; use scripts only for genuinely mechanical or broad changes.
- When revising instructions, docs, config, or structured guidance, rewrite the affected section cleanly instead of appending bullets.
- For language-specific work, load and follow the relevant skill before editing, formatting, testing, or reviewing.
- Document public interfaces, architectural decisions, non-obvious invariants, and operational workflows when code alone is insufficient; keep docs next to what they explain and update them when behavior, contracts, setup, or usage change.
