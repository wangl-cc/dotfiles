# General engineering guidance

Apply these defaults when writing, reviewing, or modifying code and other implementation artifacts, including scientific infrastructure, simulations, and analysis tools, unless they conflict with the user's current request or repository-local instructions. They are defaults, not prohibitions: when a default and the situation disagree, follow the situation and be able to say why. Research guidance also applies when the work involves research questions, experiments, or interpretation.

## Design

- Fix defects at their owning abstraction layer. If a clean fix is out of scope or blocked, report the limitation; use a temporary mitigation only when approved, with its limitations and removal criteria.
- Define invariants, ownership, trust boundaries, failure semantics, and lifecycle responsibilities explicitly enough to guide implementation. Make invalid states unrepresentable where practical.
- Match structure, interfaces, tests, and documentation to the artifact's responsibilities and expected reuse. Introduce reusable machinery when the current work establishes a concrete need.
- Prefer concepts that own coherent behavior and reduce what callers must know or coordinate. When callers repeatedly inspect internal variants, assemble related state, or repeat an operation sequence, check whether responsibility belongs inside the abstraction. When a wrapper merely forwards or repackages information, check what knowledge or constraint it actually encapsulates. These are signals to investigate, not automatic reasons to add or remove abstractions.
- When a function mixes workflow decisions with representation, policy, or resource details, organize those responsibilities before extracting helpers. Keep the main flow legible, with each extracted function having a purpose that can be explained independently.
- Judge a proposed structure through representative calls and a natural change supported by current use. If that change requires understanding or editing several unrelated places, inspect responsibility and dependency boundaries before adding more coordination.
- Respect repository-selected toolchains, dependency managers, compatibility targets, lockfiles, and generated metadata. Do not introduce parallel tooling or unrelated version churn.
- For concurrent, asynchronous, or long-lived work, define ownership, cancellation, shutdown, timeouts, backpressure, and cleanup; do not leave background work or resources without an owner.

## Trust boundaries and validation

- Static types do not validate runtime input. Validate external data at its trust boundary and convert it into an internal representation that downstream code can rely on.
- A runtime check earns its place where the signature admits the invalid state. When the parameter or return type already excludes a condition, re-checking it is usually a smell — the trust boundary may be in the wrong place — rather than free safety.
- Prefer boundary validation that changes the type: parse external input into a validated representation and let internal code accept only that representation. A check that does not transform the type tends to be repeated at every layer.

## State and mutation

- Default to immutable data flow: construct new values and validate once at construction rather than mutating shared structures in place and relying on revalidation to catch inconsistencies. Local mutation inside a constructor or a clearly owned accumulator is fine; mutation across ownership boundaries is the smell.
- A function's side effects should stay within its stated purpose. Writes to shared state beyond that belong to the caller or to an explicitly named mutator.

## Declarations and structure

- Declare a shared field set, schema, or constant in one place, via inheritance or composition. When one rule requires synchronized edits across declarations or parallel structures, inspect whether they duplicate the same knowledge; keep independently changing concepts separate. If two declarations must be bridged, make the correspondence explicit — a field added on one side should surface an error, not silently vanish.

## Expressions and readability

- Past one level of nesting, conditional expressions usually read better as a plain if/else chain, especially when the branches carry distinct meaning. When nested expressions or compound conditions obscure precedence, defaults, or state transitions, spell out the decisions so readers can see the rules directly.
- Keep names and representations consistent for the same concept, and use distinct names for meaningful differences. After a structural change, align declarations, comments, and call relationships with the resulting design within the affected scope.

## Types and public surface

- Preserve the project's static-typing strictness. Prefer precise annotations and narrowing, and contain the language's escape-hatch type at genuinely untyped boundaries rather than letting it spread through internal code.
- Treat public import paths, exported names, entry points, and built artifacts as interfaces. Review compatibility when they change.

## Testing

- Test observable contracts at the narrowest stable boundary that owns them. Each test should protect a distinct plausible regression or failure semantic; coverage alone does not justify a test, and callers should not repeat a dependency's full branch matrix.
- Keep tests deterministic and isolated. Validate narrowly first, then expand with the affected scope and risk.

## Validation and tooling

- Prefer project-native validation commands. Deterministic results decide mechanical pass/fail; an LLM summary cannot override an exit code.
- For one-off CLIs, prefer `pnx <tool>` for JavaScript or TypeScript and `uvx <tool>` for Python. Do not install or pin a validation tool unless the user asks or the project already standardizes on it.

## Documentation

- Document public interfaces, architectural decisions, non-obvious invariants, and operational workflows when code alone is insufficient; keep docs next to what they explain and update them when behavior, contracts, setup, or usage changes.
