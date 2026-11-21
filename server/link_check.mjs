import net from 'node:net';
import dns from 'node:dns/promises';
import http from 'node:http';
import https from 'node:https';

// Short-link follower + Safe Browsing on every hop. Response contract: see README "Link check response".
const MAX_HOPS = 8, HOP_MS = 2500, TOTAL_MS = 6000, MAX_BODY = 65536, MAX_REFRESH_S = 10;
const CHAIN_MS = 10 * 60e3, CLEAN_MS = 5 * 60e3, FAIL_MS = 30e3, CACHE_MAX = 1000;
const SHORTENERS = new Set(['bit.ly', 'tinyurl.com', 'is.gd', 'v.gd', 'cutt.ly', 'shorturl.at', 'rb.gy', 't.co',
  's.id', 'tiny.cc', 't.ly', 'ow.ly', 'goo.su', 'qrco.de']);
const UA = 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';

const deny = new net.BlockList();
for (const [n, p] of [['0.0.0.0', 8], ['10.0.0.0', 8], ['100.64.0.0', 10], ['127.0.0.0', 8], ['169.254.0.0', 16],
  ['172.16.0.0', 12], ['192.0.0.0', 24], ['192.0.2.0', 24], ['192.88.99.0', 24], ['192.168.0.0', 16],
  ['198.18.0.0', 15], ['198.51.100.0', 24], ['203.0.113.0', 24], ['224.0.0.0', 4], ['240.0.0.0', 4]]) deny.addSubnet(n, p, 'ipv4');
// Teredo, documentation, 6to4, NAT64 (the NAT64 ranges already sit outside 2000::/3; listed for intent).
for (const [n, p] of [['2001::', 32], ['2001:db8::', 32], ['2002::', 16], ['64:ff9b::', 96], ['64:ff9b:1::', 48]]) deny.addSubnet(n, p, 'ipv6');
const global6 = new net.BlockList();
global6.addSubnet('2000::', 3, 'ipv6');
const isPublicIp = (a, fam = net.isIP(a)) =>
  fam === 4 ? !deny.check(a, 'ipv4') : fam === 6 && global6.check(a, 'ipv6') && !deny.check(a, 'ipv6');
const badHostname = h => h === 'localhost' || !h.includes('.') || /\.(internal|local|localhost)\.?$/.test(h);

async function defaultResolve(host) { return dns.lookup(host, {all:true}); }

// One GET to the already-checked addresses: the custom lookup hands them back, so there is no second DNS query.
function defaultRequest({url, addresses, signal}) {
  return new Promise((resolve, reject) => {
    const req = (url.protocol === 'https:' ? https : http).request(url, {method:'GET', agent:false, signal,
      headers:{'User-Agent':UA, 'Accept':'text/html,*/*', 'Accept-Encoding':'identity'},
      lookup:(_host, opts, cb) => opts.all ? cb(null, addresses) : cb(null, addresses[0].address, addresses[0].family),
    }, res => {
      const {statusCode:status, headers} = res;
      if (status !== 200 || !/text\/html/i.test(headers['content-type'] ?? '')) {
        res.destroy(); resolve({status, headers, body:''}); return;
      }
      const chunks = [];
      let size = 0;
      const done = () => resolve({status, headers, body:Buffer.concat(chunks).subarray(0, MAX_BODY).toString('utf8')});
      res.on('data', c => { chunks.push(c); size += c.length; if (size >= MAX_BODY) { res.destroy(); done(); } });
      res.on('end', done);
      res.on('close', done);
      res.on('error', reject);
    });
    req.on('error', reject);
    req.end();
  });
}

// HTML "shared declarative refresh steps"; returns the target URL or null.
export function parseRefresh(content, base) {
  const s = content, ws = c => ' \t\n\f\r'.includes(c);
  let i = 0;
  while (i < s.length && ws(s[i])) i++;
  const start = i;
  while (i < s.length && s[i] >= '0' && s[i] <= '9') i++;
  if (i === start && s[i] !== '.') return null;
  const delay = Number(s.slice(start, i) || 0);
  while (i < s.length && (s[i] === '.' || (s[i] >= '0' && s[i] <= '9'))) i++;
  if (delay > MAX_REFRESH_S) return null;
  if (i < s.length) {
    if (!(s[i] === ';' || s[i] === ',' || ws(s[i]))) return null;
    while (i < s.length && ws(s[i])) i++;
    if (s[i] === ';' || s[i] === ',') i++;
    while (i < s.length && ws(s[i])) i++;
  }
  if (i >= s.length) return null; // refresh to self: no new hop
  let rest = s.slice(i);
  const m = /^url\s*=\s*/i.exec(rest);
  if (m) rest = rest.slice(m[0].length);
  if (rest[0] === '"' || rest[0] === "'") {
    const q = rest[0], end = rest.indexOf(q, 1);
    rest = rest.slice(1, end < 0 ? undefined : end);
  }
  try { return new URL(rest.trim(), base); } catch (_) { return null; }
}

const decode = v => v.replace(/&(amp|quot|#39|apos|lt|gt);/gi, (_, e) =>
  ({amp:'&', quot:'"', '#39':"'", apos:"'", lt:'<', gt:'>'})[e.toLowerCase()]);

function metaRefresh(html) {
  for (const tag of html.slice(0, MAX_BODY).match(/<meta\b[^>]*>/gi) ?? []) {
    const attrs = {};
    for (const [, k, , dq, sq, bare] of tag.matchAll(/([a-z-]+)\s*=\s*("([^"]*)"|'([^']*)'|([^\s>]+))/gi)) {
      attrs[k.toLowerCase()] = decode(dq ?? sq ?? bare);
    }
    if (attrs['http-equiv']?.toLowerCase() === 'refresh' && attrs.content !== undefined) return attrs.content;
  }
  return null;
}

function createFollower({resolve, request}) {
  return async function follow(input) {
    const hops = [];
    const total = AbortSignal.timeout(TOTAL_MS);
    const fail = (reason, extra = {}) => ({status:'unresolved', reason, hops, destination:null, ...extra});
    const seen = new Set([input]);
    let url = new URL(input);
    for (;;) {
      if (url.username || url.password) return fail('credentials_in_url');
      if (url.port && url.port !== '80' && url.port !== '443') return fail('blocked_port');
      const host = url.hostname.replace(/^\[|\]$/g, '');
      let addresses;
      if (net.isIP(host)) {
        // Node skips the custom lookup for IP literals, so they get their own check.
        if (!isPublicIp(host)) return fail('blocked_address');
        addresses = [{address:host, family:net.isIP(host)}];
      } else {
        if (badHostname(host)) return fail('blocked_address');
        try { addresses = await resolve(host); } catch (_) { return fail(total.aborted ? 'timeout_total' : 'dns_error'); }
        if (!addresses?.length || !addresses.every(a => isPublicIp(a.address, a.family))) return fail('blocked_address');
      }
      if (total.aborted) return fail('timeout_total');
      const hopSignal = AbortSignal.timeout(HOP_MS);
      let res;
      try {
        res = await request({url, addresses, signal:AbortSignal.any([hopSignal, total])});
      } catch (_) {
        return fail(total.aborted ? 'timeout_total' : hopSignal.aborted ? 'timeout_hop' : 'fetch_error');
      }
      const headers = res.headers ?? {};
      let next = null;
      if ([301, 302, 303, 307, 308].includes(res.status) && headers.location) {
        try { next = new URL(headers.location, url); } catch (_) { return fail('fetch_error'); }
      } else if (res.status === 200) {
        const refresh = headers.refresh ?? (/text\/html/i.test(headers['content-type'] ?? '') ? metaRefresh(res.body ?? '') : null);
        if (refresh != null) next = parseRefresh(refresh, url);
      }
      if (!next) {
        if (res.status !== 200) return fail('http_error');
        if (SHORTENERS.has(url.hostname)) return fail('interstitial');
        return {status:'expanded', hops, destination:url.href};
      }
      if (hops.length >= MAX_HOPS) return fail('too_many_hops');
      if (!['http:', 'https:'].includes(next.protocol)) {
        hops.push(next.href);
        return fail('non_web_destination', {destination:next.href});
      }
      if (next.href.length > 2048) return fail('fetch_error');
      if (seen.has(next.href)) return fail('loop');
      seen.add(next.href);
      hops.push(next.href);
      if (next.hostname === 'transparencyreport.google.com' && next.pathname === '/safe-browsing/search') {
        // Shortener refused the link and pointed at Google's report for it; do not follow further.
        const target = next.searchParams.get('url') ?? '';
        let blockedUrl = null;
        try { blockedUrl = new URL(/^https?:\/\//i.test(target) ? target : `http://${target}`).href; } catch (_) {}
        return {status:'blocked', hops, destination:null, blockedUrl};
      }
      url = next;
    }
  };
}

function boundedCache() {
  const map = new Map();
  return {
    get(key, at) { const e = map.get(key); return e && e.until > at ? e : undefined; },
    set(key, value) {
      map.delete(key);
      map.set(key, value);
      if (map.size > CACHE_MAX) map.delete(map.keys().next().value);
    },
  };
}

export function createLinkChecker({lookup, resolve = defaultResolve, request = defaultRequest, now = Date.now}) {
  const follow = createFollower({resolve, request});
  const chains = boundedCache(), verdicts = boundedCache();
  return async function check(input) {
    let chain = chains.get(input, now())?.chain;
    if (!chain) {
      chain = await follow(input);
      chains.set(input, {chain, until:now() + (chain.status === 'unresolved' ? FAIL_MS : CHAIN_MS)});
    }
    const at = now();
    const urls = [...new Set([input, ...chain.hops.filter(h => /^https?:/.test(h)), chain.blockedUrl].filter(Boolean))];
    const missing = urls.filter(u => !verdicts.get(u, at));
    let provider = 'Google Safe Browsing', sbFailed = false;
    if (missing.length) {
      const sb = await lookup(missing);
      provider = sb.provider ?? provider;
      if (sb.status === 'unavailable') sbFailed = true;
      else {
        const expires = sb.expiresAt ? Date.parse(sb.expiresAt) - Date.parse(sb.checkedAt) : CLEAN_MS;
        for (const u of missing) {
          const threats = sb.matches?.[u] ?? [];
          verdicts.set(u, {threats, until:at + (threats.length ? expires : CLEAN_MS)});
        }
      }
    }
    const flaggedUrls = urls.filter(u => verdicts.get(u, at)?.threats.length);
    const threatTypes = [...new Set(flaggedUrls.flatMap(u => verdicts.get(u, at).threats))];
    const status = flaggedUrls.length ? 'matched'
      : chain.status === 'blocked' ? 'blockedByShortener'
      : chain.status !== 'expanded' || sbFailed ? 'unavailable' : 'noMatch';
    const expiresAt = flaggedUrls.length ? new Date(Math.min(...flaggedUrls.map(u => verdicts.get(u, at).until))).toISOString() : null;
    return {status, threatTypes, flaggedUrls, checkedAt:new Date(at).toISOString(), expiresAt, provider,
      expansion:chain.status, destination:chain.destination, hops:chain.hops,
      ...(chain.reason && {reason:chain.reason}), ...(chain.blockedUrl && {blockedUrl:chain.blockedUrl})};
  };
}
