---
name: kimi-delegate
description: Delegate a bounded task to Kimi through its local Web API, reuse existing agent roles, and collect or follow up on the result. Use when the user explicitly requests Kimi or K3, or the current workflow already authorizes Kimi delegation. Review is a common use, not a restriction.
---

# Kimi delegation

Use `node scripts/kimi-client.mjs` with the resolved absolute script path. Requires Node.js 22+ and a running local Kimi Web server. Keep ordinary work with the calling agent; a generic review request alone does not select Kimi.

## Submit

1. Run `doctor` once for the selected server to check connectivity, authentication, and available model aliases. The default URL is `http://127.0.0.1:58627`; use `--url` for another known loopback port. The client does not start or reconfigure Kimi. If no service is available, report that prerequisite rather than repeatedly retrying.
2. Select an existing Kimi agent profile appropriate to the task. For review, reuse `correctness-reviewer`, `implementation-reviewer`, or `adversarial-reviewer` as appropriate. Do not copy their role instructions into the brief or create duplicate profiles. Other tasks may use other existing profiles or Kimi's default agent.
3. Write the task-specific brief: working scope or exact diff baseline, relevant context and constraints, accepted tradeoffs, and the question to resolve. Do not send unrelated conversation history. Choose a model from `doctor` only when requested or required; omitting `--model` uses Kimi's configured model (or the existing session's model).
4. Submit with an absolute `--cwd` for a new session. Save the returned `server`, `session_id`, and `prompt_id` in the calling task so another invocation can continue tracking it. Pass that exact `server` as `--url` on every follow-up, wait, result, and cancel command, along with the same authentication options. IDs alone do not identify a server.

```sh
node /absolute/path/to/kimi-delegate/scripts/kimi-client.mjs submit \
  --cwd /absolute/path/to/repo \
  --profile correctness-reviewer \
  --model kimi-code/k3-256k \
  --prompt-file /absolute/path/to/brief.txt
```

Use `--prompt-file -` with a quoted heredoc for a short brief. Avoid shell interpolation of task text. Reuse `submit --session SESSION_ID --prompt-file FILE` for follow-up; it preserves the profile and model unless explicitly overridden. Use a separate session for unrelated work. Every submit, including follow-ups, sets Kimi's `yolo` (Ask When Needed) permission mode: routine commands and edits run automatically, while built-in approval checks and user questions can still pause the task. This is not a read-only mode or a filesystem sandbox; keep the brief within the caller's authorized scope.

## Track and finish

```sh
node /absolute/path/to/kimi-delegate/scripts/kimi-client.mjs wait \
  --url SERVER_URL --session SESSION_ID --prompt-id PROMPT_ID --timeout 30
node /absolute/path/to/kimi-delegate/scripts/kimi-client.mjs result \
  --url SERVER_URL --session SESSION_ID --prompt-id PROMPT_ID
node /absolute/path/to/kimi-delegate/scripts/kimi-client.mjs cancel \
  --url SERVER_URL --session SESSION_ID --prompt-id PROMPT_ID
```

- `submit` acknowledges acceptance, not task completion. `wait` polls the durable transcript for the exact prompt, for at most 60 seconds per invocation. Re-run it when the task is still pending, communicating meaningful progress to the user. `result` gives a single snapshot, including assistant text from that turn only.
- `completed` means Kimi finished that turn. Inspect its text; completion is not proof that the requested work succeeded or that its findings are correct. Verify findings before acting on them.
- `needs_input` returns pending approvals or questions. Surface them to the user, or let the user resolve them in Kimi Web, then resume waiting. The client does not approve tools or answer questions automatically. `blocked` also requires inspection rather than blind polling.
- `failed` and `cancelled` are terminal. `unknown` means the prompt could not be found in the transcript or queue; do not infer success or resubmit automatically. Inspect the Kimi session if its history was changed, compacted, or steered elsewhere.
- A wait timeout or local interruption leaves the remote task running. The caller owns that task until it finishes or is explicitly cancelled. `cancel` returning `cancellation_requested` is only an acknowledgement; query `result` to confirm the terminal state. Never shut down the shared server as task cancellation.
- A submit error includes the task handle when known. On an uncertain POST outcome, retain the same session and prompt ID and inspect the result before retrying. Never blindly repeat session creation or generate another prompt ID. Duplicate IDs may return `40927` (in flight) or `40903` (completed), not the original successful response.

All commands emit one JSON result. Exit 0 means the command was accepted or the task completed; 2 means pending, timeout, needs input, cancellation requested, or unknown; 1 means failure, cancellation, or client error. Interpret `status` as well as the exit code.

## Connection

The client reads `$KIMI_CODE_HOME/server.token` or `~/.kimi-code/server.token`; `--token-file` selects another server token file. Never copy a token into the brief, command arguments, or logs. If the server is already deliberately running without authentication, pass `--no-auth`. Do not disable authentication or widen its network bind to make delegation work.

The adapter uses REST polling instead of a persistent WebSocket, so process restarts do not lose a stream cursor. It extracts all assistant text frames from the matching turn, excluding thinking and tool output. Unsupported or missing history is reported explicitly. See [API notes](references/api.md) for the protocol boundary and validation commands.
