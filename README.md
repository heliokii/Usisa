# Usisa

Usisa is a Flutter Android app that helps people in the Philippines review suspicious messages, links, and screenshots. It provides local checks first, with optional AI and URL reputation checks through a separate gateway.

## Features

- Local message and link risk checks. Results are heuristic signals, not a guarantee that content is safe or malicious.
- Screenshot import with on-device text recognition (OCR); extracted text can be reviewed and edited.
- Optional AI review through the gateway, sent only with consent and after the text is reviewed.
- Optional Google Safe Browsing URL lookup, also requiring consent.
- Optional saved history and drafts, stored locally using encrypted storage.
- New app shell (rebuild in progress): Check home with four tiles and the Auto SMS protection card; History, Learn and Settings are placeholders for now.
- English and Filipino interface localization.
- Kotlin SMS receiver code is kept but switched off in the single build until it is wired in (ticket #40).

## What is complete and checked

The last recorded check covered the Android `manual` flavor: 98 Flutter unit/widget checks and four emulator integration checks passed, and `flutter analyze --no-pub` was clean. The checks covered the manual scan and storage flow, screenshot OCR, consented AI review, and consented Safe Browsing lookup.

Those results predate recent external edits to the generated localization files in `lib/l10n/`. Re-run analysis and checks before relying on them for a release.

## Unfinished or not verified

- SMS receiving and notification flows are switched off (`SMS_ENABLED=false`, no receiver in the manifest) and unverified.
- The Android picker recovery instrumentation test requires API 29 or newer; the available emulator was API 24. A physical Android device and iOS build have not been validated.
- Release builds sign with the key named in the git-ignored `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`; `storeFile` is relative to `android/`). Without that file they fall back to debug signing.
- Filipino safety copy still needs human review, and detection quality needs measurement against independently labeled Philippine examples. Risk results are heuristic.
- The gateway runs on Render's Free plan, which is not meant for production. See [server/README.md](server/README.md) for deploy, keep-alive and quota settings.
- There is no `LICENSE` file, so reuse and distribution terms are not specified.

## Requirements

- Flutter 3.47.5 and Dart 3.13.4 (the versions used for the recorded check).
- Android SDK and JDK 17 for Android builds; the app's minimum Android SDK is 24.
- Node.js 24 or newer only if running the optional gateway locally.

## Build and install

From the project root, fetch packages and run the app (there is one build, no flavors):

```sh
flutter pub get
flutter gen-l10n
flutter run
```

To build a debug APK and install it on a connected Android device or emulator:

```sh
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The application ID is `com.usisa.app`.

## Optional local gateway

The on-device checks and OCR work without the gateway. AI review and online URL reputation checks need it. Keep API keys on the gateway; do not put them in Flutter assets or Dart defines.

In PowerShell, copy `.env.example` to `.env` at the project root and fill in the server-side keys. Then start the gateway:

```powershell
Copy-Item .env.example .env
cd server
npm start
```

For the Android emulator, run the app with the host gateway URL:

```sh
flutter run --dart-define=USISA_GATEWAY_URL=http://10.0.2.2:8787
```

For a USB-connected device, run `adb reverse tcp:8787 tcp:8787` and use `http://127.0.0.1:8787` as `USISA_GATEWAY_URL`.

Environment variables, timeouts, rate limits, the Render deploy and the keep-alive pinger are documented in [server/README.md](server/README.md).

### Link check response

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

## Verification commands

```sh
flutter analyze --no-pub
flutter test --no-pub
```

The recorded check described above did not exercise SMS flows or API 29+ picker recovery. See [MOCK_TEST.md](MOCK_TEST.md) for synthetic sample content and [DESIGN.md](DESIGN.md) for the product design notes.