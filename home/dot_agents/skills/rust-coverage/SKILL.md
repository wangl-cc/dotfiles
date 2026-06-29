---
name: rust-coverage
description: Run and interpret Rust test coverage with cargo llvm-cov through a bundled script. Use for crate or workspace coverage summaries, uncovered lines/functions, diff-focused coverage review, targeted Rust test-gap recommendations, or cargo llvm-cov troubleshooting.
---

Run `scripts/cargo_llvm_cov.py` directly for Rust coverage work. Do not prefix
it with an interpreter, and do not hand-build `cargo llvm-cov` commands,
coverage JSON parsing, diff matching, timeout handling, or output shaping that
the script already provides.

When running from a project directory, use the resolved absolute script path and
pass `--cwd <repo-or-crate>`.

Choose the smallest meaningful scope. Prefer `-p <crate>` for crate, module,
PR, or focused test-gap questions. Use `--workspace` only when the question is
cross-crate, the changed behavior spans crates, or final validation needs the
whole workspace.

Select the script action by intent:

- `check`: verify that required coverage tooling is available.
- `summary`: get coverage totals when the user asks for an overview.
- `uncovered`: inspect concrete uncovered lines or functions in the chosen
  scope.
- `diff-uncovered`: review or final validation of uncovered executable lines
  introduced by the current diff.

For review and final validation, prefer `diff-uncovered` over percentage
summaries. Set `--base` to the reviewed diff base; use the default `HEAD` only
for working-tree diffs. For a committed branch, pass the merge base or PR base;
add `--fail-on-diff-uncovered` when uncovered changed lines should fail the
check. If it reports `diff_uncovered.matched=false`, inspect `raw_uncovered`
before concluding: the diff may be covered even when unrelated code in the same
scope remains uncovered.

Treat every non-zero script exit as a failed coverage run, even if JSON was
returned. Report the script subcommand and scope, exit status, relevant JSON
fields, and whether ordinary tests are known to pass.

Interpret uncovered lines as evidence about behavior, invariants, and missing
tests. Do not chase percentages for their own sake; recommend or add tests only
when the uncovered behavior matters.
