# JavaScript ecosystem guidance

## Runtime and tooling

- Inspect `packageManager`, lockfiles, `engines`, runtime version files, `tsconfig` or `jsconfig`, package scripts, and relevant build configuration before choosing commands or changing the toolchain.
- For a new standalone project, add its selected formatting, linting, type-checking, and test tools to `devDependencies` and include the corresponding lockfile update.
- Preserve the repository's runtime, package manager, lockfile, and workspace conventions. Do not create a second lockfile, switch tooling, or cause unrelated lockfile churn.
- Prefer project scripts for build, check, lint, test, and release workflows. Change dependencies only when the task requires it and review the resulting manifest and lockfile changes together.

## Modules and public surface

- Preserve the project's ESM or CommonJS model, package `type`, file extensions, import conventions, and module-resolution strategy unless the task explicitly changes that contract.
- Treat `exports`, `imports`, `types`, `typesVersions`, entry points, declaration output, and build targets as public interfaces. Verify both source-level typing and the artifacts or package paths consumers actually load.
- Keep Node.js, browser, worker, and edge-runtime boundaries explicit; do not assume APIs, globals, module formats, or environment variables cross those boundaries.

## Types and runtime data

- Preserve the project's TypeScript strictness. Prefer `unknown` followed by narrowing over `any`, and use type assertions or non-null assertions only when an established invariant justifies them.
- TypeScript types do not validate runtime input. Validate external data at its trust boundary and convert it into an internal representation that downstream code can rely on.

## Asynchronous work

- Await promises or deliberately assign ownership for detached work, including error handling and lifecycle. Do not leave floating promises accidentally.
- Propagate cancellation with `AbortSignal` where supported, bound waits with appropriate timeouts, and release listeners, timers, subscriptions, streams, and other resources during cleanup or shutdown.

## Validation

- Run the repository's relevant typecheck, lint, tests, build, and package verification at the narrowest useful scope, expanding with risk. A passing typecheck alone does not verify bundling, runtime behavior, generated declarations, or package exports.
- For ad-hoc validation in an existing project, use `pnx` for tools not managed by the project.
