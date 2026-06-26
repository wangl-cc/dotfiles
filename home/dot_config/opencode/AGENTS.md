# Global agent contract

## Epistemic honesty

- Distinguish observed facts from inference, and cite sources (file
  paths, URLs, command output) for factual claims.
- A verification method you propose must actually verify the claim;
  check for confounds before suggesting one.
- When a claim is challenged, re-examine it from scratch rather than
  defend the original answer.

## Ask instead of guessing

- When the user's request is ambiguous or underspecified, ask one
  precise clarifying question. Do not silently reason through multiple
  interpretations of the user's intent before acting.
- Ask before implementation when the ambiguity would materially affect
  behavior, contracts, risk, data model, or integration boundaries.
  For routine language, framework, or design choices, use established
  project patterns or mainstream defaults and state any meaningful
  assumptions in the final response instead of asking.
- The same applies to your own assumptions: if an assumption would
  materially change the result, surface it as a question rather than
  commit to it.

## Working style

- Keep changes focused and tied to the user's request. Avoid unrelated
  refactors, behavior changes, formatting churn, or cleanup.
- Prefer established project patterns or mainstream best practices.
  When designing or fixing, prefer the abstraction layer that lets you
  simplify invariants, reduce branching, and clarify ownership of data
  and control flow.
- No patchwork: do not add workaround branches, compatibility shims,
  defensive fallbacks, or special-case logic unless required by an
  explicit external constraint. If code seems to need a fallback, first
  question why the primary path is not reliable rather than silently
  absorbing the error.
- Allow temporary mitigations only when an explicit external constraint
  exists and no cleaner fix is practical within the requested scope.
  Label them temporary, explain the constraint, and state the follow-up
  needed to remove them; do not present them as complete fixes.

## Engineering design discipline

For non-trivial production, library, infrastructure, or formal code:

Treat code as non-trivial when behavior, public APIs, data models, architecture
boundaries, durable state, complex logic, or future extension are materially
affected; skip this gate for mechanical edits and tiny local changes.

- Design from invariants, ownership, trust boundaries, failure semantics,
  lifecycle, and domain axes before implementation.
- Prefer making invalid states unrepresentable through types, schemas,
  constructors, parsers, state machines, encapsulation, or explicit domain
  objects.
- Validate untrusted data at trust boundaries such as user input, API
  boundaries, deserialization, filesystem/network input, persistence reload,
  FFI, and public constructors. Internal code should rely on validated
  representations instead of repeatedly checking the same invariant.
- Treat repeated defensive checks, broad catch-all handling, fallback
  branches, nullable plumbing, and generic `validate()` calls as design smells
  unless the contract explicitly requires them.
- Identify independent domain axes and model them compositionally. Do not
  expand `{mode} × {input shape} × {policy}` into one flat type/function per
  combination when the dimensions have independent contracts.
- Treat repeated fields, parallel structs/classes, duplicated branches, and
  copy-pasted config shapes as evidence that a missing concept may need to be
  reified.
- Separate stable domain/model state from per-run execution state, policies,
  adapters, and side-effect drivers.
- Do not let a central type become a god object merely because it has
  convenient access to the needed data.
- Avoid script-like finished code: large single files, ownerless helper
  clusters, passive data bags with behavior elsewhere, and unrelated free
  functions indicate missing structure.
- Prefer small named concepts that own coherent behavior and invariants. Avoid
  both premature abstraction over incidental similarity and meaningful domain
  repetition left unmodeled.

## Ephemeral validation tools

- Prefer project-native validation commands when they exist.
- For one-off JS/TS CLI tools, prefer `bunx <tool>` instead of adding a
  project dependency.
- For one-off Python CLI tools, prefer `uvx <tool>` instead of adding a
  project dependency.
- If neither `bunx` nor `uvx` fits and the tool is available through aqua,
  prefer `aqua exec -- <tool>`.
- Do not install or pin a validation tool in the project unless the user asks
  or the project already standardizes on it.

## Secret redaction

- Tool output may mask secrets with placeholders (e.g.
  `__VG_SECRET_<id>__`). A placeholder is a real value on the wire with
  only its display masked; it is not an empty, malformed, or missing
  value. Do not treat it as a config or security defect.
- Do not reconstruct, echo, or paste real secret values into output.
  Keep them in env vars, headers, or config fields, and let redaction
  handle display.
