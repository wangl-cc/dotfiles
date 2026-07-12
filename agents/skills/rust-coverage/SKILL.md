---
name: rust-coverage
description: Run and interpret Rust test coverage with cargo llvm-cov through a bundled script. Use for crate or workspace coverage summaries, uncovered lines/functions, diff-focused coverage review, targeted Rust test-gap recommendations, or cargo llvm-cov troubleshooting.
---

Run `scripts/cargo_llvm_cov.py` directly for Rust coverage work. Do not prefix it with an interpreter, and do not hand-build `cargo llvm-cov` commands, coverage parsing, diff matching, timeout handling, or output shaping that the script already provides.

When running from a project directory, use the resolved absolute script path and pass `--cwd <repo-or-crate>`.

The default toolchain is `nightly`, so coverage commands run as `cargo +nightly llvm-cov`. Use `--toolchain <name>` only when project policy requires another channel, pinned version, or named toolchain.

Choose the smallest meaningful scope. Prefer `-p <crate>` for crate, module, PR, or focused test-gap questions. Use `--workspace` only when the question is cross-crate, the changed behavior spans crates, or final validation needs the whole workspace.

Select the command by intent:

- `check`: verify that Cargo and cargo-llvm-cov are available.
- `summary`: report compact line, function, region, and branch totals.
- `uncovered`: list uncovered source lines; add `--verbose` only when zero-hit function records help diagnose a gap.
- `diff-uncovered`: review uncovered executable lines introduced by the current diff.

The script emits compact line-oriented text for agent consumption. Treat its process exit code as the mechanical outcome. Internal llvm-cov JSON is temporary implementation data and is not part of the agent-facing contract.

For review and final validation, prefer `diff-uncovered` over percentage summaries. Set `--base` to the reviewed diff base: use `HEAD` for working-tree changes and the merge base or PR base for a committed branch. Add `--fail-on-diff-uncovered` when uncovered changed lines should fail the command.

`zero_hit_changed_function_records` is diagnostic only. Rust generics and multiple test binaries can leave zero-hit function records even when the corresponding changed source line is covered, so function records must not decide diff pass/fail. Use `--verbose` to inspect them when troubleshooting.

Treat every non-zero script exit as a failed coverage run. Report the command, scope, status, relevant uncovered locations or failure stage, and whether ordinary tests are known to pass.

Interpret uncovered lines as evidence about behavior, invariants, and missing tests. Do not chase percentages or function-record counts for their own sake; recommend or add tests only when the uncovered behavior matters.
