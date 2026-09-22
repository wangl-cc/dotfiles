# Finding a Notebook on the Shared Server

`marimo.service` owns the shared server and its kernels in a dedicated container. The skill connects to `https://marimo.ws.loongw.cc` by default; use `MARIMO_URL` or `--url` for another deployment. Inside the workspace Pod, `--port 2718` connects directly to the same server. Host processes do not share Pod localhost and use HTTPS.

## Find an Active Session

```bash
bash scripts/discover-servers.sh
bash scripts/execute-code.sh --file ecDNA/notebooks/amplicon_cohorts.py -c "print('connected')"
```

Discovery reads the selected server's version and sessions through HTTP. It does not read a process registry, check local PIDs, scan ports, or delete stale entries. Containers share the network and home directory but have different PID namespaces, so a local PID check cannot establish the shared server's liveness.

Use the server's reported notebook path or a unique relative path suffix. A notebook browser URL containing `?file=` also selects that file. When multiple sessions match, choose an exact session ID with `--session`; do not execute against an arbitrary match. See [execution-context.md](execution-context.md) for the full command interface.

## Service and Session Lifecycle

If no session exists for the intended notebook, have the user open it in the shared notebook browser. A running server and an active notebook session are distinct: headless startup alone does not open every notebook.

If the server is unreachable, report the failed endpoint and check the managed service and Caddy route when host diagnostics are available. Do not start another server, install another marimo runtime, change port publications, or restart the shared service as an automatic pairing fallback. A `marimo.service` restart interrupts every notebook kernel. For a notebook-specific problem, use that notebook's kernel restart through the UI when authorized.

## Environment Selection

The managed server starts in directory `--sandbox` mode at `~/Documents`. Each active notebook session has its own kernel. With inline PEP 723 dependencies and no explicit venv selection, marimo and uv prepare the notebook environment from that metadata.

An inline `[tool.marimo.venv]` selects an existing environment instead of an automatic sandbox:

```python
# /// script
# [tool.marimo.venv]
# path = "../.venv"
# writable = false
# ///
```

The path is relative to the notebook's directory. In the inspected marimo 0.24 setup, project configuration is loaded from the server startup path; the shared server does not automatically load each notebook project's `pyproject.toml`. Do not infer environment selection from that project file alone.

`writable=false` does not fully prevent environment mutation: notebook package installation can still modify the selected venv, and automatic dependency recording can modify inline metadata. For project-owned dependencies, use the project's normal package and lockfile workflow under the user's authorization. Inspect the kernel's `sys.executable` and installed package paths when environment identity matters.

Native extensions require compatible system libraries in the marimo container. Moving a local editable package or import hook to a sandbox needs explicit dependency configuration and activation checks; the shared service does not migrate them automatically.
