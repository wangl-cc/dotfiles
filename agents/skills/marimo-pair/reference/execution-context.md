# Connection and Execution

Use this reference when the bundled scripts cannot reach the intended notebook, select a session, or complete an execution. Run the scripts from this skill's directory; they require Bash and Python 3.

## Targeting

Server selection is explicit `--url` or `--port`, then `MARIMO_URL`, then `https://marimo.ws.loongw.cc`. `--url` and `--port` are mutually exclusive.

- `--url URL` accepts a server base URL or a browser URL. A browser `?file=` is decoded into a notebook selector and removed from the API base URL.
- `--port PORT` connects to `http://127.0.0.1:PORT`. Use this only from a network namespace where that listener is reachable; the workspace Pod uses port 2718.
- `--file PATH` selects the notebook by exact server-side path or a unique relative path suffix. The path does not have to exist on the client filesystem.
- `--session ID` selects an exact active session ID. It is mutually exclusive with a file selector, including a browser URL's `?file=`.
- Without a session or file selector, exactly one active session must exist. Missing or ambiguous matches fail before execution.

Discover sessions without executing notebook code:

```bash
bash scripts/discover-servers.sh
bash scripts/discover-servers.sh --port 2718
```

Discovery queries only the selected endpoint and emits an array containing its `url`, `version`, and `sessions`. It does not search a registry or probe other ports.

## Authentication

The configured Tailscale endpoint uses no token. Do not look for tokens in logs, registry files, or retired token files. For an explicitly selected token-authenticated server, supply `MARIMO_TOKEN` or `--token`; the latter overrides the environment variable but exposes the value in process arguments. Both scripts support these options and send a bearer token to the selected server.

## Code Input and Quoting

`--file` names the target notebook. The positional argument names a local file containing code to execute. Alternatively, provide `-c` for a short one-liner or pass code through standard input. Choose one code source.

```bash
bash scripts/execute-code.sh --file ecDNA/notebooks/amplicon_cohorts.py -c "print(df.shape)"
```

Use a single-quoted heredoc for multiline code or shell-sensitive characters:

```bash
bash scripts/execute-code.sh --file ecDNA/notebooks/amplicon_cohorts.py <<'PY'
print(df.head())
PY
```

```bash
bash scripts/execute-code.sh --file ecDNA/notebooks/amplicon_cohorts.py /tmp/code.py
```

## Timeouts and Failure Handling

Connection and session listing use a 10-second timeout. Execution uses a 300-second socket timeout; raise `--timeout SECONDS` for calculations that may produce no output for longer. This is a network wait limit, not a kernel execution deadline or cancellation mechanism.

HTTP errors, invalid responses, non-event-stream execution responses, an execution error, or a stream ending without a completion event produce a nonzero exit status. The client does not automatically retry execution. A timeout or broken connection may occur after a notebook mutation has already run, and the kernel may continue running after the client exits. Inspect notebook state before deciding whether to retry.

## Common Problems

- **Server unreachable**: check the selected URL and managed service/Caddy status. Do not launch a duplicate server as a fallback.
- **No active or matching session**: open the intended notebook in the shared browser, then list sessions again.
- **Multiple matching sessions**: use an exact session ID; do not guess.
- **Authentication failure on another server**: verify the supplied token and endpoint without printing credentials.
- **SyntaxError**: inspect the submitted Python and use a quoted heredoc or code file.
- **ImportError**: inspect the active kernel's interpreter, package paths, and dependency ownership before installing anything. Notebook-managed sandboxes use `ctx.packages`; existing project venvs use the project workflow.

See [finding-marimo.md](finding-marimo.md) for service ownership and environment selection, and [../SKILL.md](../SKILL.md) for scratchpad and durable notebook changes.
