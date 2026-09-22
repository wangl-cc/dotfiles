#!/usr/bin/env node
// Kimi Web adapter. No model SDK, server lifecycle, or credential mutation.
import { readFile } from 'node:fs/promises';
import { realpathSync } from 'node:fs';
import { homedir } from 'node:os';
import { isAbsolute, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { parseArgs } from 'node:util';
import { randomUUID } from 'node:crypto';
import { setTimeout as sleep } from 'node:timers/promises';

export class ClientError extends Error {
  constructor(message, details = {}) {
    super(message);
    Object.assign(this, details);
  }
}

function check(condition, message) {
  if (!condition) throw new ClientError(message);
}

function segment(value) {
  check(typeof value === 'string' && /^[a-zA-Z0-9_.-]+$/.test(value), 'Invalid session or prompt ID');
  check(value !== '.' && value !== '..', 'Invalid session or prompt ID');
  return value;
}

export class KimiClient {
  constructor({ url = 'http://127.0.0.1:58627', token, requestTimeoutMs = 10000 } = {}) {
    const endpoint = new URL(url);
    check(endpoint.protocol === 'http:' && ['127.0.0.1', '[::1]'].includes(endpoint.hostname),
      'Use a numeric loopback HTTP address for the local Kimi Web service');
    check(!endpoint.username && !endpoint.password && !endpoint.search && !endpoint.hash && endpoint.pathname === '/',
      'Server URL must be an origin without credentials, path, query, or fragment');
    this.url = endpoint.origin;
    this.token = token;
    this.requestTimeoutMs = requestTimeoutMs;
  }

  async request(method, path, body, signal) {
    let response;
    let envelope;
    try {
      response = await fetch(`${this.url}/api/v1${path}`, {
        method,
        redirect: 'manual',
        headers: {
          ...(this.token ? { Authorization: `Bearer ${this.token}` } : {}),
          ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.any([AbortSignal.timeout(this.requestTimeoutMs), ...(signal ? [signal] : [])]),
      });
      if (response.status >= 300 && response.status < 400) throw new Error('redirect refused');
      envelope = await response.json();
    } catch {
      throw new ClientError(`Kimi ${method} request failed, timed out, or returned an invalid response`, {
        outcome: method === 'GET' ? undefined : 'unknown',
      });
    }
    if (!Number.isInteger(envelope?.code)) {
      throw new ClientError('Invalid Kimi response envelope', { outcome: method === 'GET' ? undefined : 'unknown' });
    }
    if (!response.ok || envelope.code !== 0) {
      const message = String(envelope.msg ?? 'Kimi request failed');
      throw new ClientError(this.token ? message.replaceAll(this.token, '[redacted]') : message, {
        code: envelope.code, http_status: response.status,
      });
    }
    return envelope.data;
  }

  async doctor() {
    const meta = await this.request('GET', '/meta');
    const models = await this.request('GET', '/models');
    check(typeof meta?.server_version === 'string' && Array.isArray(models?.items), 'Unsupported metadata/model response');
    return {
      server: this.url,
      server_version: meta.server_version,
      authentication: meta.dangerous_bypass_auth ? 'disabled' : 'bearer',
      models: models.items.map(item => item.model),
    };
  }

  async submit({ session, cwd, title, prompt, promptId = randomUUID(), profile, model, thinking }) {
    check(typeof prompt === 'string' && prompt.trim().length > 0, 'Prompt must not be empty');
    segment(promptId);
    check(Boolean(session) !== Boolean(cwd), 'Supply exactly one of --cwd or --session');
    if (session) segment(session);
    if (cwd) check(isAbsolute(cwd), '--cwd must be an absolute directory');
    const handle = { server: this.url, session_id: session, prompt_id: promptId };
    try {
      if (!session) {
        const created = await this.request('POST', '/sessions', {
          ...(title ? { title } : {}), metadata: { cwd },
        });
        check(typeof created?.id === 'string', 'Session creation returned no ID; do not blindly retry');
        session = segment(created.id);
        handle.session_id = session;
      }
      const accepted = await this.request('POST', `/sessions/${session}/prompts`, {
        prompt_id: promptId,
        content: [{ type: 'text', text: prompt }],
        ...(profile ? { profile } : {}),
        ...(model ? { model } : {}),
        ...(thinking ? { thinking } : {}),
        permission_mode: 'yolo',
      });
      check(accepted?.prompt_id === promptId && ['running', 'queued', 'blocked'].includes(accepted.status),
        'Unexpected prompt acknowledgement; query the returned handle before retrying');
      return { ...handle, status: accepted.status };
    } catch (error) {
      error.handle = handle;
      throw error;
    }
  }

  async result(session, promptId, signal) {
    segment(session);
    segment(promptId);
    const handle = { server: this.url, session_id: session, prompt_id: promptId };
    let before;
    const cursors = new Set();
    // Scan the durable transcript, never infer completion from session-wide busy=false.
    for (let page = 0; page < 100; page++) {
      const query = new URLSearchParams({ agent_id: 'main', page_size: '100' });
      if (before) query.set('before_turn', before);
      const transcript = await this.request('GET', `/sessions/${session}/transcript?${query}`, undefined, signal);
      check(Array.isArray(transcript?.items) && typeof transcript.has_more === 'boolean', 'Unsupported transcript response');
      const turns = transcript.items.filter(item => item.kind === 'turn');
      const turn = turns.find(item => item.triggerPromptId === promptId);
      if (turn) {
        check(['queued', 'running', 'completed', 'failed', 'cancelled'].includes(turn.state)
          && typeof turn.turnId === 'string' && Array.isArray(turn.steps), 'Unsupported turn response');
        const text = [...turn.steps].sort((a, b) => a.ordinal - b.ordinal)
          .flatMap(step => {
            check(Array.isArray(step.frames), 'Unsupported transcript frames');
            return step.frames.filter(frame => frame.kind === 'text' && frame.role === 'assistant')
              .map(frame => {
                check(typeof frame.text === 'string', 'Unsupported assistant text frame');
                return frame.text;
              });
          }).join('\n\n');
        const result = { ...handle, turn_id: turn.turnId, status: turn.state, text, ...(turn.error ? { error: turn.error } : {}) };
        if (['completed', 'failed', 'cancelled'].includes(turn.state)) return result;
        return this.withInteractions(result, signal);
      }
      if (!transcript.has_more) break;
      check(turns.length > 0 && turns.every(turn => Number.isFinite(turn.ordinal)), 'Cannot paginate transcript');
      before = turns.reduce((oldest, turn) => turn.ordinal < oldest.ordinal ? turn : oldest).turnId;
      check(typeof before === 'string' && !cursors.has(before), 'Transcript cursor did not advance');
      cursors.add(before);
      check(page < 99, 'Transcript search limit reached; inspect the session in Kimi Web');
    }
    const queue = await this.request('GET', `/sessions/${session}/prompts`, undefined, signal);
    check(Array.isArray(queue?.queued), 'Unsupported prompt queue response');
    const prompt = [queue.active, ...queue.queued].find(item => item?.prompt_id === promptId);
    if (prompt) {
      check(['running', 'queued', 'blocked'].includes(prompt.status), 'Unsupported prompt state');
      return this.withInteractions({ ...handle, status: prompt.status }, signal);
    }
    return { ...handle, status: 'unknown', message: 'No matching transcript turn or queued prompt; absence does not prove completion or cancellation.' };
  }

  async withInteractions(result, signal) {
    const session = await this.request('GET', `/sessions/${result.session_id}`, undefined, signal);
    const kind = session?.pending_interaction;
    if (!['approval', 'question'].includes(kind)) return result;
    // Kimi 0.42.0 omits current_prompt_id from the session response.
    // Only attribute pending input to the active prompt, never a queued task.
    const queue = await this.request('GET', `/sessions/${result.session_id}/prompts`, undefined, signal);
    check(Array.isArray(queue?.queued), 'Unsupported prompt queue response');
    if (queue.active?.prompt_id !== result.prompt_id) return result;
    const pending = await this.request('GET', `/sessions/${result.session_id}/${kind}s?status=pending`, undefined, signal);
    check(Array.isArray(pending?.items), 'Unsupported pending interaction response');
    return pending.items.length ? { ...result, status: 'needs_input', interaction: kind, pending: pending.items } : result;
  }

  async wait(session, promptId, { timeoutMs = 30000, pollMs = 2000 } = {}) {
    check(Number.isFinite(timeoutMs) && timeoutMs > 0 && timeoutMs <= 60000, 'Wait timeout must be between 1 and 60000 ms');
    const signal = AbortSignal.timeout(timeoutMs);
    let last;
    try {
      while (true) {
        last = await this.result(session, promptId, signal);
        if (!['queued', 'running'].includes(last.status)) return last;
        await sleep(pollMs, undefined, { signal });
      }
    } catch (error) {
      if (!signal.aborted) throw error;
      return {
        server: this.url, session_id: session, prompt_id: promptId,
        status: 'timeout', last_status: last?.status,
        message: 'Stopped waiting; the Kimi task was not cancelled. Reuse this handle to wait or cancel.',
      };
    }
  }

  async cancel(session, promptId) {
    segment(session);
    segment(promptId);
    const handle = { server: this.url, session_id: session, prompt_id: promptId };
    try {
      await this.request('POST', `/sessions/${session}/prompts/${promptId}:abort`, {});
      return { ...handle, status: 'cancellation_requested', message: 'Abort acknowledged. Query result to confirm the terminal state.' };
    } catch (error) {
      if (error.code === 40903) return this.result(session, promptId);
      error.handle = handle;
      throw error;
    }
  }
}

const help = `Kimi Web delegation client (Node.js 22+; local server required)

  doctor
  submit --cwd /absolute/path | --session ID
         --prompt-file FILE|- [--profile ROLE] [--model ALIAS] [--thinking LEVEL]
         [--title TITLE] [--prompt-id ID]
  wait   --session ID --prompt-id ID [--timeout SECONDS (default 30, max 60)]
  result --session ID --prompt-id ID
  cancel --session ID --prompt-id ID

All commands: --url http://127.0.0.1:58627 [--token-file FILE | --no-auth]
Default token: $KIMI_CODE_HOME/server.token or ~/.kimi-code/server.token.
One JSON result on stdout. Exit 0: accepted/completed; 2: pending, needs input,
timeout, cancellation requested, or unknown; 1: failure/cancelled/client error.
No automatic POST retries, approval decisions, server startup, or shutdown.
`;

export async function main(argv = process.argv.slice(2)) {
  const { values, positionals } = parseArgs({
    args: argv, allowPositionals: true,
    options: Object.fromEntries([
      ...['url', 'token-file', 'cwd', 'session', 'prompt-file', 'profile', 'model', 'thinking', 'title', 'prompt-id', 'timeout']
        .map(name => [name, { type: 'string' }]),
      ['no-auth', { type: 'boolean' }], ['help', { type: 'boolean', short: 'h' }],
    ]),
  });
  if (values.help) { process.stdout.write(help); return 0; }
  const command = positionals[0];
  check(positionals.length === 1 && ['doctor', 'submit', 'wait', 'result', 'cancel'].includes(command), help);
  const allowed = new Set(['url', 'token-file', 'no-auth', ...({
    doctor: [], submit: ['cwd', 'session', 'prompt-file', 'profile', 'model', 'thinking', 'title', 'prompt-id'],
    wait: ['session', 'prompt-id', 'timeout'], result: ['session', 'prompt-id'], cancel: ['session', 'prompt-id'],
  }[command])]);
  for (const key of Object.keys(values)) check(allowed.has(key), `--${key} is not valid for ${command}`);
  check(!(values['no-auth'] && values['token-file']), '--no-auth and --token-file are mutually exclusive');
  let token;
  if (!values['no-auth']) {
    const tokenPath = values['token-file'] ?? join(process.env.KIMI_CODE_HOME || join(homedir(), '.kimi-code'), 'server.token');
    token = (await readFile(tokenPath, 'utf8')).trim();
    check(token.length > 0, 'Server token file is empty');
  }
  const client = new KimiClient({ url: values.url, token });
  let result;
  if (command === 'doctor') result = await client.doctor();
  else if (command === 'submit') {
    check(Boolean(values['prompt-file']), '--prompt-file FILE or - is required');
    let prompt;
    if (values['prompt-file'] === '-') {
      process.stdin.setEncoding('utf8');
      prompt = '';
      for await (const chunk of process.stdin) prompt += chunk;
    } else prompt = await readFile(values['prompt-file'], 'utf8');
    result = await client.submit({
      session: values.session, cwd: values.cwd, title: values.title,
      prompt, promptId: values['prompt-id'], profile: values.profile, model: values.model, thinking: values.thinking,
    });
  } else {
    segment(values.session);
    segment(values['prompt-id']);
    result = command === 'wait'
      ? await client.wait(values.session, values['prompt-id'], { timeoutMs: Number(values.timeout ?? '30') * 1000 })
      : await client[command](values.session, values['prompt-id']);
  }
  process.stdout.write(`${JSON.stringify(result)}\n`);
  if (['failed', 'cancelled'].includes(result.status)) return 1;
  if (command !== 'submit' && result.status && result.status !== 'completed') return 2;
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href) {
  main().then(code => { process.exitCode = code; }).catch(error => {
    process.stdout.write(`${JSON.stringify({
      status: 'error', message: error.message, code: error.code,
      outcome: error.outcome, handle: error.handle,
    })}\n`);
    process.exitCode = 1;
  });
}
