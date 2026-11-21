# Code audit: what non-UI code to keep (issue #8)

Audited commit `a862497` (main, 2026-11-21). Scope: `lib/features/scan` logic, `history_store.dart`, `settings_store.dart`, `server/*.mjs`. UI files (`*_screen.dart`) are out of scope, except where they decide the verdict or drive the online checks.

Note: this repo has no `CLAUDE.md` or `GLOSSARY.md` on main, so the terms below follow the code's own names.

## Short answer

- **Keep:** the gateway server, the strict response validation in both clients, the data models, the stores, and OCR.
- **Rewrite:** the local rules engine (`scam_analyzer.dart`). It flags normal texts and promos, and it treats a payment or code request plus a brand name as **high** risk.
- **Rework:** URL extraction (`url_checker.dart`). It turns ordinary words into "links".
- **Move out of the UI:** the code that combines local, link and AI results into one verdict. Today it lives in getters on `ScanResult` and in `result_screen.dart`.
- **Main causes of failing online checks:**
  - The client's 5 s link timeout is the same as the server's 5 s Safe Browsing timeout, so it leaves no margin.
  - The AI result is thrown away whenever the model's quote is not an exact substring of the text.
  - Every server-side failure becomes one generic "unavailable".
  - Global rate and daily limits are shared by all users.

## Evidence

| Check | Result |
|---|---|
| `cd server && npm test` (Node 24.14.1) | **15/15 pass** (about 5.5 s) |
| `flutter test --no-pub` | **Did not run.** The first attempt crashed the Flutter tool with `Bad state: No element` in `testCompilerBuildNativeAssets`, because the worktree had no `.dart_tool`. After `flutter pub get` it stopped with "Building with plugins requires symlink support. Please enable Developer Mode". That is a Windows system setting, and I did not change it. Re-run on a machine with Developer Mode on. |
| `dart run tool/evaluate.dart` | Crashes on a clean checkout: `PathNotFoundException ... docs/evaluation.md`, because `docs/` is not in the repo. With `docs/` created by hand it runs: **32 labelled, TP 14, FP 0, FN 6, TN 12; precision 100%, recall 70%, FPR 0%.** All 6 misses are paraphrases or Unicode/obfuscation cases (en05, fil04, tl05, uni01, uni04, uni05). |
| Ad-hoc probe of `ScamAnalyzer` with realistic PH texts (scratch script, not committed) | 9 of 14 benign or near-benign texts were flagged or marked "unchecked". See the false-positive section. |

The 0% FPR from the evaluator is not a real signal. Its 12 benign examples were written by the implementer and include no telco or shop promos, no legitimate OTP or "enter code" messages, and no casual Taglish with words like *agad*. The tool's own header says it is "not a real-world accuracy estimate" (`tool/evaluate.dart`, around line 45).

## Per-file verdict

| File | Verdict | Reason |
|---|---|---|
| `lib/features/scan/scam_analyzer.dart` | **Rewrite** | Five regexes. Any single match gives **caution** (`Finding` defaults to `RiskLevel.caution`, `scan_models.dart:30`). A code or payment request plus any brand word or urgency word gives **high** (`scam_analyzer.dart:77`). There is no Unicode normalization, no handling across line breaks (every rule uses `[^.!?\n]`), and only the first match per rule is kept. This logic causes most of the false positives below. Keep the input limits (empty, 10 000 runes) and the negation idea. |
| `lib/features/scan/url_checker.dart` | **Rework** | `parse`, `inspect`, the official-domain list and the shortener list are sound. `extract` is too greedy. The bare-domain regex accepts any `word.word` (`ok.salamat`, `report.pdf`), and the candidate regex matches a plain `data:` anywhere (`url_checker.dart:8`), so "2GB data:" becomes an `invalidLink` **caution**. `deceptiveHost` is a plain substring test (`host.contains(brand)`, line 128), so any host containing `sss`, `bpi`, `bdo` or `maya` is flagged. The domain comment cites `docs/domain-references.md`, which does not exist. |
| `lib/features/scan/scan_models.dart` | **Keep the data, move the verdict logic** | `Finding`, `LinkResult` and `ScanResult` with JSON are solid. The verdict getters (`localRisk`, `risk`, `hasUncheckedLinks`) belong in a separate verdict module, the subject of #12. `risk` takes the maximum of local, link and AI, so a lower AI result can never clear a false local alarm. A short link counts as "unchecked" forever, even after a `noMatch` (line 211). |
| `lib/features/scan/ai_models.dart` | **Keep** | Strict schema validation that fails closed, with a whitelist of models and codes. One change to consider: the exact-substring quote check (line 153) rejects the **whole** assessment if one quote differs (curly quotes, collapsed spaces, OCR noise). Drop the bad sign instead of the whole result, or normalize whitespace and quotes before comparing. |
| `lib/features/scan/ai_scan_client.dart` | **Keep, retune** | Cancellation, size cap and idempotency key are good. The 18 s timeout leaves only 3 s over the server's 15 s Groq timeout. Every failure (HTTP 503, validation error, timeout) becomes the same `unavailable`, with no reason given. |
| `lib/features/scan/reputation_client.dart` | **Keep, retune** | Validation is good: provider check, clock-skew check, expiry capped on the device. Bug: the request timeout is **5 s** (line 67) and the server's Safe Browsing call also times out at **5 s** (`server/reputation.mjs:17`). Any slow Google response plus the trip to Render ends as "Online check unavailable". The client also never calls `/v1/capabilities`, so a missing `SAFE_BROWSING_API_KEY` (server answers 503) looks exactly like an outage. |
| `lib/features/scan/gateway_readiness.dart` | **Keep, small fix** | The wake loop (an 80 s budget, a 5 s probe, retry on 502/503/504, a timeout or a Render HTML page) fits a free Render service that sleeps after 15 min idle and takes about a minute to wake (https://render.com/docs/free). Problem: `SocketException` (which the `http` 1.6.0 `IOClient` also throws as `_ClientSocketException`) and any other `ClientException` give up **at once** (lines 53-57), so one dropped mobile connection while the server wakes means "unavailable". Retry those too, inside the budget. Also, each link check runs its own wake loop (`result_screen.dart:666`, two at a time). |
| `lib/features/scan/scan_controller.dart` | **Keep (logic)** | The revision and cancel guards and the privacy-generation checks are correct. It has two separate entry points (`check` and `checkAi`). Link checks are not here at all: they run inside `result_screen.dart:592-700`. Move that into the controller or a service so the new UI does not inherit it. |
| `lib/features/scan/ocr_service*.dart`, `ocr_models.dart` | **Keep** | ML Kit Latin OCR with size and pixel caps and safe deletion of temp files. One effect on the analyzer: OCR output has a newline per line, and every rule stops at `\n`, so "Send your⏎OTP" in a screenshot is missed. The rewrite should join lines before matching. |
| `lib/features/history/history_store.dart` | **Keep** | Serialized writes, 30-day / 100-entry pruning, generation-guarded saves and a 24 h draft are all sound. Consequence to design for: it stores Safe Browsing results as `unavailable` (line 139), so every reopened history item with a link shows "Unknown" (`history_screen.dart:863`). That is intended privacy behaviour, but the verdict UI must explain it. |
| `lib/features/settings/settings_store.dart` | **Keep, small fix** | Simple and correct. `load()` calls `jsonDecode` with no try/catch (line 27), so a corrupt `settings` value crashes startup instead of falling back to defaults. |
| `server/index.mjs` | **Keep, retune** | Has body limits, CORS, an origin check, idempotent AI requests that coalesce duplicates, and aborts the provider call when the client disconnects. Two issues. (1) Rate limits key on `req.socket.remoteAddress` (line 59). Behind Render's proxy that is probably the proxy's address, so **all users share** 10 AI and 30 link requests per minute. The code's own comment says a public deployment needs trusted ingress limits. (2) `AI_DAILY_LIMIT` defaults to **50 calls per day for the whole service** (line 28). Both limits return a 429/503 that the app shows as "unavailable". Minor: `HOST` defaults to `127.0.0.1` (line 127), so Render must set `HOST=0.0.0.0`. This is not documented in the README. |
| `server/reputation.mjs` | **Keep** | Correct Safe Browsing v4 `threatMatches:find` call. An empty response means `noMatch`, not "safe", and match fields are validated. Raise the margin between its 5 s timeout and the client's timeout. Licensing check for #10 or #13: the Safe Browsing Lookup API is for non-commercial use; Web Risk is the commercial path. |
| `server/ai_scan.mjs`, `ai_schema.mjs` | **Keep** | Good prompt: it warns against brand-only and OTP-reminder false positives and treats input as untrusted. The schema is strict and model prose is thrown away. The `text.includes(evidence)` check in `validVerdict` makes the whole verdict invalid on a single quote mismatch (same issue as `ai_models.dart`). |
| `server/ai_evaluate.mjs`, `ai_smoke.mjs`, `*.test.mjs` | **Keep** | Dev tools and tests. All tests pass. |
| `tool/evaluate.dart` | **Keep, fix** | Useful harness, but it writes to a `docs/` folder that is missing on a clean checkout, and the fixture set needs real promos and legitimate OTP messages (see #7 and #13). |

## What concretely causes false positives

Each case below was reproduced with the current `ScamAnalyzer` (`rules-v1`):

| Text (abridged) | Result | Cause |
|---|---|---|
| `Pay with GCash today and get FREE delivery on your first order!` | **high** | `paymentRequest` matches "pay ... delivery", and "GCash" is a brand word, so it is escalated to high. |
| `Your GCash order is confirmed. Enter the verification code 482913 ...` | **high** | `codeRequest` matches "enter ... verification code". Legitimate OTP-entry messages look like this. |
| `GoSURF50: 2GB data: valid for 3 days.` | caution | `data:` is extracted as a URL scheme and becomes an `invalidLink` caution. |
| `Mom, I will transfer the money for the rent tomorrow.` | caution | `paymentRequest` matches "transfer ... money". |
| `Uwi ka agad pagkatapos ng klase ha.` | caution | *agad* ("right away") counts as urgency. |
| `Your account was blocked ... Visit a BPI branch.` | caution | *blocked* counts as urgency, with no link and no request. |
| `Hi Ma, pa-send naman ng pera pang tuition, need ko agad.` | **high** | Payment plus urgency gives high. A real family request gets the same result as a scam. |
| `Sige, ok.salamat po.` / `notes in report.pdf` | low, but shown as **Unknown** | `ok.salamat` and `report.pdf` are extracted as links. They are unchecked, so the banner switches to "unknown status" (`result_screen.dart:1484`). |
| `Visit http://example.org ...` | caution | Any plain `http://` link gives a caution. |

Correctly not flagged: "Never share your OTP..." and "Your GCash OTP is 123456. Do not share..." (the negation check works).

Root causes:
1. One weak cue is enough for caution. The rules never weigh signals together.
2. A brand word is enough to escalate to high. The AI prompt explicitly says a brand name alone is not impersonation, but the local rules do the opposite.
3. The verbs are too broad: "pay", "transfer", "enter" and "send" all count.
4. The URL extractor accepts `word.word` and a plain `data:`.
5. The final risk is a maximum of all sources, so AI or a link `noMatch` can never lower a local false alarm.

## What causes wrong verdicts

- **Escalation logic** (above): normal requests become **high**.
- **Pseudo-links make a result "Unknown"**: any result with low risk and an unchecked link shows the Unknown banner, even when the link is just `ok.salamat`.
- **Banner message vs title**: when links exist, `bannerMessage` reports link status ("unknown link" or "not listed") instead of the risk explanation, even if the title says High (`result_screen.dart:1503-1510`).
- **Reputation decays**: a `noMatch` turns into `unavailable` after 5 min (`scan_models.dart:83-108`), and history never keeps Safe Browsing results. Reopening a result changes its banner.
- **AI can only raise risk**: an AI `low` cannot clear a local false positive, while an AI false positive does raise the risk.
- **Misses**: paraphrases, homoglyphs, zero-width characters, short links (evaluator FN = 6/20), and requests split across OCR line breaks.

## What causes failing online checks

1. **No timeout margin on link checks**: the client gives up at 5 s, exactly when the server's Safe Browsing call times out (`reputation_client.dart:67` vs `server/reputation.mjs:17`). The time to reach Render from the Philippines comes on top.
2. **Cold start**: a free Render service sleeps after 15 min idle and takes about a minute to wake. The 80 s wake loop covers it, but **gives up at once on any socket or client exception** (`gateway_readiness.dart:53-57`). The user also waits up to 80 s with only a spinner. Keeping the service awake is #10.
3. **Shared limits**: per-IP limits behind the Render proxy, and 50 AI calls per day for the whole service, give 429/503, which the app shows as "unavailable".
4. **AI rejected on quote mismatch**: if one warning-sign quote is not an exact substring, the whole AI result is discarded on the server (`ai_schema.mjs`) or in the client (`ai_models.dart:153`). Screenshot text makes this more likely.
5. **One error state for everything**: missing key, rate limit, daily cap, timeout and validation failure all become `unavailable` with the message "Try again later". `/v1/capabilities` exists but is never called, so configuration problems are never shown.

## Recommendations for the rebuild (#15, #12)

- Carry over unchanged: `ai_models.dart`, `ai_scan_client.dart`, `reputation_client.dart`, `gateway_readiness.dart`, `ocr_service*`, `history_store.dart`, `settings_store.dart`, and the data parts of `scan_models.dart`. Apply the small fixes listed above.
- Carry over all of `server/`. Then retune the timeouts (for example, client 8-10 s for a link check against the server's 5 s), key rate limits on a trusted `X-Forwarded-For`, raise or make visible the AI daily cap, return a reason code with each 503, and document `HOST=0.0.0.0`.
- Rewrite: a scoring rules engine that needs several signals together, with no escalation from a brand word alone, Unicode normalization, joined lines, and narrower verbs. Also rewrite URL extraction (a known-TLD list or a scheme or `www.` prefix, and no plain `data:`). Measure against a fixture set that includes real promos, OTP messages and family requests.
- New: a pure verdict function that combines local, link and AI results outside the UI. That is #12.

Not verified: behaviour on a real device or a live Render deployment, Flutter widget and unit tests (blocked by symlinks), and exactly what `remoteAddress` shows behind Render's proxy.
