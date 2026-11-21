import assert from 'node:assert/strict';
import {test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {createGateway, TIMEOUTS} from './index.mjs';

const text = 'GCash: Send your OTP immediately.';

async function gateway(opts, run) {
  const server = createGateway({configured:false,aiConfigured:true,scanAi:async()=>({state:'completed'}),...opts});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = (headers = {}) => fetch(`${base}/v1/ai-scan`,{method:'POST',
    headers:{'Content-Type':'application/json','Idempotency-Key':crypto.randomUUID(),...headers},
    body:JSON.stringify({text,responseLanguage:'en'})});
  try { await run({post}); } finally { server.closeAllConnections(); await new Promise(resolve=>server.close(resolve)); }
}

test('behind Render, each forwarded client address gets its own rate-limit bucket', async () => {
  await gateway({trustProxy:true},async({post})=>{
    const phoneA = {'CF-Connecting-IP':'203.0.113.10'};
    for (let n=0;n<10;n++) assert.equal((await post(phoneA)).status,200);
    assert.equal((await post(phoneA)).status,429);
    assert.equal((await post({'CF-Connecting-IP':'203.0.113.20'})).status,200);
    // A client-supplied X-Forwarded-For cannot buy a fresh bucket; only Cloudflare's overwritten header counts.
    assert.equal((await post({...phoneA,'X-Forwarded-For':'198.51.100.7'})).status,429);
  });
});

test('without a trusted proxy, forwarded headers are ignored and the socket peer is the client', async () => {
  await gateway({trustProxy:false},async({post})=>{
    for (let n=0;n<10;n++) assert.equal((await post({'CF-Connecting-IP':`203.0.113.${n}`})).status,200);
    assert.equal((await post({'CF-Connecting-IP':'203.0.113.99'})).status,429);
  });
});

test('a slow upstream ends in unavailable at the server deadline, before the app gives up', async () => {
  let release;
  await gateway({timeouts:{aiMs:50,linkCheckMs:50},scanAi:()=>new Promise(resolve=>{ release = resolve; })},async({post})=>{
    const response = await post();
    assert.equal(response.status,503);
    assert.deepEqual(await response.json(),{error:'unavailable'});
    release({state:'completed'});
  });
});

async function appSeconds(file, pattern) {
  const source = await readFile(new URL(`../lib/features/scan/${file}`,import.meta.url),'utf8');
  const match = source.match(pattern);
  assert.ok(match,`app timeout not found in ${file}`);
  return Number(match[1])*1000;
}

test('server deadlines stay at least 1 s below the app request timeouts', async () => {
  const appAi = await appSeconds('ai_scan_client.dart',/timeout = const Duration\(seconds: (\d+)\)/);
  const appLink = await appSeconds('reputation_client.dart',/\.timeout\(const Duration\(seconds: (\d+)\)\)/);
  assert.ok(TIMEOUTS.aiMs <= appAi-1000,`AI ${TIMEOUTS.aiMs} ms vs app ${appAi} ms`);
  assert.ok(TIMEOUTS.linkCheckMs <= appLink-1000,`link check ${TIMEOUTS.linkCheckMs} ms vs app ${appLink} ms`);
});
