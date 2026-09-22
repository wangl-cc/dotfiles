# Dependencies, Local Packages, and Native Extensions

Use this guide when adding, removing, or diagnosing a notebook dependency. Perform changes within the user's requested scope; an installation example is not a reason to migrate environments or synchronize unrelated projects.

## Choose the Environment Owner

Read the notebook's PEP 723 header and the project's package configuration. Inspect the actual interpreter through `execute-code.sh` in the target session:

```python
import sys
print(sys.executable)
print(sys.prefix)
```

| Environment | Persistent dependency declaration | Installation workflow |
| --- | --- | --- |
| Notebook sandbox without `[tool.marimo.venv]` | Notebook `dependencies` and `tool.uv.sources` | Live ordinary packages through `ctx.packages`; local sources through the header workflow below |
| Explicit project `.venv` | Project `pyproject.toml` and lockfile | Project package manager, such as `uv add` from the project root |

A configured project venv replaces the automatic notebook sandbox. Inline `dependencies` may still be written in that mode; their presence does not prove a second environment exists. In the inspected marimo 0.24 implementation, `writable=false` does not block all missing-package or UI installation paths. Those paths can change the project venv without updating its lockfile.

## Ordinary Packages

### Live notebook sandbox

Run this through the skill's execution script, in the scratchpad, after confirming the notebook owns its sandbox:

```python
import marimo._code_mode as cm

async with cm.get_context() as ctx:
    ctx.packages.add("altair>=6,<7")
```

Use a package name for normal resolution, a range for compatibility constraints, or `name==version` when an exact version is required. Preserve existing constraints unless changing them is part of the task. To remove a dependency, use `ctx.packages.remove("altair")` after removing or replacing dependent notebook code.

These operations are synchronous queueing calls; installation runs on context exit. They do not automatically rerun cells. Verify installation in a subsequent call, then deliberately rerun the affected cells. To list packages, use `ctx.packages.list()` in a fresh context, not after queueing additions or removals. Check the active kernel's API when signatures differ; `marimo._code_mode` is private and belongs only in the scratchpad.

An execution request completing successfully is not sufficient proof that package installation succeeded. Inspect installation errors, the installed distribution, and the saved header using the verification steps below.

### Project-owned environment

From the actual project root, for an authorized dependency change:

```bash
uv add 'altair>=6,<7'
```

This updates project metadata, the lockfile, and normally synchronizes the project environment. Use the project's selected groups/extras when applicable, and verify that the resulting environment is the one used by the kernel. `uv pip install` only changing a venv is insufficient for a durable project dependency.

Review `pyproject.toml` and `uv.lock`. A shared project venv can serve several kernels, so changes may affect other notebooks. Do not run `uv sync` as a diagnostic step: it can remove packages missing from the project's declaration. Restart only affected kernels when loaded packages need refreshing.

## Local Python Packages

A local source dependency points to a package directory containing a valid `pyproject.toml` and build configuration. The distribution name in `dependencies` must match that package's project name; its Python import name may differ, such as `analysis-helpers` versus `analysis_helpers`.

### Notebook-owned source configuration

The inspected `ctx.packages.add()` accepts package specifiers but has no dedicated editable/source-table API. Do not invent `editable=True` arguments or assume a transient installation persists the required source configuration.

For a new or inactive notebook, configure its existing PEP 723 header. For an active notebook, save work, end that notebook's session, and confirm it is no longer active before editing the file or running `uv add --script`. Reopen it through the shared server afterward; changing source metadata on disk does not reconfigure an already running kernel. Do not stop the shared service. These commands can update script metadata even while a session is live, which is why the lifecycle check matters.

Given this layout:

```text
project/
  notebooks/demo.py
  packages/analysis_helpers/pyproject.toml
  packages/analysis_helpers/src/analysis_helpers/__init__.py
```

From `project/`, add the local package to the inactive notebook:

```bash
uv add --script notebooks/demo.py --editable ./packages/analysis_helpers
```

The resulting source entry is relative to the notebook file, even though the CLI path was relative to the command's working directory. Merge it with existing dependencies and sources; retain marimo and other required packages:

```python
# /// script
# requires-python = ">=3.13"
# dependencies = ["marimo", "analysis-helpers"]
#
# [tool.uv.sources]
# analysis-helpers = { path = "../packages/analysis_helpers", editable = true }
# ///
```

Use a Python requirement compatible with all selected packages. The package source must exist at the resolved path inside the marimo container. This uses the local source without importing packages from the project's `.venv`. Ordinary Python edits in an editable package are visible to new imports; already imported modules may need reloading or a kernel restart.

For an inactive notebook, ordinary dependencies can likewise be declared with `uv add --script notebooks/demo.py 'altair>=6,<7'`. This updates the script declaration, not the project's `pyproject.toml`, and does not install into an already running kernel. Reopening through the sandbox server prepares the environment. Running `uv run` on the real notebook is not a harmless install check: it can execute the notebook's workload.

### Project-owned local dependency

From the project root:

```bash
uv add --editable ./packages/analysis_helpers
```

If the package is already a uv workspace member, follow the existing workspace source declarations instead of replacing them. uv may add an in-tree package as a workspace member; use `--no-workspace` when it should remain a direct path dependency. Verify the project diff and the kernel's imported package location.

## Native Extensions

Rust/PyO3 packages with a Maturin build backend can be local sandbox dependencies just like Python packages. For example, ecDNA's distribution is `ecdna-native`, its source directory is `pybinding`, and its extension import is `ecdna._native`. From that project root, the inactive-notebook declaration can be added with:

```bash
uv add --script notebooks/demo.py --editable ./pybinding
```

This records the native package source; it does not validate compilation or make project helpers importable. Declare other local packages used by the notebook as well, including the package providing `utils` if needed. Inspect workspace dependencies and source resolution instead of assuming the root project's complete environment is inherited.

Before opening the sandbox, check its Python compatibility and the container's compiler, Cargo toolchain, build backend, and required system libraries. ecDNA's BLAS linkage needs a compatible BLAS library at runtime and development files when compiling. Mounting a source tree or `.venv` does not supply libraries installed in another container.

Editable installation does not itself rebuild changed Rust code. Choose the project's supported rebuild workflow:

- **Import hook:** install its dependencies into the target environment and activate it before the first import of the native package.
- **Explicit build:** use the project's documented Maturin command while deliberately targeting the environment in use. A bare `uv run maturin develop` in the project targets the project environment, not an unrelated notebook sandbox. A plain `cargo build` does not establish that Python imports the resulting library.
- **Wheel:** build a compatible wheel and declare its local path as the dependency source. Rebuild and reinstall it when native code changes; wheel installation is not editable.

### Activate and Verify the Import Hook

The target environment needs both `maturin` and `maturin-import-hook`. Put them in the notebook's inline dependencies for a sandbox or the appropriate project development group for a project venv. Installing those distributions alone does not activate the hook.

For a package adequately handled by the standard hook, persist activation in a setup cell before importing the native package, using `cm` to edit a live notebook:

```python
import maturin_import_hook
from maturin_import_hook.settings import MaturinSettings

maturin_import_hook.install(settings=MaturinSettings(release=True, uv=True))
# Import the native package only after installing the hook.
```

Use the project's existing custom hook when it covers additional source dependencies. For ecDNA, `ecdna_maturin_hook.install()` adds workspace source tracking. Make that module importable in the sandbox first: the root project's package configuration must actually include it, or it must be available through an intentional notebook module layout. Merely installing the root distribution does not guarantee every root-level `.py` file is included. Do not silently replace a custom source searcher with the default hook.

A `sitecustomize` registration belongs to one Python environment and is not inherited by a new sandbox. Notebook setup activation travels with the notebook; a project-specific helper still needs a declared, importable source. Keep hook activation before native imports rather than in an unrelated reactive cell whose execution order is uncertain.

Check registration without importing the extension or triggering a build:

```python
import sys
print([type(f).__module__ + "." + type(f).__name__
       for f in sys.meta_path if "maturin" in type(f).__module__])
```

Registration verifies activation, not successful rebuilding. For an authorized native change, verify that the hook tracks the changed source, observe the rebuild on a fresh kernel import, and run a small check of the changed behavior. Repeated `import` of an already loaded module is not a rebuild test. Prefer an affected-kernel restart when native objects are already in use; do not assume reloading updates existing references. Editable builds may write compiled artifacts into the shared source tree, so separate sandboxes do not guarantee independent native build artifacts.

## Small Local Helpers

Choose the smallest durable home for the helper:

| Helper scope | Placement |
| --- | --- |
| Only this notebook | A function in a notebook cell, written through `cm`; no package installation |
| A small module kept beside the notebook | Import the sibling module only after verifying the notebook directory is on the kernel's import path and the intended file is imported |
| Shared by multiple notebooks or projects | An existing package, or a small installable package with explicit source and dependency declarations |

For a shared `analysis_helpers` package, use the local editable workflow above and import `analysis_helpers`. Its own third-party requirements belong in its package metadata. Do not add repeated `sys.path` patches or absolute developer-machine paths to notebooks to hide packaging problems. If a standalone helper is not importable, fix its module/package layout within the requested scope. Verify imports in the notebook kernel: success from a shell whose working directory is the project root is insufficient.

## Verify the Result

After installation or a session restart, run a scratchpad check in the target kernel, adapting distribution and import names:

```python
import importlib
import importlib.metadata as metadata
import sys

module = importlib.import_module("altair")
print(sys.executable)
print(metadata.version("altair"))
print(module.__file__)
```

For an editable dependency, also inspect `metadata.distribution("analysis-helpers").read_text("direct_url.json")` and `analysis_helpers.__file__`. For native packages, inspect the extension's `__file__` and exercise one small relevant function; an installed distribution is not proof that its shared library can load.

Review the notebook header or project metadata and lockfile, as appropriate. Record which environment changed, whether source declarations persisted, and whether imports/rebuilds were actually tested. Never claim a notebook migration or native rebuild based only on a successful metadata edit.

## Sources

- [marimo inline dependencies and local editable sources](https://docs.marimo.io/guides/package_management/inlining_dependencies/#local-development-with-editable-installs)
- [uv script dependencies](https://docs.astral.sh/uv/guides/scripts/#declaring-script-dependencies) and [project dependencies](https://docs.astral.sh/uv/concepts/projects/dependencies/)
- [Maturin local development](https://www.maturin.rs/local_development) and [import hook activation](https://www.maturin.rs/import_hook)
