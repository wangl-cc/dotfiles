# General engineering guidance

Apply these defaults when writing, reviewing, or modifying code and other implementation artifacts, including scientific infrastructure, simulations, and analysis tools, unless they conflict with the user's current request or repository-local instructions. They are defaults, not prohibitions: when a default and the situation disagree, follow the situation and be able to say why.

## Design

- Fix defects at their owning abstraction layer. If a clean fix is out of scope or blocked, report the limitation; a temporary mitigation needs approval, a stated limitation, and removal criteria.
- Place responsibility where the knowledge lives. Signs that it is misplaced: callers repeatedly inspect internal variants, assemble related state, or repeat an operation sequence; a natural change requires understanding or editing several unrelated places; one rule requires synchronized edits across declarations or parallel structures. Declare shared knowledge once, or make the correspondence explicit so that a field added on one side surfaces an error instead of silently vanishing. Keep independently changing concepts separate even when they look alike.
- Watch for structure that hides missing or misplaced concepts: wrappers that merely forward or repackage information, types that accumulate unrelated responsibilities because they offer convenient data access, and script-like code made of large single files, ownerless helpers, and passive data bags. These are signals to investigate, not automatic reasons to add or remove abstractions.
- Model independent domain axes compositionally rather than multiplying flat `{mode} × {shape} × {policy}` cases. Separate parts that change for different reasons or live for different durations, such as stable domain state and per-run execution state, policies, adapters, and side-effect drivers.
- Introduce reusable machinery when the current work establishes a concrete need. Judge a proposed structure through representative calls and a natural change supported by current use, not hypothetical future requirements.
- When a function mixes workflow decisions with representation, policy, or resource details, organize those responsibilities before extracting helpers. Keep the main flow legible, with each extracted function having a purpose that can be explained independently.

## Boundaries, types, and errors

- Static types do not validate runtime input. Validate external data at its trust boundary by parsing it into a validated representation, and let internal code accept only that representation. A check that does not change the type tends to be repeated at every layer.
- Make invalid states unrepresentable where practical. A runtime check earns its place where the signature admits the invalid state; re-checking a condition the type already excludes usually means the trust boundary is in the wrong place, not that the code gained safety.
- Preserve the project's static-typing strictness. Prefer precise annotations and narrowing, and contain the language's escape-hatch type at genuinely untyped boundaries rather than letting it spread through internal code.
- Let errors reach the layer that can handle them meaningfully. Avoid catch-all handlers, silent defaults, and fallback branches that turn a failure into a plausible-looking wrong result; when a fallback is genuinely required, make it explicit and observable.
- Treat public import paths, exported names, entry points, and built artifacts as interfaces. Review compatibility when they change.

## State and lifecycle

- Default to immutable data flow: construct validated values once, as boundary parsing does, rather than mutating shared structures in place and relying on revalidation to catch inconsistencies. Local mutation inside a constructor or a clearly owned accumulator is fine; mutation across ownership boundaries is the smell.
- Keep a function's side effects within its stated purpose. Writes to shared state beyond that belong to the caller or to an explicitly named mutator.
- For concurrent, asynchronous, or long-lived work, define ownership, cancellation, shutdown, timeouts, backpressure, and cleanup; do not leave background work or resources without an owner.

## Testing

- Test observable contracts at the narrowest stable boundary that owns them. Each test should protect a distinct plausible regression or failure semantic; coverage alone does not justify a test, and callers should not repeat a dependency's full branch matrix.
- Keep tests deterministic and isolated.

## Tooling and validation

- Respect repository-selected toolchains, dependency managers, compatibility targets, lockfiles, and generated metadata. Do not introduce parallel tooling or unrelated version churn.
- Prefer project-native validation commands. Deterministic results decide mechanical pass/fail; an LLM summary cannot override an exit code.
- For one-off CLIs, prefer `pnx <tool>` for JavaScript or TypeScript and `uvx <tool>` for Python. Do not install or pin a validation tool unless the user asks or the project already standardizes on it.

## Documentation

- Document public interfaces, architectural decisions, non-obvious invariants, and operational workflows when code alone is insufficient; keep docs next to what they explain and update them when behavior, contracts, setup, or usage changes.

## Readability

- Keep names and representations consistent for the same concept, and use distinct names for meaningful differences.
- Past one level of nesting, conditional expressions usually read better as a plain if/else chain, especially when the branches carry distinct meaning. When nested expressions or compound conditions obscure precedence, defaults, or state transitions, spell out the decisions so readers can see the rules directly.
