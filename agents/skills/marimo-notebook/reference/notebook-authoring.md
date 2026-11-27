# Notebook Authoring

Use this reference for new notebook files and source organization. For active notebooks, submit cell bodies through [live code mode](live-sessions.md); do not write serialized decorators into the scratchpad or edit the running notebook's file.

## Dependencies and Entry Point

Every notebook has a PEP 723 header with a compatible Python requirement and all required dependency declarations. Include local helper packages with relative editable sources as described in [dependencies](dependencies.md). Keep `__generated_with` consistent with the Marimo version used to write the notebook.

A small example with actual reactive inputs:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["marimo>=0.24"]
# ///

import marimo

__generated_with = "0.24.2"
app = marimo.App(width="medium")


with app.setup:
    import marimo as mo


@app.function
def scale_values(values: list[int], factor: int) -> list[int]:
    return [value * factor for value in values]


@app.cell(hide_code=True)
def _():
    mo.md("""
    # Scaling values

    Change the multiplier to inspect how the output follows the input.
    """)
    return


@app.cell
def _():
    source_values = [1, 2, 3]
    return (source_values,)


@app.cell
def _():
    multiplier = mo.ui.slider(1, 5, value=2, label="Multiplier")
    multiplier
    return (multiplier,)


@app.cell
def _(multiplier, source_values):
    scaled_values = scale_values(source_values, multiplier.value)
    mo.ui.table({"input": source_values, "output": scaled_values})
    return (scaled_values,)


if __name__ == "__main__":
    app.run()
```

Use the task's actual inputs when implementing an analysis.

## Definition Forms

- Use `with app.setup:` for imports, project constants, and one-time setup that other definitions need. It cannot depend on names from other cells. Reuse existing path, data, and style helpers.
- Use `@app.function` for a reusable pure helper and `@app.class_definition` for a reusable class or dataclass. Prefer one helper or class per definition. They may use setup symbols and other top-level definitions, without capturing reactive cell variables.
- Use `@app.cell` for UI elements, reactive computation, previews, figures, and narrative. Give values consumed by later cells clear public names.
- Only extract a package when a real consumer needs the code shared. Keep notebook-specific presentation and orchestration in the notebook.

## Cell Scope and Output

A public name has exactly one owning cell, including imported names and names introduced by loops. Use function-local variables or a private `_name` for intermediates that should not enter the notebook graph; private cell names cannot be read from another cell. Avoid prefixing every variable or creating alias imports to evade duplicate-name errors.

Execution follows the dependency graph, not visual cell order. Return the names that downstream cells need and use separate names for successive transformations. Create new values across cells rather than mutating another cell's list, DataFrame, or configuration object in place.

The last top-level expression of a cell is its displayed output. For conditional output, assign a renderable object inside the branch and display that variable afterward. Show an explicit message for missing input or an empty selection. Let unexpected data errors reach the user.

## Controls and Script Execution

Create built-in controls in one cell and read their `.value` downstream. Keep display controls and cheap summaries downstream of reusable computation. Pass controls that change the experiment into the project's existing computation interface.

Use a form or run button when settings should apply together or when computation is costly. Choose the trigger deliberately so opening a notebook or exporting it has the intended behavior. Recompute dependent selector options when their inputs change and handle a selection becoming unavailable.

Run a notebook with `uv run --script notebook.py` when that execution is in scope. For a notebook that accepts command-line arguments, use `mo.cli_args()` in script mode and send those values through the same parameter validation used for the interactive controls.

## Validation

Use the installed Marimo CLI to check the notebook, for example `uvx marimo check notebook.py`. When a suitable project CLI is already available, it can perform the structural check; that does not verify the notebook's sandbox dependencies.

For an active notebook, validate through its actual kernel and inspect cell errors and outputs. Verify local package paths and imports in that environment.

Exercise controls and data cases that could materially change the result. Inspect chart rendering as well as the computed values. A display-only change should not rerun expensive computation unless its inputs changed.

Running a notebook, a test suite that executes its cells, or an export can launch its workload and side effects. Choose validation that fits the authorized cost and behavior. Keep the real input semantics; do not silently insert synthetic data or auto-submit a costly workflow just to make a script run pass. Add automated tests when they protect a concrete behavioral guarantee, rather than requiring a test cell in every notebook.

For an offline edit to a previously opened notebook, tell the user when reloading or reopening is required to bring those file changes into a kernel. For a fresh notebook, report that it is prepared and checked; do not claim it has been opened in the shared server unless verified.
