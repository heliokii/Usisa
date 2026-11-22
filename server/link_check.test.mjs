import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {test} from 'node:test';
import {createGateway} from './index.mjs';
import {createReputationLookup} from './reputation.mjs';

const PUBLIC = [{address:'93.184.216.34', family:4}];
const redirect = (location, status = 302) => ({status, headers:{location}, body:''});
const html = (body, headers = {}) => ({status:200, headers:{'content-type':'text/html; charset=utf-8', ...headers}, body});

// Starts the real gateway with fake DNS, fake per-hop HTTP and a fake Safe Browsing endpoint.
async function startGateway({routes = {}, dns = {}, flagged = {}, sbDown = false, sbHang = false, clock, timeouts} = {}) {
  const requests = [], resolved = [], sbCalls = [];
  const resolve = async host => {
    resolved.push(host);
    if (dns[host] instanceof Error) throw dns[host];
    return dns[host] ?? PUBLIC;
  };
  const request = async ({url, addresses, signal}) => {
    requests.push({url:url.href, addresses});
    const route = routes[url.href];
    if (typeof route === 'function') return route(signal);
    if (!route) throw new Error('ECONNREFUSED');
    return route;
  };
  const lookup = createReputationLookup({apiKey:'synthetic', fetchImpl:async (_url, options) => {
    const entries = JSON.parse(options.body).threatInfo.threatEntries.map(e => e.url);
    sbCalls.push(entries);
    if (sbDown) return new Response('', {status:503});
    if (sbHang) await new Promise((_, reject) => options.signal.addEventListener('abort', () => reject(options.signal.reason)));
    const matches = entries.filter(u => flagged[u]).map(u => ({threatType:flagged[u], threatEntryType:'URL',
      threat:{url:u}, cacheDuration:'300s'}));
    return Response.json(matches.length ? {matches} : {});
  }});
  const server = createGateway({lookup, configured:true, resolve, request, timeouts,
    now:clock ? () => clock.now : Date.now});
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  const check = async url => {
    const response = await fetch(`${base}/v1/link-check`, {method:'POST',
      headers:{'Content-Type':'application/json'}, body:JSON.stringify({url})});
    return {code:response.status, ...await response.json()};
  };
  return {check, requests, resolved, sbCalls, close:() => new Promise(r => server.close(r))};
}

test('follows a redirect chain and returns the real destination with every hop', async () => {
  const gw = await startGateway({routes:{
    'https://bit.ly/abc': redirect('https://track.example.com/c?id=1', 301),
    'https://track.example.com/c?id=1': redirect('/landing'),
    'https://track.example.com/landing': html('<p>hello</p>'),
  }});
  try {
    const r = await gw.check('https://bit.ly/abc');
    assert.equal(r.code, 200);
    assert.equal(r.status, 'noMatch');
    assert.equal(r.expansion, 'expanded');
    assert.equal(r.destination, 'https://track.example.com/landing');
    assert.deepEqual(r.hops, ['https://track.example.com/c?id=1', 'https://track.example.com/landing']);
    assert.deepEqual(gw.sbCalls, [['https://bit.ly/abc', 'https://track.example.com/c?id=1',
      'https://track.example.com/landing']]);
  } finally { await gw.close(); }
});

test('a flagged hop at any step is reported, and the raw link counts too', async () => {
  const routes = {
    'https://bit.ly/a': redirect('https://mid.example.com/'),
    'https://mid.example.com/': redirect('https://end.example.com/'),
    'https://end.example.com/': html('ok'),
  };
  for (const bad of ['https://bit.ly/a', 'https://mid.example.com/', 'https://end.example.com/']) {
    const gw = await startGateway({routes, flagged:{[bad]:'SOCIAL_ENGINEERING'}});
    try {
      const r = await gw.check('https://bit.ly/a');
      assert.equal(r.status, 'matched');
      assert.deepEqual(r.threatTypes, ['SOCIAL_ENGINEERING']);
      assert.deepEqual(r.flaggedUrls, [bad]);
      assert.ok(r.expiresAt);
      assert.equal(gw.sbCalls.length, 1);
    } finally { await gw.close(); }
  }
});

test('a flagged hop beats an unfinished expansion', async () => {
  const gw = await startGateway({routes:{'https://bit.ly/a': redirect('http://127.0.0.1/admin')},
    flagged:{'https://bit.ly/a':'MALWARE'}});
  try {
    const r = await gw.check('https://bit.ly/a');
    assert.equal(r.status, 'matched');
    assert.equal(r.expansion, 'unresolved');
  } finally { await gw.close(); }
});

test('stops after 8 hops and on loops', async () => {
  const chain = n => Object.fromEntries(Array.from({length:n}, (_, i) =>
    [`https://h${i}.example.com/`, redirect(`https://h${i + 1}.example.com/`)]));
  const eight = await startGateway({routes:{...chain(8), 'https://h8.example.com/': html('end')}});
  try {
    const r = await eight.check('https://h0.example.com/');
    assert.equal(r.status, 'noMatch');
    assert.equal(r.hops.length, 8);
    assert.equal(r.destination, 'https://h8.example.com/');
  } finally { await eight.close(); }
  const nine = await startGateway({routes:{...chain(9), 'https://h9.example.com/': html('end')}});
  try {
    const r = await nine.check('https://h0.example.com/');
    assert.equal(r.status, 'unavailable');
    assert.equal(r.reason, 'too_many_hops');
    assert.equal(r.destination, null);
    assert.equal(r.hops.length, 8);
    assert.ok(!nine.requests.some(q => q.url === 'https://h9.example.com/'));
  } finally { await nine.close(); }
  const loop = await startGateway({routes:{'https://a.example.com/': redirect('https://b.example.com/'),
    'https://b.example.com/': redirect('https://a.example.com/')}});
  try {
    const r = await loop.check('https://a.example.com/');
    assert.equal(r.status, 'unavailable');
    assert.equal(r.reason, 'loop');
  } finally { await loop.close(); }
});

test('per-hop and total time limits end in unresolved', async () => {
  const hang = signal => new Promise((_, reject) => signal.addEventListener('abort', () => reject(signal.reason)));
  const slow = next => signal => new Promise((resolve, reject) => {
    const t = setTimeout(() => resolve(redirect(next)), 2200);
    signal.addEventListener('abort', () => { clearTimeout(t); reject(signal.reason); });
  });
  const hop = await startGateway({routes:{'https://bit.ly/x': hang}});
  const total = await startGateway({routes:{'https://bit.ly/y': slow('https://a.example.com/'),
    'https://a.example.com/': slow('https://b.example.com/'), 'https://b.example.com/': slow('https://c.example.com/'),
    'https://c.example.com/': html('end')}});
  try {
    const start = performance.now();
    const [h, t] = await Promise.all([hop.check('https://bit.ly/x'), total.check('https://bit.ly/y')]);
    assert.equal(h.status, 'unavailable');
    assert.equal(h.reason, 'timeout_hop');
    assert.equal(t.status, 'unavailable');
    assert.equal(t.reason, 'timeout_total');
    assert.deepEqual(t.hops, ['https://a.example.com/', 'https://b.example.com/']);
    const elapsed = performance.now() - start;
    assert.ok(elapsed > 5800 && elapsed < 7500, `took ${elapsed} ms`);
  } finally { await hop.close(); await total.close(); }
});

test('refuses internal, transition-range and odd destinations without connecting', async () => {
  for (const [target, reason] of [
    ['http://127.0.0.1/', 'blocked_address'], ['http://0x7f.1/', 'blocked_address'],
    ['http://2130706433/', 'blocked_address'], ['http://10.1.2.3/', 'blocked_address'],
    ['http://169.254.169.254/latest/meta-data/', 'blocked_address'], ['http://100.64.0.1/', 'blocked_address'],
    ['http://[::1]/', 'blocked_address'], ['http://[::ffff:169.254.169.254]/', 'blocked_address'],
    ['http://[fd00:ec2::254]/', 'blocked_address'], ['http://[fe80::1]/', 'blocked_address'],
    ['http://[64:ff9b::a9fe:a9fe]/', 'blocked_address'], ['http://[2002:c0a8:101::1]/', 'blocked_address'],
    ['http://[2001:0:4136:e378::1]/', 'blocked_address'], ['http://localhost/', 'blocked_address'],
    ['http://metadata.google.internal/', 'blocked_address'], ['http://printer.local/', 'blocked_address'],
    ['http://intranet/', 'blocked_address'], ['http://example.com:8080/', 'blocked_port'],
    ['http://user:pw@example.com/', 'credentials_in_url'],
  ]) {
    const gw = await startGateway({routes:{'https://bit.ly/x': redirect(target)}});
    try {
      const r = await gw.check('https://bit.ly/x');
      assert.equal(r.status, 'unavailable', target);
      assert.equal(r.reason, reason, target);
      assert.equal(gw.requests.length, 1, target);
    } finally { await gw.close(); }
  }
});

test('bare internal IPs as the submitted link are refused before any request', async () => {
  for (const url of ['http://127.0.0.1/', 'http://[::1]:443/', 'https://192.168.1.1/']) {
    const gw = await startGateway();
    try {
      const r = await gw.check(url);
      assert.equal(r.status, 'unavailable', url);
      assert.equal(r.reason, 'blocked_address', url);
      assert.equal(gw.requests.length, 0, url);
    } finally { await gw.close(); }
  }
});

test('DNS is resolved once per hop, any private answer is refused, and the checked addresses are used', async () => {
  const mixed = await startGateway({routes:{'https://bit.ly/x': redirect('https://evil.example.com/')},
    dns:{'evil.example.com':[{address:'93.184.216.34', family:4}, {address:'10.0.0.5', family:4}]}});
  try {
    const r = await mixed.check('https://bit.ly/x');
    assert.equal(r.reason, 'blocked_address');
    assert.equal(mixed.requests.length, 1);
  } finally { await mixed.close(); }
  const six = await startGateway({routes:{'https://bit.ly/x': redirect('https://v6.example.com/')},
    dns:{'v6.example.com':[{address:'2002:a00:1::1', family:6}]}});
  try { assert.equal((await six.check('https://bit.ly/x')).reason, 'blocked_address'); } finally { await six.close(); }
  const failing = await startGateway({dns:{'nx.example.com':new Error('ENOTFOUND')}});
  try { assert.equal((await failing.check('https://nx.example.com/')).reason, 'dns_error'); } finally { await failing.close(); }
  const pinned = [{address:'2606:4700::1', family:6}, {address:'93.184.216.34', family:4}];
  const ok = await startGateway({routes:{'https://good.example.com/': html('ok')}, dns:{'good.example.com':pinned}});
  try {
    await ok.check('https://good.example.com/');
    assert.deepEqual(ok.resolved, ['good.example.com']);
    assert.deepEqual(ok.requests[0].addresses, pinned);
  } finally { await ok.close(); }
});

test('follows the Refresh header and meta refresh, never JavaScript', async () => {
  const forms = [
    '<META http-equiv="refresh" content="0;URL=https://dest.example.com/a">',
    `<meta content='1; url="https://dest.example.com/a"' http-equiv='Refresh'>`,
    '<meta http-equiv=refresh content="0, https://dest.example.com/a">',
    '<meta http-equiv="refresh" content="  3.5  URL = \'https://dest.example.com/a\'">',
    '<meta http-equiv="refresh" content="0;url=https://dest.example.com/a?x=1&amp;y=2">',
  ];
  for (const meta of forms) {
    const gw = await startGateway({routes:{'https://t.co/x': html(`<head>${meta}</head>`),
      'https://dest.example.com/a': html('ok'), 'https://dest.example.com/a?x=1&y=2': html('ok')}});
    try {
      const r = await gw.check('https://t.co/x');
      assert.equal(r.status, 'noMatch', meta);
      assert.match(r.destination, /^https:\/\/dest\.example\.com\/a/, meta);
    } finally { await gw.close(); }
  }
  const header = await startGateway({routes:{'https://x.example.com/': html('', {refresh:'0; url=/next'}),
    'https://x.example.com/next': html('ok')}});
  try { assert.equal((await header.check('https://x.example.com/')).destination, 'https://x.example.com/next'); }
  finally { await header.close(); }
  const slowRefresh = await startGateway({routes:{
    'https://x.example.com/': html('<meta http-equiv="refresh" content="30;url=https://y.example.com/">')}});
  try { assert.equal((await slowRefresh.check('https://x.example.com/')).destination, 'https://x.example.com/'); }
  finally { await slowRefresh.close(); }
  const js = await startGateway({routes:{
    'https://x.example.com/': html('<script>location.replace("https://y.example.com/")</script>')}});
  try {
    const r = await js.check('https://x.example.com/');
    assert.equal(r.destination, 'https://x.example.com/');
    assert.equal(js.requests.length, 1);
  } finally { await js.close(); }
});

test('ending on a known shortener page means the destination is unconfirmed', async () => {
  const gw = await startGateway({routes:{'https://tinyurl.com/abc': redirect('https://tinyurl.com/preview/abc'),
    'https://tinyurl.com/preview/abc': html('<a href="http://www.example.com/">go</a>')}});
  try {
    const r = await gw.check('https://tinyurl.com/abc');
    assert.equal(r.status, 'unavailable');
    assert.equal(r.reason, 'interstitial');
    assert.equal(r.destination, null);
    assert.deepEqual(r.hops, ['https://tinyurl.com/preview/abc']);
  } finally { await gw.close(); }
});

test('a link blocked by the shortener itself is reported distinctly and its target is checked', async () => {
  const gw = await startGateway({routes:{'https://cutt.ly/abc':
    redirect('https://transparencyreport.google.com/safe-browsing/search?url=angora.me', 301)}});
  try {
    const r = await gw.check('https://cutt.ly/abc');
    assert.equal(r.status, 'blockedByShortener');
    assert.equal(r.blockedUrl, 'http://angora.me/');
    assert.equal(gw.requests.length, 1);
    assert.deepEqual(gw.sbCalls, [['https://cutt.ly/abc',
      'https://transparencyreport.google.com/safe-browsing/search?url=angora.me', 'http://angora.me/']]);
  } finally { await gw.close(); }
});

test('non-web destinations, HTTP errors and Safe Browsing outages are never clean', async () => {
  const intent = await startGateway({routes:{'https://bit.ly/x': redirect('intent://pay#Intent;scheme=gcash;end')}});
  try {
    const r = await intent.check('https://bit.ly/x');
    assert.equal(r.status, 'unavailable');
    assert.equal(r.reason, 'non_web_destination');
    assert.equal(r.destination, 'intent://pay#Intent;scheme=gcash;end');
  } finally { await intent.close(); }
  const notFound = await startGateway({routes:{'https://x.example.com/': {status:404, headers:{}, body:''}}});
  try { assert.equal((await notFound.check('https://x.example.com/')).reason, 'http_error'); } finally { await notFound.close(); }
  const sbDown = await startGateway({routes:{'https://x.example.com/': html('ok')}, sbDown:true});
  try {
    const r = await sbDown.check('https://x.example.com/');
    assert.equal(r.status, 'unavailable');
    assert.equal(r.expansion, 'expanded');
  } finally { await sbDown.close(); }
});

test('cache windows: chain 10 min, clean result 5 min, failure 30 s', async () => {
  const clock = {now:Date.parse('2026-11-21T00:00:00Z')};
  const gw = await startGateway({clock, routes:{'https://bit.ly/a': redirect('https://end.example.com/'),
    'https://end.example.com/': html('ok')}});
  try {
    await gw.check('https://bit.ly/a');
    assert.equal(gw.requests.length, 2); assert.equal(gw.sbCalls.length, 1);
    clock.now += 4 * 60e3;
    assert.equal((await gw.check('https://bit.ly/a')).status, 'noMatch');
    assert.equal(gw.requests.length, 2); assert.equal(gw.sbCalls.length, 1);
    clock.now += 2 * 60e3; // 6 min: clean result expired, chain still cached
    await gw.check('https://bit.ly/a');
    assert.equal(gw.requests.length, 2); assert.equal(gw.sbCalls.length, 2);
    clock.now += 5 * 60e3; // 11 min: chain expired
    await gw.check('https://bit.ly/a');
    assert.equal(gw.requests.length, 4); assert.equal(gw.sbCalls.length, 3);
  } finally { await gw.close(); }
  const failing = await startGateway({clock, routes:{'https://bit.ly/b': redirect('http://10.0.0.1/')}});
  try {
    await failing.check('https://bit.ly/b');
    clock.now += 29e3;
    assert.equal((await failing.check('https://bit.ly/b')).reason, 'blocked_address');
    assert.equal(failing.requests.length, 1);
    clock.now += 2e3;
    await failing.check('https://bit.ly/b');
    assert.equal(failing.requests.length, 2);
  } finally { await failing.close(); }
});

test('a slow Safe Browsing gets only the time left, so a followed chain still answers before the deadline', async () => {
  const gw = await startGateway({sbHang:true, timeouts:{aiMs:16000, linkCheckMs:1500}, routes:{
    'https://bit.ly/abc': redirect('https://shop.example.com/'),
    'https://shop.example.com/': html('<p>hi</p>'),
  }});
  try {
    const r = await gw.check('https://bit.ly/abc');
    assert.equal(r.code, 200);
    assert.equal(r.status, 'unavailable');
    assert.equal(r.destination, 'https://shop.example.com/');
  } finally { await gw.close(); }
});

test('the default follower refuses loopback hosts without connecting', async () => {
  let hits = 0;
  const local = createServer((_req, res) => { hits++; res.end('secret'); });
  await new Promise(r => local.listen(0, '127.0.0.1', r));
  const port = local.address().port;
  const lookup = createReputationLookup({apiKey:'synthetic', fetchImpl:async () => Response.json({})});
  const server = createGateway({lookup, configured:true});
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  try {
    for (const url of [`http://127.0.0.1:${port}/`, `http://localhost:${port}/`, 'http://localhost/']) {
      const response = await fetch(`http://127.0.0.1:${server.address().port}/v1/link-check`, {method:'POST',
        headers:{'Content-Type':'application/json'}, body:JSON.stringify({url})});
      const r = await response.json();
      assert.equal(r.status, 'unavailable', url);
    }
    assert.equal(hits, 0);
  } finally { await new Promise(r => server.close(r)); await new Promise(r => local.close(r)); }
});
