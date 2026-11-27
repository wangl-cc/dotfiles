# Notebook Dependencies

Declare PEP 723 dependencies in the notebook, including Marimo, direct requirements, and local packages. Inspect `sys.executable` and imported module paths in the actual kernel when diagnosing environment problems. If an existing notebook explicitly sets `[tool.marimo.venv]`, check the selected environment and use that project's dependency workflow before changing packages.

## Live Sandbox Packages

For ordinary package changes in a notebook-owned sandbox, run this in the live scratchpad:

```python
import marimo._code_mode as cm

async with cm.get_context() as ctx:
    ctx.packages.add("altair>=6,<7")
```

Package operations queue synchronously and apply on context exit. Use `ctx.packages.remove(...)` to remove a package and `ctx.packages.list()` in a fresh context to inspect the environment. Verify the saved header and installed package before rerunning the affected cells.

A library already loaded in the kernel can retain an earlier dependency check. For example, if Polars still reports missing PyArrow after installation, verify that PyArrow imports in that same kernel, then restart only the affected kernel if needed.

## Local Editable Packages

Declare the distribution name and a source path relative to the notebook. The distribution name can differ from its import name.

```python
# /// script
# requires-python = ">=3.13"
# dependencies = ["marimo", "analysis-helpers"]
#
# [tool.uv.sources]
# analysis-helpers = { path = "../packages/analysis_helpers", editable = true }
# ///
```

For a new or inactive notebook, edit the header or run `uv add --script notebooks/demo.py --editable ./packages/analysis_helpers` from the project root. For an active notebook, save it and close that session before editing the source table, then reopen it in the managed server. Code-mode package operations handle package specifiers. Use the notebook's source table to record editable paths.

Verify that the source path exists in the server container and the kernel imports the intended source. Changing the header takes effect when the sandbox is prepared again.

## Native Extensions and the Maturin Import Hook

Declare a local PyO3 package as an editable source using its distribution name. Confirm the server has the project's compiler, toolchain and system dependencies. An editable source declaration alone does not rebuild an extension after Rust changes. Use the project's explicit rebuild command for the target environment or activate the Maturin import hook there.

For the standard hook, declare `maturin` and `maturin-import-hook` in the notebook dependencies. Activate it in setup before importing the native package. For a live notebook, edit the setup cell through code mode.

```python
import maturin_import_hook
from maturin_import_hook.settings import MaturinSettings

maturin_import_hook.install(settings=MaturinSettings(release=True, uv=True))
```

If the project provides a custom hook for workspace source tracking, declare its importable source in the sandbox and use that hook. A hook registered by `sitecustomize` in a project venv belongs to that environment.

Check hook registration in the kernel:

```python
import sys

print([type(finder).__name__ for finder in sys.meta_path
       if "maturin" in type(finder).__module__])
```

Then use a fresh affected kernel to observe the rebuild on the first import and exercise a small changed behavior. Verify the extension's `__file__` to confirm which binary was loaded. Repeating an import in a kernel that already loaded the module does not exercise a rebuild.

## Further Reading

- [Marimo inline dependencies and local editable sources](https://docs.marimo.io/guides/package_management/inlining_dependencies/)
- [uv script dependencies](https://docs.astral.sh/uv/guides/scripts/#declaring-script-dependencies)
- [Maturin import hook](https://www.maturin.rs/import_hook)
