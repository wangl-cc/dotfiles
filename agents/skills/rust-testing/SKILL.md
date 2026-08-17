---
name: rust-testing
description: Design, place, review, and validate Rust tests. Use when adding, changing, reviewing, or reorganizing tests, or when a Rust behavior change or defect fix needs test coverage.
---

# Rust Testing

## Scope

Use this skill for Rust test structure, support layout, and validation. Read repository testing instructions and nearby tests first. Add the smallest test set that protects the changed observable contract, and state any intentionally reduced validation scope.

## Test Locations and Visibility

- Put unit tests with the implementation they exercise, normally in an inline `#[cfg(test)] mod tests`.
- Use crate-level `tests/` for black-box public API, cross-module, or workflow behavior; integration tests cannot access private implementation details.
- Use doctests when a public example is valuable executable documentation, and keep the example's imports and feature requirements realistic.
- Do not widen production visibility solely for tests. Test private behavior through its owning module or expose a public behavior only when that is the actual product contract.
- Split a large inline module into child files only for a coherent subsystem suite, substantial shared support, or a real harness constraint; do not collect unrelated tests in a generic `src/tests.rs`.

## Test Support Layout

- Keep helpers used by one inline module in that module.
- Put support shared within a private subsystem in that subsystem's test module, such as `tests/mod.rs`.
- Put support shared only by integration tests under the crate's `tests/` tree.
- Create a support crate only when multiple crates need a stable shared testing API.
- Keep fixtures, helpers, and assertion utilities scoped to their users; do not use support modules as miscellaneous test containers.

## Rust Test Coverage

- Unit tests should cover behavior owned by the module: representative success, meaningful boundaries, specified errors, and a minimal defect regression.
- Integration tests should cover representative public workflows, significant public failures, and composition or wiring that unit tests cannot protect.
- Use property tests for broad invariants, fuzzing for untrusted structured inputs, and temporary directories for filesystem contracts when those techniques match the changed behavior.
- Test feature-specific behavior with the relevant feature combinations, including default and no-default configurations when applicable.
- Keep tests deterministic under normal parallel execution: own temporary resources, control process-global state, use explicit seeds where needed, and avoid wall-clock sleeps for synchronization.

## Validation

1. Run the narrowest changed test or target.
2. Run the affected crate and relevant doctests, examples, targets, or feature combinations.
3. Expand to workspace checks required by project policy or the change risk.

Use existing project commands and report commands, results, and environment blockers distinctly.
