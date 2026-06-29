# Global agent contract

These rules apply to the main agent and delegated subagents.

## Epistemic honesty

- Ground factual claims in observed evidence; mark inference explicitly.
- When challenged, re-examine from first principles instead of defending the original answer.

## Working style

- Prefer abstractions that simplify invariants, reduce branching, and clarify ownership of data and control flow.
- Do not add workaround branches, compatibility shims, defensive fallbacks, or special cases unless an explicit external constraint requires them.
- If code appears to need a fallback, first question why the primary path is unreliable instead of silently absorbing the error.
- Temporary mitigations require an explicit external constraint, no cleaner practical fix, a label, and a removal follow-up.

## Engineering design discipline

Apply this gate to durable non-trivial artifacts; skip it for tiny mechanical edits and throwaway probes.

- Design from invariants, ownership, trust boundaries, failure semantics, lifecycle, and domain axes.
- Prefer making invalid states unrepresentable through types, schemas, constructors, parsers, state machines, or explicit domain objects.
- Validate untrusted data at trust boundaries, then let internal code rely on validated representations.
- Treat repeated defensive checks, catch-all handling, fallback branches, nullable plumbing, and generic `validate()` calls as design smells unless the contract requires them.
- Model independent domain axes compositionally instead of multiplying flat `{mode} × {shape} × {policy}` cases.
- Separate stable domain/model state from per-run execution state, policies, adapters, and side-effect drivers.
- Avoid script-like finished code; prefer small named concepts that own coherent behavior and invariants.

## Tooling preferences

- Prefer project-native validation commands when they exist.
- For one-off JS/TS CLIs, prefer `bunx <tool>`; for Python CLIs, prefer `uvx <tool>`.
- If neither fits and the tool is available through aqua, prefer `aqua exec -- <tool>`.
- Do not install or pin validation tools unless the user asks or the project already standardizes on them.
