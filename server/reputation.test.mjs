import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createReputationLookup } from './reputation.mjs';
import { createGateway } from './index.mjs';

test('fixed provider endpoint returns threat and never requests the submitted host', async () => {
  const lookup = createReputationLookup({ apiKey: 'synthetic-key', fetchImpl: async (url, options) => {
    assert.equal(url.origin, 'https://webrisk.googleapis.com');
    assert.equal(url.searchParams.get('uri'), 'https://example.test/path');
    assert.ok(options.signal);
    return Response.json({ threat: { threatTypes: ['SOCIAL_ENGINEERING'], expireTime: new Date(Date.now() + 60000).toISOString() } });
  }});
  const result = await lookup('https://example.test/path');
  assert.equal(result.status, 'matched');
  assert.deepEqual(result.threatTypes, ['SOCIAL_ENGINEERING']);
});
test('empty successful provider response means no match, not verified safe', async () => {
  const lookup = createReputationLookup({ apiKey: 'synthetic', fetchImpl: async () => Response.json({}) });
  assert.equal((await lookup('https://example.test')).status, 'noMatch');
});
test('already expired provider evidence remains unavailable', async () => {
  const lookup = createReputationLookup({apiKey: 'synthetic', fetchImpl: async () =>
    Response.json({threat: {threatTypes: ['MALWARE'], expireTime: '2000-01-01T00:00:00Z'}})});
  assert.equal((await lookup('https://example.test')).status, 'unavailable');
});
test('provider work is aborted after five seconds with a sanitized unavailable result', async () => {
  let aborted = false;
  const lookup = createReputationLookup({apiKey: 'synthetic', fetchImpl: async (_, {signal}) =>
    new Promise((resolve, reject) => {
      const timer = setTimeout(() => resolve(Response.json({})), 10000);
      signal.addEventListener('abort', () => {
        aborted = true;
        clearTimeout(timer);
        reject(new Error('private upstream diagnostic'));
      }, {once: true});
    })});
  const start = performance.now();
  const result = await lookup('https://example.test/private');
  assert.equal(aborted, true);
  assert.equal(result.status, 'unavailable');
  assert.ok(performance.now() - start < 9000);
  assert.ok(!JSON.stringify(result).includes('private'));
});
test('missing configuration, provider quota, network and malformed output stay unavailable', async () => {
  assert.equal((await createReputationLookup({})('https://example.test')).status, 'unavailable');
  for (const response of [new Response('', {status: 429}), Response.json({wrong: true}), Response.json({threat:{threatTypes:['MADE_UP']}})]) {
    const result = await createReputationLookup({apiKey:'synthetic', fetchImpl:async () => response})('https://example.test');
    assert.equal(result.status, 'unavailable');
  }
  const result = await createReputationLookup({apiKey:'synthetic', fetchImpl:async () => {throw new Error('secret upstream details');}})('https://example.test');
  assert.equal(result.status, 'unavailable');
  assert.ok(!JSON.stringify(result).includes('secret'));
});
test('gateway validates trust boundaries, method, rate limit and capabilities', async () => {
  let calls = 0;
  const server = createGateway({lookup: async () => {calls++; return {status:'noMatch',threatTypes:[],checkedAt:'2026-11-09T00:00:00Z',expiresAt:null,provider:'Google Web Risk'};}, configured:true});
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    assert.deepEqual(await (await fetch(`${base}/v1/capabilities`)).json(), {urlReputation:true,aiScanning:false});
    for (const [body, status] of [['{broken', 400], [' '.repeat(8193), 413]]) {
      const response = await fetch(`${base}/v1/link-check`, {method:'POST', headers:{'Content-Type':'application/json'}, body});
      assert.equal(response.status, status);
    }
    assert.equal((await fetch(`${base}/v1/link-check`, {method:'POST', body:'{}'})).status, 415);
    for (const body of [{url:'file:///tmp/private'},{url:'https://example.test',extra:'not allowed'},{url:'https://'+ 'a'.repeat(2048)}]) {
      assert.equal((await fetch(`${base}/v1/link-check`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)})).status,400);
    }
    assert.equal(calls,0);
    const result = await fetch(`${base}/v1/link-check`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({url:'https://example.test'})});
    assert.equal(result.status,200);
    assert.equal((await result.json()).status,'noMatch');
    assert.equal(calls,1);
    assert.equal((await fetch(`${base}/v1/link-check`)).status,405);
    for(let i=0;i<30;i++) { await fetch(`${base}/v1/link-check`,{method:'POST',body:'{}'}); }
    const limited = await fetch(`${base}/v1/link-check`,{method:'POST',body:'{}'});
    assert.equal(limited.status,429);
    assert.ok(limited.headers.get('retry-after'));
  } finally { await new Promise(resolve=>server.close(resolve)); }
});
