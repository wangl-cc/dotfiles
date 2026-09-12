# Kimi Web adapter

The [official Server API reference](https://moonshotai.github.io/kimi-code/en/reference/server-api.html) documents the experimental REST and WebSocket protocols. The running server's authenticated `/openapi.json` and `/asyncapi.json` are authoritative for its version. This adapter targets the transcript and prompt surfaces observed in Kimi Code 0.40.1; do not assume an accepted schema field changes runtime behavior.

| Operation | REST route under `/api/v1` |
| --- | --- |
| Check instance and model aliases | `GET /meta`, `GET /models` |
| Create a session | `POST /sessions` with `metadata.cwd` |
| Submit or follow up | `POST /sessions/{id}/prompts` with `prompt_id`, `content`, optional `profile`, `model`, `thinking`, and `permission_mode` |
| Find the exact prompt's turn | `GET /sessions/{id}/transcript?agent_id=main&page_size=100`, following `before_turn` |
| Inspect queued input | `GET /sessions/{id}/prompts` |
| Inspect pending input for the active prompt | `GET /sessions/{id}`, then `/approvals?status=pending` or `/questions?status=pending` |
| Request cancellation | `POST /sessions/{id}/prompts/{prompt_id}:abort` |

JSON responses use `{code, msg, data, request_id}`. HTTP 200 alone is not success. Mutation requests are never retried automatically, and redirects are refused so a server token cannot follow a redirect. Connections are restricted to numeric loopback origins. Each HTTP operation has a 10-second timeout; a wait additionally has its own deadline, which does not cancel the server task.

The task handle is the server origin, session ID, and client-chosen prompt ID. A transcript turn is matched by `triggerPromptId`; its `turnId` is returned with the result. Pagination searches up to 100 pages and rejects non-advancing cursors. Missing turns are checked against the prompt queue, then reported as unknown. In particular, `busy=false`, an empty queue, and another turn's completion never establish that the target task succeeded.

The caller retains the handle across command invocations. The client writes no task registry, credentials, or configuration and leaves session history in Kimi for follow-up. It does not manage server lifetime, create remote connections, or forward arbitrary management endpoints. Review-specific prompts and finding validation belong to the calling agent and existing Kimi profiles.

Run validation from the chezmoi repository:

```sh
node --test agents/skills/kimi-delegate/tests/client.test.mjs
node --check agents/skills/kimi-delegate/scripts/kimi-client.mjs
pnx markdownlint-cli2 'agents/skills/kimi-delegate/**/*.md'
```

For live validation, use `doctor`, submit a bounded task through an existing profile, wait for its exact result, follow up in the same session, and verify cancellation separately. Keep model failures distinct from transport/client failures. Do not treat a mock server test as live model validation.
