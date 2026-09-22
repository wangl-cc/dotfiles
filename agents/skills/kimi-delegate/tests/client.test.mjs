import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { execFileSync } from 'node:child_process';
import { KimiClient } from '../scripts/kimi-client.mjs';

async function server(t, handler, options = {}) {
  const requests = [];
  const http = createServer(async (req, res) => {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    const text = Buffer.concat(chunks).toString();
    const request = { method: req.method, url: req.url, headers: req.headers, body: text ? JSON.parse(text) : undefined };
    requests.push(request);
    try {
      const result = await handler(request, res);
      if (!res.writableEnded && result !== undefined) {
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ code: 0, data: result }));
      }
    } catch (error) {
      res.statusCode = 500;
      res.end(JSON.stringify({ code: 50001, msg: error.message }));
    }
  });
  await new Promise(resolve => http.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => { http.closeAllConnections(); http.close(resolve); }));
  return { client: new KimiClient({ url: `http://127.0.0.1:${http.address().port}`, ...options }), requests };
}

const turn = (id, state = 'completed', ordinal = 1) => ({
  kind: 'turn', turnId: `turn-${ordinal}`, triggerPromptId: id, ordinal, state,
  steps: [{ ordinal: 1, frames: [
    { kind: 'thinking', text: 'private reasoning' },
    { kind: 'text', role: 'user', text: 'user prompt' },
    { kind: 'tool', output: 'tool output' },
    { kind: 'text', role: 'assistant', text: `answer for ${id}` },
  ] }],
});

test('HTTP 200 business error remains a failure and redacts the server token', async t => {
  const { client } = await server(t, (_req, res) => {
    res.end(JSON.stringify({ code: 40101, msg: 'bad secret-token' }));
  }, { token: 'secret-token' });
  await assert.rejects(client.doctor(), error => error.code === 40101 && !error.message.includes('secret-token'));
});

test('loopback only; reject URL credentials and redirects without sending token onward', async t => {
  for (const url of ['http://example.com', 'https://127.0.0.1', 'http://u:p@127.0.0.1', 'http://127.0.0.1/path']) {
    assert.throws(() => new KimiClient({ url }));
  }
  let received = false;
  const destination = await server(t, () => { received = true; return {}; });
  const { client } = await server(t, (_req, res) => {
    res.writeHead(302, { Location: `${destination.client.url}/api/v1/meta` }); res.end();
  }, { token: 'secret-token' });
  await assert.rejects(client.doctor());
  assert.equal(received, false);
});

test('submit forwards a caller brief and existing profile; no auth header when omitted', async t => {
  const { client, requests } = await server(t, req => req.url === '/api/v1/sessions'
    ? { id: 'session-1' } : { prompt_id: req.body.prompt_id, status: 'queued' });
  const result = await client.submit({ cwd: '/tmp/repo', prompt: 'specific brief', promptId: 'p1', profile: 'reviewer', model: 'k3' });
  assert.equal(result.session_id, 'session-1');
  assert.equal(requests[0].headers.authorization, undefined);
  assert.deepEqual(requests[0].body, { metadata: { cwd: '/tmp/repo' } });
  assert.deepEqual(requests[1].body, {
    prompt_id: 'p1', content: [{ type: 'text', text: 'specific brief' }],
    profile: 'reviewer', model: 'k3', permission_mode: 'yolo',
  });
});

test('follow-up reuses session without resetting its profile or model', async t => {
  const { client, requests } = await server(t, req => ({ prompt_id: req.body.prompt_id, status: 'running' }));
  await client.submit({ session: 'session-1', prompt: 'follow up', promptId: 'p2' });
  assert.equal(requests.length, 1);
  assert.equal(requests[0].url, '/api/v1/sessions/session-1/prompts');
  assert.equal(requests[0].body.profile, undefined);
  assert.equal(requests[0].body.model, undefined);
  assert.equal(requests[0].body.permission_mode, 'yolo');
});

test('ambiguous prompt submission preserves handle and never retries POST', async t => {
  const { client, requests } = await server(t, req => {
    if (req.url === '/api/v1/sessions') return { id: 'session-1' };
  }, { requestTimeoutMs: 30 });
  await assert.rejects(client.submit({ cwd: '/tmp', prompt: 'brief', promptId: 'p1' }), error => {
    assert.equal(error.outcome, 'unknown');
    assert.equal(error.handle.session_id, 'session-1');
    assert.equal(error.handle.prompt_id, 'p1');
    return true;
  });
  assert.equal(requests.length, 2);
});

test('duplicate prompt rejection retains ID and is not disguised as success', async t => {
  const { client, requests } = await server(t, (_req, res) => res.end(JSON.stringify({ code: 40927, msg: 'duplicate' })));
  await assert.rejects(client.submit({ session: 's', prompt: 'brief', promptId: 'p' }), error => error.code === 40927 && error.handle.prompt_id === 'p');
  assert.equal(requests.length, 1);
});

test('result paginates to matching prompt and excludes other turns, tools and thinking', async t => {
  const { client, requests } = await server(t, req => req.url.includes('before_turn=turn-2')
    ? { items: [turn('target')], has_more: false }
    : { items: [turn('other', 'completed', 2)], has_more: true });
  const result = await client.result('s', 'target');
  assert.equal(result.status, 'completed');
  assert.equal(result.text, 'answer for target');
  assert.equal(requests.length, 2);
});

test('missing prompt never inherits another completed turn', async t => {
  const { client } = await server(t, req => req.url.includes('/transcript')
    ? { items: [turn('other')], has_more: false } : { active: null, queued: [] });
  assert.equal((await client.result('s', 'missing')).status, 'unknown');
});

test('non-advancing transcript pagination fails explicitly', async t => {
  const { client } = await server(t, () => ({ items: [turn('other')], has_more: true }));
  await assert.rejects(client.result('s', 'missing'), /cursor did not advance/);
});

for (const kind of ['approval', 'question']) {
  test(`only the active target prompt receives ${kind} details when current_prompt_id is absent`, async t => {
    let current = 'p';
    const pending = { [`${kind}_id`]: 'input-1' };
    const { client, requests } = await server(t, req => {
      if (req.url.includes('/transcript')) return { items: [turn('p', 'running')], has_more: false };
      if (req.url.endsWith('/prompts')) return { active: current ? { prompt_id: current } : null, queued: [{ prompt_id: 'p' }] };
      if (req.url.includes(`/${kind}s?`)) return { items: [pending] };
      return { pending_interaction: kind };
    });
    const result = await client.wait('s', 'p', { timeoutMs: 1000 });
    assert.equal(result.status, 'needs_input');
    assert.equal(result.interaction, kind);
    assert.deepEqual(result.pending, [pending]);
    for (current of ['other', null]) {
      assert.equal((await client.result('s', 'p')).status, 'running');
    }
    assert.equal(requests.filter(req => req.url.includes(`/${kind}s?`)).length, 1);
  });
}

test('wait timeout covers stalled HTTP and does not cancel the task', async t => {
  const { client, requests } = await server(t, () => undefined);
  const started = Date.now();
  assert.equal((await client.wait('s', 'p', { timeoutMs: 40 })).status, 'timeout');
  assert.ok(Date.now() - started < 1000);
  assert.ok(requests.every(req => req.method === 'GET'));
});

test('wait observes terminal failure rather than waiting for idle or returning success', async t => {
  const { client } = await server(t, () => ({ items: [turn('p', 'failed')], has_more: false }));
  assert.equal((await client.wait('s', 'p')).status, 'failed');
});

test('abort acknowledgement is not terminal cancellation; already completed is reconciled', async t => {
  let completed = false;
  const { client, requests } = await server(t, (req, res) => {
    if (req.method === 'POST') {
      if (completed) { res.end(JSON.stringify({ code: 40903, msg: 'completed' })); return; }
      return { aborted: true };
    }
    return { items: [turn('p')], has_more: false };
  });
  assert.equal((await client.cancel('s', 'p')).status, 'cancellation_requested');
  assert.equal(requests[0].url, '/api/v1/sessions/s/prompts/p:abort');
  completed = true;
  assert.equal((await client.cancel('s', 'p')).status, 'completed');
});

test('reject invalid handles and command-specific options before remote mutation', async t => {
  const { client, requests } = await server(t, () => ({}));
  await assert.rejects(client.cancel('../other', 'p'));
  await assert.rejects(client.submit({ cwd: '/tmp', session: 's', prompt: 'brief' }));
  assert.equal(requests.length, 0);
  const script = new URL('../scripts/kimi-client.mjs', import.meta.url).pathname;
  assert.throws(() => execFileSync(process.execPath, [script, 'cancel', '--cwd', '/tmp', '--no-auth'], { stdio: 'pipe' }));
});
