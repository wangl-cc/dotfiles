---
name: rust-engineering
description: Use when editing, formatting, reviewing, or designing Rust code. Covers project toolchains, MSRV, Rust ownership and APIs, Cargo features, errors, unsafe code, concurrency, performance, and public Rust contracts.
---

# Rust Engineering

## Scope

Use this skill for Rust-specific implementation and review decisions. Follow project-local policy first. When tests change, also use `rust-testing` for test placement and validation.

## Project Toolchain and Lints

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

## Cargo and Compatibility

- Add dependencies only for clear value over local code and prefer crates already established by the project.
- Treat Cargo features, defaults, and optional dependencies as public behavior. Avoid unrelated version churn or feature toggles.
- When feature behavior changes, validate relevant combinations, including default features, `--no-default-features`, or targeted features as applicable; `--all-features` alone can conceal incompatibilities.
- For public crates, review changed surface area through a semver lens and avoid accidental exports. Consider `#[non_exhaustive]` only when forward-compatible extension is a real requirement.

## Failure and Safety Semantics

- Make error semantics explicit: distinguish invalid input or state, not-found, recoverable failures, and hard failures at the owning abstraction boundary.
- Library crates should expose structured errors with sources where callers need policy control; application boundaries may aggregate errors when appropriate.
- Do not hide failures with wrong or degraded data. Any permitted degradation must be explicit in the contract.
- Public library APIs must not panic for ordinary failures. Document intentional panic conditions with rustdoc `# Panics`.
- Use `unwrap` only for a local, evident invariant.
- Add `unsafe` only for a necessary FFI, representation, or performance boundary. Each unsafe block needs a nearby `SAFETY:` explanation, and safe wrappers should make the contract narrow.

## Async, Concurrency, and Performance

- Define ownership, cancellation, shutdown, timeout, backpressure, and shared-state semantics for concurrent or async code.
- Do not hold synchronous locks across `.await`; select synchronization primitives that fit the executor and blocking behavior.
- Keep hot paths simple and measurable. Benchmark representative workloads before retaining complexity motivated by performance.
- Do not weaken validation, corruption checks, or other correctness guarantees for a benchmark unless the reduced-guarantee mode is explicit and documented.

## Rustdoc and Public Contracts

- Document public types, traits, functions, and methods when behavior, errors, invariants, panic conditions, or performance expectations are not self-evident.
- Add module documentation for non-obvious unsafe, concurrency, persistence, external-data, or cross-module contracts.
- Keep rustdoc focused on the supported contract and usage; record design history separately when it is needed.
