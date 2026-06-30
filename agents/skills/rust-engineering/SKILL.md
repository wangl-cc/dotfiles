---
name: rust-engineering
description: Use when editing, formatting, testing, reviewing, or designing Rust code. Covers project-local policy precedence, Rust toolchain and formatter selection, MSRV-aware idioms, ownership-aware API design, correctness boundaries, unsafe code, lints, dependencies, and tests.
---

# Rust Engineering

## Scope

Use this skill before editing, formatting, testing, reviewing, or designing Rust code.

## Project Baseline

### Local Policy

- Follow project-local policy before this skill, including `rust-toolchain.toml`, `rust-toolchain`, CI commands, `Cargo.toml`, `clippy.toml`, `rustfmt.toml`, `.rustfmt.toml`, crate README, and CONTRIBUTING docs.

### Toolchain and Formatting

- When formatting, first identify the project's pinned toolchain and rustfmt configuration, then use the formatter command that matches CI behavior.
- If no project policy exists, use stable defaults such as `cargo fmt`.
- Use `cargo +nightly fmt` only when the project explicitly relies on nightly Rust or unstable rustfmt options.

### Verification

- Prefer the project's CI-equivalent commands. When no project policy exists, use `cargo fmt --check`, `cargo clippy --all-targets --all-features`, and `cargo test --workspace --all-features` as the default quality gate.
- Scope verification to the touched crate or feature set when full-workspace checks are impractical, and state the reduced scope in the final response.
- Add specialized checks, such as examples, doctests, benches, Miri, fuzzing, or sanitizers, when the changed code relies on them or the risk profile justifies the extra coverage.

### Lint Discipline

- Follow the project's lint policy. Do not silence warnings by broad `#[allow(...)]`, dummy assignments, or unused bindings unless the lint exception is intentional and narrowly scoped.
- When a lint must be broken and the MSRV supports it, prefer `#[expect(lint_name, reason = "...")]` over `#[allow(...)]` so the exception fails closed if it becomes unnecessary.
- If `#[allow(...)]` is required, keep it on the smallest item or expression practical and include a reason, such as `#[allow(lint_name, reason = "...")]`, when supported by the toolchain.

## Design and API Shape

This skill specializes the global engineering design discipline for Rust. Do
not treat invariant ownership, boundary validation, domain-axis decomposition,
or responsibility/lifecycle separation as Rust-only concerns.

### Quality Bar

- Prefer type-level invariants and explicit ownership or lifecycle models over runtime fallback branches.
- Keep behavior changes narrow and reviewable; make contract, correctness, and migration impacts explicit when they change.
- Optimize for long-term maintainability, correctness, and reviewability rather than only making the code compile or the benchmark improve.
- Do not choose a lower-quality structure for speed. Follow established Rust best practices even for small CLIs, prototypes, or one-off tools; spending a little more design time to model ownership, invariants, and error boundaries correctly is expected.

### Code Organization

- Model stateful concepts, ownership, and invariants as explicit types with methods. Avoid large clusters of free helper functions when the logic belongs to a domain type.
- Before adding or keeping a free helper function, identify the invariant owner. If the function validates, constructs, derives, mutates, caches, schedules, samples, or interprets data for a specific type or domain concept, prefer an inherent method, associated function, or small owning type instead of a free function.
- Keep free functions only when they are genuinely ownerless algorithms, narrow local mechanics, or mathematically pure helpers whose receiver would be artificial. Name and place them so their lack of ownership is obvious.
- When refactoring or reviewing Rust modules, scan module-level `fn` and `pub(crate) fn` items deliberately. Move helpers back onto the type that owns their state, layout, cache, validation rule, or lifecycle before presenting the code as finished.
- Do not use "script-like" free-function organization as a shortcut when a coherent domain type or method receiver would better express ownership, state, or invariants. Temporary exploration code must be reshaped before handoff rather than presented as finished Rust.
- Split modules by domain concepts, responsibility, and invariant ownership. Avoid flat module structures once a crate has multiple independent concepts.
- Separate domain logic from I/O, filesystem, network, process, or other side effects when the boundary is natural; this keeps behavior easier to unit test, validate, and reuse.
- Keep module boundaries natural for review: each module should have a small purpose, a clear owner for its invariants, and limited knowledge of unrelated internals.
- Extract shared helpers or types for meaningful repeated logic when the abstraction clarifies behavior and preserves invariants; avoid abstracting incidental similarity that makes the code harder to read.
- Prefer one correct path over compatibility shims, workaround branches, or defensive fallbacks. If fallback behavior is required, document the external constraint that makes it necessary.
- Remove prototype residue before handoff: unused config fields, temporary scripts, stale plans, experimental APIs, and debug-only code should either be deleted or explicitly marked experimental.

### API Ownership

- Prefer borrowed parameters for read-only inputs, such as `&str`, `&Path`, and `&[T]`. Accept owned values when the function needs to store, transfer, mutate independently, or outlive the caller's data.
- Avoid converting inputs to owned values at API boundaries unless ownership is part of the contract. Preserve ownership through iterators, slices, references, or `Cow` when that keeps the API clear.
- Use generic bounds such as `AsRef`, `Into`, or iterator traits when they make call sites meaningfully better; avoid generic flexibility that worsens diagnostics, readability, or code size without clear benefit.
- Introduce traits for real abstraction boundaries, not only for speculation or one-off testing. Public traits, blanket impls, associated types, and object-safety choices are long-term API commitments.

### Public Contracts and Documentation

- Document public types, traits, functions, and methods with rustdoc that explains behavior, errors, invariants, and performance-relevant expectations.
- Write rustdoc and comments with semantic line breaks: keep a sentence on one line when it fits the project comment width,
  and break longer sentences at clause, condition, list, or example boundaries instead of pre-wrapping mechanically at 80 columns.
- Add module-level docs for modules that encode non-obvious contracts, such as unsafe assumptions, concurrency assumptions, external data semantics, persistence semantics, or cross-module invariants.
- Keep user-facing docs focused on final purpose, contract, and usage. Put rejected alternatives or design history in an ADR-style document, not in normal API docs.
- Make global behavior explicit through named constants, types, and docs rather than scattering magic values across implementation code.
- For public crates, treat API changes through a semver lens. Document migration-relevant changes, avoid accidental public surface expansion, and consider `#[non_exhaustive]` when future-compatible extension matters.

## Compatibility and Dependency Surface

### MSRV and Edition

- Respect the project's declared MSRV, edition, and feature matrix, especially `rust-version`, CI jobs, release policy, and documented supported targets.
- When the MSRV is modern enough, prefer clear current Rust idioms over older compatibility patterns, such as let chains, let guards, `let else`, or standard-library APIs supported by the declared MSRV.

### Dependencies and Cargo Features

- Add dependencies only when they provide clear value over small local code, and prefer established crates already used by the project.
- Treat Cargo features as part of the public contract. Avoid changing default features or enabling heavyweight optional functionality unless the behavior and downstream impact are intentional.
- Keep `Cargo.toml` changes focused: avoid broad version churn, unrelated feature toggles, or workspace metadata edits.
- When feature behavior changes, verify the relevant combinations instead of relying only on `--all-features`; include default features, `--no-default-features`, or targeted feature sets when they matter.

## Correctness Boundaries

### Error Semantics

- Define error semantics at the right abstraction layer before implementing branches. Be explicit about which cases are hard errors, recoverable errors, not-found results, invalid inputs, invalid state, or intentionally ignored conditions.
- In library crates, prefer structured public errors that preserve sources and let callers decide policy. Reserve `anyhow`-style aggregation for application or binary boundaries unless the crate already exposes that style.
- Never return wrong data to hide a failure. If the domain permits degradation, make the degraded behavior part of the documented contract and test it directly.

### Panics and Unwrap

- Public library APIs should not panic for ordinary errors. Document intentional panic conditions in rustdoc, preferably with a `# Panics` section.
- Use `unwrap` only when the invariant is local and obvious, and include a short justification if it is not immediately self-evident.

### Unsafe Code

- Avoid adding `unsafe` unless it is necessary for a clear boundary with performance, FFI, or low-level representation requirements.
- Every `unsafe` block should have a nearby `SAFETY:` comment that states the invariant being upheld. Prefer safe wrappers that make the unsafe contract narrow and testable.

### External State and Determinism

- Treat persistence, crash recovery, and external resource invariants as first-class behavior when the code owns them. Test partial updates, invalid external state, and reopen or retry behavior when relevant.
- Keep nondeterministic dependencies, such as clocks, randomness, environment variables, current directories, process state, and external services, at explicit boundaries.
- When those dependencies affect behavior, pass them as parameters, traits, small adapters, or test helpers instead of letting core logic read global process state directly.

## Runtime Behavior

### Concurrency and Async

- Define cancellation, shutdown, timeout, backpressure, and shared-state ownership semantics explicitly when working with concurrent or async code.
- Avoid holding synchronous locks across `.await`; choose synchronization primitives that match the executor, blocking behavior, and ownership model.

### Performance

- Keep hot paths simple and measurable. Avoid clever special cases unless they are backed by benchmarks or a clear workload-specific reason.
- Avoid unnecessary allocation and cloning. Do not use `to_string`, `to_vec`, `clone`, or owned collections casually when borrowing, slices, `Cow`, or ownership-preserving APIs are sufficient.
- Benchmark meaningful workload shapes rather than only microbenchmarks that make the implementation look good.
- Report benchmark assumptions and tradeoffs when performance drives a design choice, especially if correctness checks, copies, allocation, or I/O behavior differ across implementations.
- Do not weaken validation or corruption checks merely to improve benchmark numbers unless the mode is explicitly named, documented, and excluded from correctness-sensitive defaults.

## Testing

### Placement and Scope

- Put Rust unit tests in the same module/file as the behavior or invariant they exercise whenever practical. Prefer an in-module `#[cfg(test)] mod tests` over accumulating unit tests in the crate root or a distant test module.
- Organize module tests by scope and behavior rather than accumulating unrelated cases in one file. Keep crate-root tests and integration tests for black-box cross-module behavior, public convenience APIs, or workflows that genuinely span modules.

### Test Helper Shape

- Split test helpers by conceptual role when that makes the test easier to read, such as setup, exercising behavior, building expected values, and asserting acceptance criteria.
- Avoid extracting one-line or two-line helpers that scatter a simple expression or tightly coupled idea across multiple names. Keep cohesive calculations close enough that reviewers can see the whole assertion.
- Name helpers after the behavior and acceptance rule they check rather than vague mechanics.

### Coverage Shape

- Add tests for both the happy path and the invariant boundary: invalid inputs, boundary values, duplicate or conflicting data, ordering assumptions, state transitions, resource failures, and public error classification where applicable.
- When tests depend on nondeterministic inputs such as randomness, clocks, ordering, or external state, make reproducibility explicit through project-local policy, dependency injection, or focused test helpers.
- Use doctests for public examples, property tests for broad invariant spaces, fuzzing for structured or untrusted inputs, and temporary directories for filesystem behavior when adding or changing those behaviors.
- When optimizing code, preserve or add correctness tests before relying on benchmarks.
