# Live Notebook Sessions

Read and edit an active notebook through its kernel. Use [notebook authoring](notebook-authoring.md) for files without an active session.

## Find and Target a Session

Run the bundled scripts with Bash and Python 3 from the skill directory. From a workspace container they connect to the shared server at `http://marimo:2718` by default. Open notebooks through the shared browser. If the intended notebook is missing from discovery, open it in the browser and list sessions again. Restarting `marimo.service` stops every notebook kernel.

```bash
bash scripts/discover-servers.sh
bash scripts/execute-code.sh --file project/notebooks/analysis.py -c "print('connected')"
```

- `--file` selects an exact server-side notebook path or unique relative suffix. A browser URL passed to `--url` can also select the notebook through `?file=`.
- `--session` selects an exact session ID and is mutually exclusive with file selection. Without either selector, execution requires exactly one active session.
- Set `MARIMO_URL` for a different server. `--url` and `--port` override it and are mutually exclusive. Use `--port` for an endpoint on the calling container's loopback or a local forward.
- The shared internal endpoint uses no token. For a token-authenticated server, pass credentials through `MARIMO_TOKEN` to keep them out of command arguments and URLs.

Use a quoted heredoc for multiline code. A positional argument can also supply the path of a local file containing the code to execute.

```bash
bash scripts/execute-code.sh --file project/notebooks/analysis.py <<'PYCODE'
import marimo._code_mode as cm

async with cm.get_context() as ctx:
    for cell in ctx.cells:
        print(cell.id, cell.name, cell.code)
PYCODE
```

## Diagnose Execution Failures

- If discovery fails, check the selected URL, workspace network, and managed service before retrying. Discovery queries the selected server's API without executing notebook code.
- Resolve an ambiguous match with an exact session ID. Recheck the endpoint and `MARIMO_TOKEN` for authentication failures without displaying the token.
- Execution has a 300-second default socket timeout. Use `--timeout SECONDS` for a longer wait. A timeout or broken stream can occur after code has started, and the kernel can keep running. Inspect session state before retrying a mutation.
- For import failures, verify the active kernel's interpreter and package paths using the [dependency guide](dependencies.md).

## Inspect and Edit the Live Notebook

Scratchpad Python sees a shallow copy of the kernel globals. New bindings and rebindings disappear after the call. In-place changes to shared objects can persist. Use ordinary Python in the scratchpad to inspect values, test expressions, or check imports. Use code mode for durable edits.

`marimo._code_mode` is a private API. Keep it in the scratchpad and inspect `help(cm)` or the active context when an API differs. The scratchpad supports top-level `async with`.

```python
import marimo._code_mode as cm

async with cm.get_context() as ctx:
    cid = ctx.create_cell("preview = df.head()")
    ctx.run_cell(cid)
```

- Read the current cell body with `ctx.cells[...].code` before replacing it. `ctx.cells` exposes notebook order, names, IDs, and cell errors. `ctx.graph` exposes definitions, references, and descendants. Check descendants before deleting a cell.
- Pass cell bodies to `create_cell` and `edit_cell`. Follow the [cell scope rules](notebook-authoring.md#cell-scope-and-output) and reuse the notebook's imports and dependencies.
- Mutation methods queue operations synchronously inside the context. A successful exit applies queued package and structural changes, then runs requested cells. A structural edit needs `ctx.run_cell(...)` when execution is required. Inspect cell errors and affected downstream outputs afterward.
- Use `ctx.globals["preview"]` to inspect a new notebook binding later in the same scratchpad call. A later call can read it by name.
- Use `ctx.set_ui_value(element, value)` for built-in Marimo controls. Manage packages according to the [dependency guide](dependencies.md).
