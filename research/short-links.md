# How the gateway should safely open short links

Research for [#6](https://github.com/heliokii/Usisa/issues/6) (parent map #4, blocks #12).
Date: 2026-11-21. Node checked: v24.14.1 (local). Gateway code read: `server/index.mjs`, `server/reputation.mjs` on `main` @ `a862497`.

## Answer in one paragraph

Add a **link expander** to the gateway, written with `node:http`/`node:https` (not `fetch`), which follows redirects by hand. It uses `GET` and never `HEAD`. Limits: **at most 8 hops**, **2.5 s per hop**, **6 s total**, ports 80/443 only, at most 64 KiB of body read and only when a page might hold a meta refresh. Every connection goes through a **custom `lookup` function** that resolves the name once and refuses any non-public address. The socket then connects to exactly the address that was checked, so DNS rebinding has no second lookup to exploit. Literal-IP hosts are checked separately, because `lookup` is skipped for them. Follow HTTP 3xx `Location`, the `Refresh` header and `<meta http-equiv="refresh">`. Never run JavaScript. When expansion ends on a shortener's own preview or warning page, the destination is unconfirmed. Send **every hop URL in one Safe Browsing `threatMatches:find` call** (the limit is 500 entries). Cache expansion chains in memory for about 10 minutes. **Any** failure (timeout, blocked address, too many hops, loop, TLS error, non-web scheme, interstitial, Safe Browsing unavailable) must return a status the app shows as **Couldn't check**. A failure never falls through to `noMatch`, and so never shows as Looks safe.

## What the code does today

- `reputation.mjs` sends the single input URL to Safe Browsing v4 Lookup with a 5 s timeout. The `redirect:'error'` option only covers the call to googleapis.com. The short link itself is never opened, so for `bit.ly/x` only the string `https://bit.ly/x` is checked.
- The response check requires `match.threat?.url === input`. With several hops in one batch, this has to become "is in the set of URLs sent".
- `index.mjs` sets `requestTimeout = 10000` and allows 8 link checks at once (`active >= 8`). The expansion budget has to fit inside 10 s together with Safe Browsing (5 s). Hence 6 s total for expansion, plus up to about 3 s for a Safe Browsing call that can start early (see the flow below).

## Findings, with sources

### 1. Redirect rules and hop limits

- RFC 9110 sets no number: "A client SHOULD detect and intervene in cyclical redirections". It notes that an earlier version recommended a maximum of five ([RFC 9110 §15.4](https://www.rfc-editor.org/rfc/rfc9110#section-15.4)). A `Location` value can be relative and is resolved against the target URI ([§10.2.2](https://www.rfc-editor.org/rfc/rfc9110#section-10.2.2)).
- Browsers (Fetch Standard) give up after 20 redirects: "If request's redirect count is 20, then return a network error" ([Fetch §4.4 HTTP-redirect fetch](https://fetch.spec.whatwg.org/#http-redirect-fetch)).
- Only 301, 302, 303, 307 and 308 with a `Location` header are redirects to follow. 300, 304 and 305 are not.
- **Recommendation:** at most 8 hops. That is more than the RFC 2068 figure of five, to allow for chains like shortener → click tracker → second shortener → landing page, and far fewer than 20, because the time budget is small. Loop detection: keep a `Set` of visited normalized URLs and stop on a repeat.

### 2. HTTP 3xx vs meta refresh vs JavaScript

- The HTML Standard treats the `Refresh` response header the same way as `<meta http-equiv="refresh">`. Both run the "shared declarative refresh steps" ([HTML document lifecycle: "If navigationParams's response has a `Refresh` header"](https://html.spec.whatwg.org/multipage/document-lifecycle.html); [parsing algorithm](https://html.spec.whatwg.org/multipage/semantics.html#shared-declarative-refresh-steps)). The content is `<digits>[.digits]`, then `;` or `,` or whitespace, then an optional `url=` and optional quotes, then the URL. Write the parser by following those steps, not with a loose regex.
- **Observed** (probe from this machine, 2026-11-21): `t.co` answers **200** with `<META http-equiv="refresh" content="0;URL=…">` plus a `location.replace(...)` script. It does not use a 3xx. A `HEAD` request to t.co returns 200 with no destination at all. A follower that only handles 3xx therefore stops at t.co.
- JavaScript redirects need a browser engine, which the free Render instance can't run. Don't execute JS. If the final page is still on a shortener or redirector host and contains no declarative redirect, return `unresolved` ("Couldn't check"). Don't treat that page as the destination.
- **Recommendation:** follow a meta or header refresh only when the delay is ≤ 10 s, the response is `text/html`, and the tag is within the first 64 KiB. Each refresh counts as a hop.

### 3. HEAD vs GET

Observed, with a mobile Chrome User-Agent and `redirect:'manual'`:

| Short link | HEAD | GET |
|---|---|---|
| `bit.ly/<code>` | 301 + Location | 301 + Location |
| `tinyurl.com/<code>` | 302 → `tinyurl.com/preview/<code>` (for that code) | same |
| `is.gd/<code>` | 301 + Location | 301 + Location |
| `cutt.ly/<code>` | 301 + Location | 301 + Location |
| `shorturl.at/<code>` | **403** | 301 → `www.shorturl.at/<code>` → 302 → destination |
| `rb.gy/<code>` | **403** | 302 |
| `t.co/<code>` | **200, no Location** | 200 + meta refresh |
| `s.id/<code>`, `tiny.cc/<code>` | 303 + Location | 303 + Location |
| `bit.ly/<code>+` (preview) | **405** | 200 HTML preview |

**Recommendation:** always use `GET`. On a 3xx, read only the headers and then `res.destroy()`, with no body download. Read the body (capped at 64 KiB) only for a 200 `text/html` response. Send `Accept-Encoding: identity`, because `http.request` doesn't decompress. Send no cookies, no `Referer` and no credentials. Also send a fixed, generic mobile User-Agent. Shorteners serve some interstitials based on the User-Agent, and a mobile UA matches what the user's phone would get.

### 4. Shortener interstitial and preview pages

- **Observed:** `tinyurl.com/google` 302-redirects to `tinyurl.com/preview/google`, a 200 HTML page whose only outbound link is the destination (`href="http://www.google.com/"`). TinyURL sends some links to its preview page rather than the destination.
- **Observed:** `cutt.ly/google` 301-redirects to `https://transparencyreport.google.com/safe-browsing/search?url=angora.me`. Cutt.ly sends links it has blocked to Google's Safe Browsing report page. The real destination is in the `url=` parameter.
- Manual preview tricks exist, but they are documented by third parties, not by the services: `bit.ly/x+`, `preview.tinyurl.com/x`, `is.gd/x-` ([Bitly on Wikipedia](https://en.wikipedia.org/wiki/Bitly), [CMU security tips](https://www.cmu.edu/computing/safe/secure-your/dont-take-the-bait/shortened-url-security.html), [TinyURL on Wikipedia](https://en.wikipedia.org/wiki/TinyURL)). The gateway doesn't need them, because following the redirect gives the same answer.
- **Recommendation:**
  - Keep a small table of **known shortener hosts**: `bit.ly`, `tinyurl.com`, `is.gd`, `v.gd`, `cutt.ly`, `shorturl.at`, `rb.gy`, `t.co`, `s.id`, `tiny.cc`, `t.ly`, `ow.ly`, `goo.su`, `qrco.de`. Which ones matter most for PH SMS scams is not measured here. Grow the table from the Yissuh dataset in #4.
  - If expansion **ends with a 200 page on a known shortener host**, return `unresolved` with reason `interstitial`, which the app shows as Couldn't check.
  - Special case: a final hop to `transparencyreport.google.com/safe-browsing/search?url=X` means the shortener itself blocked the link. Return `matched`-like evidence (`blockedByShortener: X`) and also send `X` to Safe Browsing. The verdict layer (#12) decides between Dangerous and Be careful. It must never become Looks safe.
  - Don't scrape the preview HTML in version 1. The markup is undocumented and changes. Scraping TinyURL's preview page is an optional later improvement.

### 5. SSRF: which addresses to refuse, and how to pin the address in Node without dependencies

OWASP's SSRF cheat sheet ([link](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)) says to:
- validate the **resolved** IPs, not the hostname
- avoid the TOCTOU gap, because "A second, unchecked DNS lookup between validation and connection can bypass these checks". Connect to the validated IP while keeping the hostname for `Host`, SNI and certificate checks.
- disable automatic redirect following
- unmap IPv4-mapped and NAT64 addresses before checking
- block `169.254.0.0/16`, plus `metadata.google.internal` and AWS's `fd00:ec2::254`

What Node gives you without dependencies. Each item was checked against the v24 docs, the source, and local tests:

- `http.request` / `https.request` accept a `lookup` function (default `dns.lookup`), and "`options` in `socket.connect()` are also supported" ([http.md](https://github.com/nodejs/node/blob/v24.x/doc/api/http.md#httprequestoptions-callback)). `http.request` never follows redirects, so each hop is our own decision.
- `dns.lookup(host, {all:true}, cb)` returns `[{address, family}]`. Node's connect logic calls it with `all:true` because `autoSelectFamily` (Happy Eyeballs) is on by default since v20 ([net.md](https://github.com/nodejs/node/blob/v24.x/doc/api/net.md#socketconnectoptions-connectlistener), [dns.md](https://github.com/nodejs/node/blob/v24.x/doc/api/dns.md#dnslookuphostname-options-callback)). The custom lookup has to handle both the `all:true` and `all:false` callback forms.
- **Tested:** a `lookup` that resolves, rejects the whole answer if **any** address is blocked, and otherwise returns those same addresses blocks `http://localhost` and `https://localhost` (`::1` was returned and refused). Public hosts still work. The socket connects to an address from that same answer, with no second resolution, which closes the rebinding gap. TLS SNI and certificate checks still use the original hostname, because `https.request` derives `servername` from `host`.
- **Tested, a trap:** `lookup` is **not called when the host is an IP literal**. `http://127.0.0.1:port/` connected even with the blocking lookup in place. Every hop's hostname must be checked with `net.isIP()` (after removing IPv6 brackets) against the same rules before the request.
- **Tested, a trap:** the `blockList` socket option ([net.md `new net.Socket`](https://github.com/nodejs/node/blob/v24.x/doc/api/net.md#new-netsocketoptions)) is enforced at connect time for `http` (`ERR_IP_BLOCKED`, see `lib/net.js` `internalConnect`). It was **not** enforced for `https` in v24.14.1: `https://localhost` got as far as a TLS handshake. Don't rely on `blockList` alone. Use the custom lookup. Optionally pass `blockList` as well, as a second layer for http.
- `net.BlockList.check('::ffff:127.0.0.1','ipv6')` matches an IPv4 `127.0.0.0/8` rule (tested, and shown in the docs example). NAT64 `64:ff9b::a9fe:a9fe` did **not** match `169.254.0.0/16`, so NAT64 needs its own rule.
- The WHATWG `URL` parser already turns `0x7f.1`, `2130706433` and `017700000001` into `127.0.0.1` (tested). Always take the host from `new URL()`, never from the raw string.

**Address policy** (IANA special-purpose registries: [IPv4](https://www.iana.org/assignments/iana-ipv4-special-registry/), [IPv6](https://www.iana.org/assignments/iana-ipv6-special-registry/)):
- IPv4: refuse `0.0.0.0/8`, `10.0.0.0/8`, `100.64.0.0/10`, `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, `192.0.0.0/24`, `192.0.2.0/24`, `192.88.99.0/24`, `192.168.0.0/16`, `198.18.0.0/15`, `198.51.100.0/24`, `203.0.113.0/24`, `224.0.0.0/4` and `240.0.0.0/4`, which includes `255.255.255.255`.
- IPv6: **allow only `2000::/3`**, the global unicast range. That excludes `::1`, `::`, `::ffff:0:0/96`, `fc00::/7` (which covers `fd00:ec2::254`), `fe80::/10` and `ff00::/8` in one rule. Inside `2000::/3`, also refuse `2001::/32` (Teredo), `2001:db8::/32`, `2002::/16` (6to4, which can embed a private IPv4 address), `64:ff9b::/96` and `64:ff9b:1::/48`. The last two sit outside `2000::/3` already, but listing them makes the intent explicit.
- Hostnames: refuse names that end in `.internal`, `.local` or `.localhost`, refuse `localhost`, and refuse any name without a dot. This is cheap, and it fails before DNS.
- Ports: allow only 80 and 443. URLs with credentials (`user:pass@`) get `unresolved`, reason `credentials_in_url`.
- Schemes: a `Location` that isn't http(s) (`intent:`, `market:`, `sms:`, `tel:`, `javascript:`, `data:`) **stops expansion**. Report it as the destination string, with status `unresolved` and reason `non_web_destination`. The verdict layer may treat `intent:`/`data:` as Be careful.

### 6. Checking every hop with Safe Browsing

- A Lookup API `threatMatches:find` request "can include up to 500 URLs" ([Lookup API](https://developers.google.com/safe-browsing/v4/lookup-api)). Up to 9 URLs (the input plus 8 hops) fit in **one** request. Matches come back per entry in `threat.url`.
- The API is "for non-commercial use only", and commercial use belongs on Web Risk ([Usage limits](https://developers.google.com/safe-browsing/v4/usage-limits)). This was already true for the current gateway, and nothing here changes it. "clients must never use data older than what is specified by the service": only cache matches for their `cacheDuration`.
- **Recommendation:** start the Safe Browsing call for the **raw input URL straight away**, in parallel with expansion, so a known-bad short link returns fast. When expansion finishes, send one batch with the remaining hop URLs. Any hop matching means `matched`. The result is `noMatch` only when the expansion **completed** (no `unresolved`) **and** the batch call returned cleanly. Change the `match.threat?.url !== input` check to a membership check against the set of URLs sent.

### 7. Caching

- Render Free "spins down" after 15 minutes without traffic, takes about a minute to spin up, and "might restart a Free web service at any time" ([Render Free docs](https://render.com/docs/free)). Treat an in-memory cache as lost at any moment. That's fine here: it is a speed-up, not something correctness depends on.
- **Recommendation:**
  - `Map` cache of input URL → `{hops[], final, status, at}` with a **10-minute TTL** and at most **1000 entries** (evict the oldest by insertion order). Bitly and others let owners change where a link points, so long TTLs go stale.
  - Store Safe Browsing results per URL separately. Keep `matched` until its `expiresAt`, as the code does today. Keep `noMatch` for at most 5 minutes.
  - **Never cache** an `unresolved` result for longer than about 30 s. That short window only stops hammering. A slow hop now shouldn't become Couldn't check for the next 10 minutes.

### 8. Failure semantics

Expansion returns `{status:'expanded'|'unresolved', hops:[url…], final:url|null, reason?}`. Each of these yields `unresolved`:
- `timeout_hop`, `timeout_total`, `dns_error`, `blocked_address`, `blocked_port`, `tls_error`
- `too_many_hops`, `loop`, `non_web_destination`, `interstitial`, `js_redirect_on_shortener`
- `http_error` (a 4xx or 5xx before a non-shortener destination is reached)

The gateway response for any `unresolved` result must be the existing `unavailable` shape (HTTP 503), or a new 200 `{status:'unavailable', reason, hops}`, either of which the app maps to **Couldn't check**. Show the partial `hops` (the "Real destination so far") as information only. Make the app's verdict code treat `noMatch` as eligible for Looks safe **only if** `expansion.status === 'expanded'`. Add a unit test for that rule. Note that today's catch-all `catch → unavailable()` pattern in `reputation.mjs` already fails closed. Keep it that way in the expander.

One limit to note: phishing kits often show datacenter IPs (Render) a harmless page. Expansion reveals the destination **URL**, not what the user would see. A clean result means "no known threat on any hop". It does not prove the site is safe. #12 should weigh that.

## Recommended design (build-ready)

```
POST /v1/link-check {url}
  ├─ t=0  SB.lookup([input])                      (parallel, existing 5 s timeout)
  ├─ t=0  expand(input)  // ≤8 hops, 2.5 s/hop, 6 s total
  │        per hop:
  │          u = new URL(next); reject non-http(s), creds, port∉{80,443}, bad hostnames
  │          if net.isIP(host) → check policy; else lookup = safeLookup (resolve once, refuse if ANY addr bad)
  │          (http|https).request(u, {method:'GET', lookup, agent:false, timeout:2500,
  │              signal, headers:{'User-Agent':MOBILE_UA,'Accept':'text/html,*/*','Accept-Encoding':'identity'}})
  │          3xx+Location → resolve relative, res.destroy(), next hop
  │          200 text/html → read ≤64 KiB; Refresh header / meta refresh (delay ≤10 s) → next hop
  │          else stop: final = u
  │        stop on revisit (loop), on known-shortener 200 (interstitial), on non-web scheme
  ├─ SB.lookup(hops not yet checked)  // one batch, ≤500 entries
  └─ result: matched if any hop matched;
             unavailable (Couldn't check) if expansion unresolved OR any SB call unavailable;
             noMatch only if expanded && all SB calls clean.
             Always include {hops, final} so the app can show the Real destination.
```

Sketch of the address guard. This is about 30 lines with no dependencies. Treat it as a sketch for the implementer, not reviewed code:

```js
import net from 'node:net'; import dns from 'node:dns';
const deny = new net.BlockList();
for (const [n,p] of [['0.0.0.0',8],['10.0.0.0',8],['100.64.0.0',10],['127.0.0.0',8],['169.254.0.0',16],
  ['172.16.0.0',12],['192.0.0.0',24],['192.0.2.0',24],['192.88.99.0',24],['192.168.0.0',16],['198.18.0.0',15],
  ['198.51.100.0',24],['203.0.113.0',24],['224.0.0.0',4],['240.0.0.0',4]]) deny.addSubnet(n,p,'ipv4');
for (const [n,p] of [['2001::',32],['2001:db8::',32],['2002::',16]]) deny.addSubnet(n,p,'ipv6');
const global6 = new net.BlockList(); global6.addSubnet('2000::',3,'ipv6');
export const isPublicIp = (a, fam = net.isIP(a)) =>
  fam === 4 ? !deny.check(a,'ipv4') : fam === 6 && global6.check(a,'ipv6') && !deny.check(a,'ipv6');
export function safeLookup(host, opts, cb) {
  dns.lookup(host, {...opts, all:true}, (err, addrs) => {
    if (err) return cb(err);
    if (!addrs.length || !addrs.every(x => isPublicIp(x.address, x.family)))
      return cb(Object.assign(new Error('blocked_address'), {code:'EBLOCKED'}));
    opts.all ? cb(null, addrs) : cb(null, addrs[0].address, addrs[0].family);
  });
}
```

Note: an IPv4-mapped IPv6 address (`::ffff:a.b.c.d`) fails `global6`, so it is refused. That is acceptable, because `dns.lookup` returns native IPv4 for A records.

Tests to add with the build:
- the blocked-address list, including literal `127.0.0.1`, `[::1]`, `0x7f.1`, `169.254.169.254` and `[::ffff:169.254.169.254]`
- a local server that 302s to `127.0.0.1` (must be `unresolved`)
- a meta-refresh parser fed the HTML-spec forms
- a hop-limit loop
- an interstitial on a known shortener host
- "SB returns `{}` but expansion timed out", which must be `unavailable`

## Open questions for the map (#4 / #12)

- The verdict for `blockedByShortener` (cutt.ly to the transparency report): Dangerous or Be careful?
- The verdict for `non_web_destination`, for example `intent://…` that launches an APK install.
- Whether to send the hop list to the AI scan as context.

## Method

- Primary docs fetched: RFC 9110; the WHATWG Fetch and HTML Standards; Node v24 `http.md`, `net.md`, `dns.md`, `tls.md` and `lib/net.js` from `nodejs/node@v24.x`; the OWASP SSRF cheat sheet; the Google Safe Browsing v4 Lookup API and usage limits pages; Render's Free docs.
- Behaviour tests, run locally on Node v24.14.1:
  - `blockList` with http vs https
  - a custom `lookup` with http vs https and with a literal IP
  - `BlockList` with mapped and NAT64 addresses
  - `URL` normalization of odd IPv4 forms
- Shortener probes: one-off `fetch(..., {redirect:'manual'})` and `curl` runs from this machine on 2026-11-21, against public short codes, with no links created. Shortener behaviour can change at any time and may differ when requests come from Render's IPs.
