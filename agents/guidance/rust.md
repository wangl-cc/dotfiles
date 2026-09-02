# Rust guidance

Apply these personal defaults to Rust-specific implementation and review decisions unless they conflict with the user's current request or repository-local instructions.

## Project toolchain and lints

- Inspect `rust-toolchain.toml`, `rust-toolchain`, CI commands, `Cargo.toml`, `clippy.toml`, `rustfmt.toml`, `.rustfmt.toml`, and relevant crate documentation before editing.
- Respect the declared MSRV, edition, targets, and feature matrix; use newer idioms only when they are supported by the MSRV.
- Format with the toolchain and command used by CI; use `cargo +nightly fmt` only when the project explicitly requires nightly or unstable rustfmt options.
- Prefer project CI-equivalent checks; otherwise start with `cargo fmt --check` and `cargo clippy --all-targets --all-features`.
- Follow the lint policy. Keep any lint exception narrow and justified; prefer `#[expect(lint_name, reason = "...")]` when the MSRV supports it.

## Ownership and APIs

- Model ownership, borrowing, lifetimes, and state transitions directly in types and method signatures.
- Prefer borrowed read-only inputs such as `&str`, `&Path`, and `&[T]`; accept owned values only when storage, transfer, independent mutation, or a longer lifetime is part of the contract.
- Avoid needless allocation and cloning; use references, iterators, slices, `Cow`, or ownership transfer when they express the intended lifetime clearly.
- Add generic bounds only when they improve the real call site. Do not trade clear diagnostics and contracts for speculative flexibility.
- Introduce traits for genuine abstraction boundaries. Public traits, blanket implementations, associated types, and object-safety choices are long-term API commitments.

## Cargo and compatibility

- Add dependencies only for clear value over local code and prefer crates already established by the project.
- Treat Cargo features, defaults, and optional dependencies as public behavior. Avoid unrelated version churn or feature toggles.
- When feature behavior changes, validate relevant combinations, including default features, `--no-default-features`, or targeted features as applicable; `--all-features` alone can conceal incompatibilities.
- For public crates, review changed surface area through a semver lens and avoid accidental exports. Consider `#[non_exhaustive]` only when forward-compatible extension is a real requirement.

## Failure and safety semantics

- Make error semantics explicit: distinguish invalid input or state, not-found, recoverable failures, and hard failures at the owning abstraction boundary.
- Library crates should expose structured errors with sources where callers need policy control; application boundaries may aggregate errors when appropriate.
- Do not hide failures with wrong or degraded data. Any permitted degradation must be explicit in the contract.
- Public library APIs must not panic for ordinary failures. Document intentional panic conditions with rustdoc `# Panics`.
- Use `unwrap` only for a local, evident invariant.
- Add `unsafe` only for a necessary FFI, representation, or performance boundary. Each unsafe block needs a nearby `SAFETY:` explanation, and safe wrappers should make the contract narrow.

## Async, concurrency, and performance

- Define ownership, cancellation, shutdown, timeout, backpressure, and shared-state semantics for concurrent or async code.
- Do not hold synchronous locks across `.await`; select synchronization primitives that fit the executor and blocking behavior.
- Keep hot paths simple and measurable. Benchmark representative workloads before retaining complexity motivated by performance.
- Do not weaken validation, corruption checks, or other correctness guarantees for a benchmark unless the reduced-guarantee mode is explicit and documented.

## Testing

Read repository testing instructions and nearby tests first. Add the smallest test set that protects the changed observable contract, and state any intentionally reduced validation scope.

### Test placement and visibility

- Put unit tests with the implementation they exercise, normally in an inline `#[cfg(test)] mod tests`.
- Use crate-level `tests/` for black-box public API, cross-module, or workflow behavior; integration tests cannot access private implementation details.
- Use doctests when a public example is valuable executable documentation, and keep the example's imports and feature requirements realistic.
- Do not widen production visibility solely for tests. Test private behavior through its owning module or expose a public behavior only when that is the actual product contract.
- Split a large inline module into child files only for a coherent subsystem suite, substantial shared support, or a real harness constraint; do not collect unrelated tests in a generic `src/tests.rs`.

### Test support layout

- Keep helpers used by one inline module in that module.
- Put support shared within a private subsystem in that subsystem's test module, such as `tests/mod.rs`.
- Put support shared only by integration tests under the crate's `tests/` tree.
- Create a support crate only when multiple crates need a stable shared testing API.
- Keep fixtures, helpers, and assertion utilities scoped to their users; do not use support modules as miscellaneous test containers.

### Test design and techniques

- Unit tests should cover behavior owned by the module: representative success, meaningful boundaries, specified errors, and a minimal defect regression.
- Integration tests should cover representative public workflows, significant public failures, and composition or wiring that unit tests cannot protect.
- Use property tests for broad invariants, fuzzing for untrusted structured inputs, and temporary directories for filesystem contracts when those techniques match the changed behavior.
- Test feature-specific behavior with the relevant feature combinations, including default and no-default configurations when applicable.
- Keep tests deterministic under normal parallel execution: own temporary resources, control process-global state, use explicit seeds where needed, and avoid wall-clock sleeps for synchronization.

### Validation

1. Run the narrowest changed test or target.
2. Run the affected crate and relevant doctests, examples, targets, or feature combinations.
3. Expand to workspace checks required by project policy or the change risk.

Use existing project commands and report commands, results, and environment blockers distinctly.

## Rustdoc and public contracts

- Document public types, traits, functions, and methods when behavior, errors, invariants, panic conditions, or performance expectations are not self-evident.
- Add module documentation for non-obvious unsafe, concurrency, persistence, external-data, or cross-module contracts.
- Keep rustdoc focused on the supported contract and usage; record design history separately when it is needed.
