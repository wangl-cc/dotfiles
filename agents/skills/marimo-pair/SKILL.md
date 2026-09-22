---
name: marimo-pair
description: >-
  Drive a live marimo notebook as a workspace: run Python in the same kernel
  the user does, inspect live notebook state, and commit durable notebook
  changes. Use when the user wants to start a marimo notebook or pair on an
  active marimo session.
allowed-tools: Bash(bash **/scripts/discover-servers.sh *), Bash(bash **/scripts/execute-code.sh *), Read
---

marimo is a reactive Python runtime for building reproducible Python programs (marimo notebooks). Cells are connected by the variables they define and reference. Running a cell re-executes dependents in dataflow order. The active runtime holds the kernel namespace, cell state, and dataflow graph. The notebook (`.py` file) is the artifact the kernel writes from that state while a session is running.

A user interacts with the same runtime via a notebook UI with cells, outputs, and widgets.

**WARNING. The active runtime is the source of truth.** During a session, you SHOULD NOT modify the associated `.py` file directly. File edits WILL NOT reach the active kernel or user, and the kernel may overwrite them on save. Use `marimo._code_mode` (`cm`) for notebook changes. Reading disk is fine, but prefer `ctx.cells[...].code` for current cell code.

## Connect to a Notebook

Use the bundled scripts from this skill's directory. They require Bash and Python 3, and connect to the managed shared server at `https://marimo.ws.loongw.cc` by default. `MARIMO_URL` overrides the default; `--url` or `--port` selects an explicit server. The configured Tailscale endpoint uses no token.

First list the server's active sessions:

```bash
bash scripts/discover-servers.sh
```

Select the intended notebook by its server-side path. A relative path must uniquely match an active session; use the full path when names overlap:

```bash
bash scripts/execute-code.sh --file ecDNA/notebooks/amplicon_cohorts.py -c "print('connected')"
```

A browser URL also selects its `?file=` notebook:

```bash
bash scripts/execute-code.sh --url 'https://marimo.ws.loongw.cc/?file=ecDNA%2Fnotebooks%2Famplicon_cohorts.py' -c "print('connected')"
```

Use `--session` instead of a file selector when selecting an exact session ID. If no selector is supplied, execution requires exactly one active session. Do not guess between sessions.

Use `-c` only for short one-liners. For multiline code or shell-sensitive characters, use a single-quoted heredoc:

```bash
bash scripts/execute-code.sh --file ecDNA/notebooks/amplicon_cohorts.py <<'PY'
import marimo._code_mode as cm

async with cm.get_context() as ctx:
    for cell in ctx.cells:
        print(cell.id, cell.code)
PY
```

When code already lives in a file, pass its path as the positional argument; `--file` always means the target notebook:

```bash
bash scripts/execute-code.sh --file ecDNA/notebooks/amplicon_cohorts.py /tmp/code.py
```

The scripts query HTTP APIs only. They do not scan ports, inspect or delete registry entries, or read tokens from logs. Inside the workspace Pod, `--port 2718` selects `http://127.0.0.1:2718`; host processes use HTTPS.

`marimo.service` owns the server. If the notebook has no active session, have the user open it in the shared notebook browser. Do not launch a per-project server or restart the shared service to make a session appear. A transport error may occur after code has run: inspect the notebook before retrying a mutation. See [finding-marimo.md](reference/finding-marimo.md) for lifecycle and environment selection, and [execution-context.md](reference/execution-context.md) for targeting, authentication, and failures.

## Scratchpad Scope

`execute-code` evaluates Python in marimo's scratchpad: a temporary namespace with a shallow copy of the kernel globals. Notebook variables are available by name, but new top-level bindings and rebindings are discarded after each call. In-place mutations to notebook-owned objects can persist because those names still reference live objects.

Each call reports stdout and stderr from the scratchpad, plus console output from notebook cells it causes to run, including reactive descendants.

### Ordinary Python

Use ordinary Python in the scratchpad to inspect variables, sample data, test transformations, probe APIs, check imports, and read widget state.

```python
print(df.head())

x = 10
print(x)
```

Here `df` comes from notebook globals, while `x` is a scratchpad-local binding. `x` exists for this call only and WILL NOT be added to notebook globals.

### Persist with `cm`

Top-level scratchpad assignments and rebindings are temporary. To persist work, including new variables, you MUST submit changes through `marimo._code_mode` (`cm`).

`marimo._code_mode` is a PRIVATE, UNSTABLE agent API (note the leading underscore). It exists for tools like this skill to drive a live kernel from the scratchpad. DO NOT import it from notebook cells, library code, or anything a user would run — methods can change or disappear across marimo versions and kernels. Treat every `import marimo._code_mode as cm` as scratchpad-only.

At session start, inspect what `cm` exposes in the active kernel:

```python
import marimo._code_mode as cm

help(cm)
```

Open a code-mode context to queue notebook changes.

```python
import marimo._code_mode as cm

async with cm.get_context() as ctx:
    cid = ctx.create_cell("x = df.head()")
    ctx.run_cell(cid)
```

The scratchpad supports top-level async code. Use `async with` directly; wrapping it in `asyncio.run(...)` is unnecessary and can conflict with the kernel's event loop.

After this block exits and the new cell runs, `x` is notebook state. Later scratchpad calls can read `x` by name. Code later in the same scratchpad call should read `ctx.globals["x"]`, because the scratchpad namespace was copied before the cell ran.

Inside the context, queued mutation methods are synchronous. Call them directly; do not `await` them. Each call queues an operation for marimo to apply when the context exits normally. If the block raises, the queue is discarded.

On clean exit, marimo applies packages, validates and applies structural cell changes, runs queued cells, then may run dependents. Validation is only structural since queued cell runs can still error. `create_cell` and `edit_cell` change notebook structure only. Use `run_cell` to execute.

`create_cell` currently defaults to `hide_code=True`, which collapses the code editor in the UI. Pass `hide_code=False` if the user wants created cells to be visible without manually expanding them.

## Marimo Rules

marimo imposes a small contract on notebook code so it can keep the notebook as a directed acyclic graph (DAG):

- **No cycles** - cells cannot depend on each other in a cycle.
- **No public redefinitions across cells** - each name has one owning cell.
- **No wildcard imports** - `import *` prevents static analysis of definitions.

These rules keep the kernel, UI, and saved artifact consistent.

When `cm` submits a cell body, marimo parses its top-level definitions and references. A top-level name enters the graph unless it is private with a leading underscore.

```python
# Public definitions: values, total, i, value, mean
values = np.array([1, 2, 3])
total = 0
for i, value in enumerate(values):
    total += value
mean = total / len(values)
mean
```

```python
# Public definition: mean
_values = np.array([1, 2, 3])
_total = 0
for _i, _value in enumerate(_values):
    _total += _value
mean = _total / len(_values)
mean
```

Use private names for intermediates that no other cell should read. Public names define the notebook-level dataflow. If a `cm` edit violates the contract, marimo rejects the structural change and returns the validation error.

## The Notebook's Shape

A notebook is an ordered collection of cells. `ctx.cells` is the document view and `ctx.graph` is the dataflow view.

```python
for cell in ctx.cells:
    cell  # .id, .code, .name, .config, .status, .errors

ctx.cells["setup"]         # by name
ctx.cells[0]               # by position
list(ctx.cells.keys())     # all IDs, in notebook order
```

Cell IDs are opaque strings which can be queried from the notebook or captured from `cm` return values:

```python
cid = ctx.create_cell("df = pd.read_csv('data.csv')")
print(cid)   # e.g. 'Hbol'
```

Alternatively, cells can be assigned and referenced by `name`. The graph can be used to understand its role in the dataflow.

```python
for cid, impl in ctx.graph.cells.items():
    impl  # .defs, .refs   (sets of public names)

ctx.graph.descendants(cid)   # cells that re-run when this one changes
ctx.graph.ancestors(cid)     # cells this one depends on
```

In marimo, deletes are *destructive* so it can be useful to query the descendants prior to deleting to understand it's impact.

## Writing Notebook Changes

The graph contract keeps marimo able to run and save the notebook. Passing those checks alone does not guarantee a useful artifact. Committed cells should still be readable, rerunnable, and editable.

Make durable edits that reuse the notebook's existing names, imports, dependencies, and UI model. Don't be lazy. Avoid one-off workarounds that pass `cm` validation but leave a brittle notebook.

### Cell Bodies

Submit the code that belongs in the cell.

- **Submit cell contents** - `create_cell` and `edit_cell` take cell contents, not saved-file `@app.cell` wrappers.
- **Read before replacing** - for now, another editor may change a cell between scratchpad calls. Before `edit_cell`, read the current body from `ctx.cells[...]` and submit the full replacement.
- **Reuse notebook imports** - if `np` already exists, use it or edit the owning import cell. DO NOT add `import numpy as _np` just to bypass the graph.
- **Define public names intentionally** - use public names for values later cells should reference. Use private `_name` bindings or function locals for same-cell intermediates.
- **Define each public name once** - a public name has one owning cell. Reassigning it in another cell fails with `Multiply-defined names`; edit the owning cell or give the result a new name. See [gotchas.md](reference/gotchas.md).
- **Run cells deliberately** - `create_cell` and `edit_cell` change structure only. Queue `ctx.run_cell(...)` when the cell should execute.

### Prefer `cm`-Managed Changes

Use `cm` APIs for notebook structure and UI. Choose package operations according to the environment ownership described below, and avoid scratchpad-only state for changes that should persist.

- **Do not edit the `.py` artifact** - DO NOT use `Edit`, `Write`, or `NotebookEdit` on the notebook file during a live session. Use `ctx.edit_cell(...)` even for small changes.
- **Respect dependency ownership** - use `ctx.packages.add()` or `ctx.packages.remove()` for notebook-managed sandboxes. For an existing project `.venv`, manage dependencies through the project workflow rather than notebook package APIs.
- **Avoid transient paths** - persisted cells should not depend on `/tmp/...` unless the work is intentionally transient.
- **Delete deliberately** - deleting a cell removes globals it defines. Reuse empty cells when convenient and delete cells left empty after edits.

### Package and Environment Ownership

Before changing dependencies, inspect the notebook's inline metadata, relevant project configuration, and the active kernel's `sys.executable` and package locations. A shared server does not imply shared kernels, and a notebook's `dependencies` header does not prove it runs in a separate sandbox.

- **Notebook-managed sandbox**: inline PEP 723 dependencies describe the notebook environment. Use `ctx.packages` for authorized package changes.
- **Existing project `.venv`**: `[tool.marimo.venv]` selects that environment instead of an automatic sandbox. Follow the project's dependency workflow; for an authorized uv-managed project change, run `uv add` from the project directory and synchronize through its normal workflow. Keep `pyproject.toml` and `uv.lock` consistent with the intended environment. Do not run `uv sync` merely to investigate an installation, since it may remove undeclared packages.

In the inspected marimo 0.24 behavior, `writable=false` is not a complete read-only guarantee. UI or missing-package installation can still modify the selected `.venv`, while automatic dependency recording can write notebook metadata without updating the project's dependency files. Do not use this flag as permission to install packages. Seeing `uv add` alone does not establish that project metadata was updated: `uv add --script notebook.py` writes the notebook's inline dependencies.

Local editable packages, native extensions, and import hooks need their own sandbox configuration and runtime verification. Do not assume a sandbox inherits project `.venv` packages or startup hooks, or that moving a notebook to sandbox mode has already been completed.

### UI and Widgets

Inspect the object before changing it. Different UI objects update through different paths.

- **Set `mo.ui.*` through `cm`** - use `ctx.set_ui_value(element, value)` inside `cm.get_context()`.
- **Set anywidget traitlets directly** - synced traitlets are Python attributes, for example `widget.value = 5`.

For designing custom visual or interactive output, see [rich-representations.md](reference/rich-representations.md).

## References

- [execution-context.md](reference/execution-context.md) — script targeting, auth, failures, and shell quoting
- [finding-marimo.md](reference/finding-marimo.md) — shared service lifecycle and environment selection
- [gotchas.md](reference/gotchas.md) — name redefinition, cached module proxies, and notebook traps
- [rich-representations.md](reference/rich-representations.md) — custom widgets and visualizations
- [notebook-improvements.md](reference/notebook-improvements.md) — improving existing notebooks
