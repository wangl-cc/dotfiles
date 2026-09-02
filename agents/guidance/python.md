# Python guidance

Apply these defaults when editing, reviewing, debugging, designing, or validating Python unless they conflict with the user's current request or repository-local instructions.

## Compatibility and project shape

- Read the repository's documented commands and relevant Python configuration before choosing tools or making changes. Identify `requires-python`, the package layout, build backend, environment and dependency manager, and configured formatter, linter, type checker, and test runner.
- For a new project without conflicting requirements, use uv for project and dependency management, and add Ruff and ty to its development dependency group.
- Preserve the declared Python compatibility range. Do not reduce supported syntax for an unrelated system interpreter or introduce syntax and APIs unavailable to supported versions; run project work in the environment selected by the repository.
- Distinguish importable packages, modules, entry points, and standalone scripts. Fix import and packaging problems at their owning boundary rather than relying on the current directory or `sys.path` manipulation to hide them.

## Types and runtime boundaries

- Preserve the project's type-checking policy. Prefer precise annotations and narrowing, and contain `Any` at genuinely untyped boundaries rather than allowing it to spread through internal code.
- Type annotations do not validate runtime input. Validate external data at its trust boundary and convert it into an internal representation that downstream code can rely on.

## Packaging and public surface

- Treat public import paths, exported names, entry points, extras, optional dependencies, package data, and built artifacts as interfaces. Review compatibility when they change.
- Preserve the project's build backend and source layout. When packaging behavior changes, verify the artifacts and installed behavior that consumers actually use rather than relying only on source-tree imports.

## uv-managed projects

- Apply this subsection only when the project selects uv through `uv.lock`, `uv.toml`, `[tool.uv]`, or repository instructions that use uv for project environment or dependency management. A generic `pyproject.toml`, package directory, test suite, `.venv`, `uvx` invocation, or standalone `uv run --script` command alone is not evidence that uv owns the project workflow.
- Read the project's dependency groups, extras, workspace configuration, sources, indexes, and lockfile conventions before choosing uv options.
- Run project commands and project-owned tools through `uv run`, preserving the project's selected groups, extras, package, workspace, and Python-version behavior.
- Prefer `uv run --locked` for validation when a lockfile is present and the task does not authorize changing it. Use `uv sync --check` to verify that the environment is synchronized without modifying it when that state matters.
- Use `uv sync` only when creating or intentionally refreshing the project environment. Use `uv add`, `uv remove`, or `uv lock` only for an authorized dependency or resolution change, and review `pyproject.toml` and `uv.lock` together.
- Preserve uv configuration and lockfile metadata. Do not introduce uv into an existing unconfigured project, change indexes or sources, alter dependency groups, or refresh unrelated versions without a task need.
- Treat a session-owned standalone script outside a configured project as a separate `uv run --script` workflow rather than as a uv-managed project; follow a third-party script's instructions when it must run unchanged.

## Validation

- Prefer the project's documented formatter, linter, type checker, tests, build, and packaging commands. Validate narrowly first, then expand according to affected scope and risk.
- For ad-hoc validation in an existing project, use `uvx` for Ruff or ty only when that tool is not project-managed.
- When the project has no more specific commands, use the applicable project-native checks and focused tests; do not assume one generic command covers every project layout.
- Report the exact commands run and their results. For uv-managed projects, also report whether validation preserved the lockfile and whether any command modified the project environment.
