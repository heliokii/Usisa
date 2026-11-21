# Keeping the free Render gateway awake

Research for heliokii/Usisa#10. Sources checked 2026-11-21. The gateway is `https://usisa-gateway.onrender.com/` (Render Free web service, branch `codex/usisa-gateway`, `GET /healthz` returns `{"status":"ok"}`).

## Answer

Yes. A pinger that hits `/healthz` every 10 minutes keeps one free service awake, and one always-on service uses less than the 750 free hours a month. Render's docs don't forbid keep-alive pings, but they don't allow them either. Two things still apply: Render says Free instances are not for production, and the gateway can still go down at any time. The app has to treat the gateway as best-effort and show **Couldn't check** whenever the gateway is slow or unreachable.

## Render Free plan facts

All quotes are from https://render.com/docs/free unless another source is named.

| Question | Finding |
|---|---|
| Idle spin-down | A Free web service spins down after it "goes 15 minutes without receiving any inbound traffic". Inbound HTTP requests and WebSocket messages both count as traffic. |
| Cold start | Spin-up "takes about one minute". Browsers get a loading page while they wait. |
| Measured cold start | We measured it on 2026-11-21 (3 sequential `GET /healthz`). The first request took **17.4 s** (the service was asleep). The next two took 0.11 s and 0.10 s. The first response came back as HTTP 200 after the wait, not as an error. The response passes through Cloudflare (`server: cloudflare`, `x-render-origin-server: Render`). |
| Free hours | "Render grants 750 Free instance hours to each workspace per calendar month." Hours are counted **per workspace**, not per service, and unused hours don't roll over. |
| Does one always-on service fit? | Yes. A 31-day month has 744 h, which is under 750. A second always-on Free service in the same workspace would run out of hours mid-month. When hours run out, "Render suspends all of your Free web services until the start of the next month." |
| Production use | "Do not use them for production applications." |
| Bandwidth / build minutes | Free services use the workspace's included outbound bandwidth and build minutes. If bandwidth runs out and there is no payment method, Render suspends all Free services for the rest of the month. If build minutes run out, new builds are disabled but running services keep going. |

## Do Render's terms permit keep-alive pinging?

Nothing explicitly allows it or forbids it.

- https://render.com/docs/free doesn't mention keep-alive pings. The traffic clause there is about traffic a service *initiates*: Render "may suspend a Free web service that initiates an uncommonly high volume of traffic over the public internet". An inbound ping every 10 minutes is not outbound traffic.
- The Acceptable Use Policy (https://render.com/acceptable-use) forbids attempts to "bypass, circumvent, or defeat any access or usage restrictions". It also forbids misusing the Service "to avoid payment or financial responsibility". Render could read a pinger that defeats spin-down as falling under either clause. We found no statement from Render that it enforces them this way. Pinging uses up the free hours Render grants and stays inside the 750-hour limit.
- **Risk:** this is a grey area. The documented downside is suspension. For anything beyond a pilot, the clean option is a paid instance (the Starter plan has no spin-down).

## Other causes of downtime or slowness

- **Random restarts.** "Render might restart a Free web service at any time." (https://render.com/docs/free)
- **Maintenance.** Free services get no advance notice. Render "might perform maintenance on a free service at any time". Stateless services "remain available during maintenance windows" because Render starts new instances before removing the old ones. (https://render.com/docs/platform-maintenance)
- **Deploys.** "All service types redeploy with zero downtime, unless they attach a persistent disk." Traffic stays on the old instance until the new one is ready. The old instance gets SIGTERM 60 s later. (https://render.com/docs/deploys) The Free page doesn't list Free as an exception, but we haven't verified this on Free. A deploy that fails to boot leaves the old instance serving.
- **Ephemeral filesystem.** Local files are lost on every redeploy, restart or spin-down. The gateway is stateless, so this doesn't matter, as long as caches and rate-limit state are treated as disposable.
- **Hours or bandwidth running out.** Either one suspends every Free service until the next month (see the table above).
- **Pinger gaps.** If the pinger misses one run, the service can sleep. The next user then waits for a cold start.

## Pinger options

| Option | Free? | Interval | Reliability notes | Source |
|---|---|---|---|---|
| **cron-job.org** (recommended) | "entirely free of charge" | Down to 1 min | Each request gets a 30 s timeout. A job is auto-disabled after more than 25 failures in a row. Jobs that fail often may be delayed. Fair-use policy. | https://cron-job.org/en/faq/ |
| **UptimeRobot** Free | Yes, 50 monitors, "personal and commercial projects" | 5 min | Also sends downtime alerts, which is useful for spotting suspensions. | https://uptimerobot.com/pricing/ |
| **GitHub Actions `schedule`** | Free minutes (unlimited for public repos) | Minimum 5 min | Runs "can be delayed during periods of high loads" and "some queued jobs may be dropped". In public repos, scheduled workflows are auto-disabled after 60 days with no repo activity. **Not reliable enough to be the only pinger.** | https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows |

**Recommendation:** run cron-job.org every **10 min** on `GET /healthz`, which leaves a 5-minute margin under the 15-minute spin-down. Add UptimeRobot at 5 min as a second pinger and alert source. Both are free, and two independent pingers cover each other's gaps. Ping only `/healthz`, never the AI or link-check endpoints, so pings don't use any upstream API quota.

## Client-side behaviour (Flutter)

What the code does today, on `main`:

- `lib/features/scan/gateway_readiness.dart` `waitForGateway()` polls `/healthz` before each gateway call. It has an 80 s budget, a 5 s per-probe timeout and a 4 s interval. It retries on timeout, 502/503/504 or an HTML 200 (Render's spin-up page), and gives up immediately on `SocketException` or `ClientException`.
- `ai_scan_client.dart` then allows 18 s for the POST.
- `reputation_client.dart` allows 5 s.
- Every failure path returns the `unavailable` state.

This design is already right. Recommended refinements:

1. **Warm-up ping on app open.** As soon as the app reaches the foreground, fire one `GET /healthz` without awaiting it, with a 60 s timeout and the result ignored. A cold start (17 s measured, up to about 60 s documented) then overlaps with the user typing or pasting, instead of starting when they tap Scan. Never block UI on it, and never surface its result.
2. **Timeouts.**
   - Connect timeout: about 10 s. Use `HttpClient.connectionTimeout` through `IOClient` if a separate connect limit is wanted. Today only the overall `.timeout()` applies.
   - Health probe: keep 5 s per probe inside the loop.
   - Readiness budget: about 60–80 s total. Render documents about 1 min, so 80 s is acceptable. Consider showing "Waking the checker…" after about 3 s so the wait is visible.
   - Request read timeout: 18 s for AI and 5 s for link-check, both measured *after* readiness succeeds.
3. **Retries.**
   - Retry only the idempotent health probe, and only on timeout, 502/503/504 or HTML responses (current behaviour).
   - Don't auto-retry the scan POST. If the AI POST must ever be retried, retry once at most, and reuse the same `Idempotency-Key` (today a new key is generated per `_request`).
   - Consider one retry on `SocketException` during readiness. A restart or instance swap can briefly reset connections. Today the loop gives up immediately.
4. **How results map to the verdict (hard rule).** The following always end in **Couldn't check**, never in a hang and never in **Looks safe**:
   - a timeout
   - any non-200 status
   - a non-JSON or HTML body
   - an oversized body
   - a stale or missing `checkedAt`
   - a failed readiness check
   - a user cancel

   Only a well-formed, fresh `noMatch` from the gateway may count toward a positive result. The current `unavailable` returns already do this. Keep a unit test for each of these paths, using a fake `http.Client` that hangs, returns 503 or returns HTML, so a refactor can't silently turn one of them into "safe".
5. **Cancellation.** Keep the `AbortableRequest` plus abort-trigger pattern so that leaving the screen cancels in-flight probes and requests.

## Not verified

- Whether zero-downtime deploys apply on the Free plan. The docs don't list Free as an exception.
- Whether Render enforces the AUP against keep-alive pingers.
- Cold-start time across multiple samples. Only one sample was taken.
