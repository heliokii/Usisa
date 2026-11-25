# Usisa gateway

A plain `node:http` server (Node 24 or newer, no npm dependencies). It holds the API keys so the app never does. Endpoints: `GET /healthz`, `GET /v1/capabilities`, `POST /v1/ai-scan`, `POST /v1/link-check`.

`POST /v1/ai-scan` takes `{text, responseLanguage: "en"|"fil", links?}`, where `links` (up to 5) is `[{url, destination, hops}]` copied from `/v1/link-check` results so the model sees where each link really goes. A warning sign whose quote is not in `text` is dropped; the answer is rejected only if a caution/high verdict is left without any quote.

```sh
npm start   # loads ../.env if it exists
npm test
```

## Link check response

`POST /v1/link-check {"url": "..."}` follows the link's redirects on the gateway (GET only, at most 8 hops, 2.5 s per hop, 6 s total, ports 80/443, internal addresses refused), then sends the raw link and every hop to Safe Browsing in one call. A finished check answers HTTP 200 with:

| Field | Meaning |
|---|---|
| `status` | `matched` (some URL is flagged), `blockedByShortener` (the shortener itself refused the link), `noMatch` (every hop followed and none flagged; not proof of safety), `unavailable` (Couldn't check) |
| `destination` | Real destination URL, or `null` when it is unconfirmed. For `non_web_destination` it is the non-web link (for example `intent://...`) |
| `hops` | Every URL reached after the submitted one, in order. Partial when unfinished: show it as "so far" only |
| `expansion` | `expanded`, `blocked` or `unresolved` |
| `reason` | Only when `expansion` is `unresolved`: `timeout_hop`, `timeout_total`, `dns_error`, `blocked_address`, `blocked_port`, `credentials_in_url`, `fetch_error`, `http_error`, `too_many_hops`, `loop`, `non_web_destination`, `interstitial` (stopped on a shortener's preview page) |
| `blockedUrl` | Only with `blockedByShortener`: the link the shortener blocked |
| `flaggedUrls`, `threatTypes`, `expiresAt` | Which URLs Safe Browsing flagged, the threat types, and until when the match may be used |
| `checkedAt`, `provider` | Check time and `Google Safe Browsing` |

A flagged hop wins over an unfinished expansion. Anything other than `noMatch` must never show as Looks safe. HTTP 503 `{"error":"unavailable"}` still means the gateway is not configured or busy. Results are cached in memory: chains 10 min, clean results 5 min, unfinished chains 30 s.

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `GROQ_API_KEY` | none | Turns on AI review. |
| `GROQ_MODEL` | none | Must be on the allow-list in `ai_scan.mjs`, for example `openai/gpt-oss-120b`. |
| `SAFE_BROWSING_API_KEY` | none | Turns on link checks. |
| `AI_DAILY_LIMIT` | `50` | Total AI calls per UTC day across all users. Once it is reached, AI review answers `503 unavailable` and the app falls back to local checks. Raise it for demos. |
| `HOST` | `127.0.0.1` | The address to listen on. **Set `0.0.0.0` on Render**, or Render can't reach the service. |
| `PORT` | `8787` | Render sets this itself. |
| `ALLOWED_ORIGIN` | empty | The one browser origin allowed to call the gateway (the web preview). Requests from the Android app send no `Origin` and are unaffected. |
| `RENDER` | set by Render | When it is `true`, the gateway takes the client address from the `CF-Connecting-IP` header (see below). Don't set it yourself. |

## Rate limits

Limits are counted per client address: 10 AI checks and 30 link checks per minute.

- **On Render** (`RENDER=true`) the client address is `CF-Connecting-IP`. Cloudflare sits in front of every Render web service and overwrites that header on each request, so a caller can't choose their own bucket. `X-Forwarded-For` is ignored, because Render only appends to it and the caller controls its left side.
- **Locally**, or anywhere else, the gateway uses the socket peer address and ignores forwarded headers.

Rate-limit counters live in memory, so a restart or a Render spin-down resets them.

## Timeouts

Each gateway answer has a server deadline that ends before the app gives up. A slow upstream therefore comes back as a clean `503 unavailable` ("Couldn't check"), not as a client timeout.

| Path | Upstream limit | Gateway deadline (`TIMEOUTS` in `index.mjs`) | App request timeout |
|---|---|---|---|
| `POST /v1/ai-scan` | Groq 15 s | 16 s | 18 s (`ai_scan_client.dart`) |
| `POST /v1/link-check` | redirects 6 s total (2.5 s per hop), Safe Browsing 5 s | 8 s | 10 s (`reputation_client.dart`) |
| Receiving a request (headers and body) | n/a | 10 s (`requestTimeout`) | n/a |

The app's readiness probe (`gateway_readiness.dart`, up to 80 s for a cold start) runs before these timeouts start. `gateway_ops.test.mjs` fails if a gateway deadline comes within 1 s of the app's timeout, so raise both sides together.

## Deploying on Render

The gateway runs as a Render **Free** web service at https://usisa-gateway.onrender.com/.

1. In the Render dashboard, open the service. Under **Settings**, set **Branch** to `main`, **Root Directory** to `server`, **Build Command** to empty, and **Start Command** to `node index.mjs`.
2. Under **Environment**, set `HOST=0.0.0.0`, `GROQ_API_KEY`, `GROQ_MODEL`, `SAFE_BROWSING_API_KEY` and, if wanted, `AI_DAILY_LIMIT`. Keys are only ever stored here, never in the repo.
3. Keep **Auto-Deploy** on, so each merge to `main` deploys. The old `codex/usisa-gateway` branch is retired; don't deploy from it.
4. Check the deploy: `curl https://usisa-gateway.onrender.com/healthz` returns `{"status":"ok"}`, and `/v1/capabilities` shows which checks are configured.

Free plan limits to keep in mind: the service sleeps after 15 minutes with no inbound traffic, and the first request after that waits for a cold start (17 s measured, up to about 1 minute documented). The workspace gets 750 free instance hours a month, which is enough for **one** always-on service. Render can restart a Free service at any time and says Free is not for production.

## Keep-alive

An external pinger stops the service from sleeping. Ping only `/healthz`, never the AI or link-check endpoints, so pings use no API quota.

**cron-job.org (main pinger)**

1. Create a free account at https://cron-job.org.
2. Create a cronjob with URL `https://usisa-gateway.onrender.com/healthz`, method `GET`, and an every-10-minutes schedule. That leaves 5 minutes of margin under the 15-minute spin-down.
3. Turn on failure notifications. cron-job.org disables a job after more than 25 failures in a row, so re-enable it after any outage.

**UptimeRobot (backup pinger and alerts)**

1. Create a free account at https://uptimerobot.com.
2. Add an **HTTP(s)** monitor for `https://usisa-gateway.onrender.com/healthz` with a 5-minute interval.
3. Add an email alert contact. An alert usually means a crash, a suspension, or the monthly hours or bandwidth running out.

Render's terms neither allow nor forbid keep-alive pings, so it is a grey area. For anything beyond a pilot, use a paid instance; it doesn't sleep. The app still treats the gateway as best-effort and shows "Couldn't check" when it is slow or unreachable. The research behind this is on the `research/render-keepalive` branch.
