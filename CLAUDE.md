# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Usisa is a Flutter Android app (English/Filipino) that checks suspicious messages, links, screenshots and incoming texts for scams in the Philippines. The phone check runs first and works offline. The online link check (Google Safe Browsing, after redirects) and AI review (Groq) are optional and consent-gated, and go through a separate Node gateway in `server/`. API keys live only on the gateway (`.env` at repo root), never in Flutter assets or `--dart-define`. Vocabulary (Check, Verdict, Looks safe / Be careful / Dangerous / Couldn't check, Harmless promo...) is in `GLOSSARY.md`; UI direction in `DESIGN.md`.

## Commands

Flutter 3.47.5 / Dart 3.13.4, JDK 17, Android minSdk 24. There is one build: no flavors. Application ID `com.usisa.app`.

```sh
flutter pub get
flutter gen-l10n                          # regenerate lib/l10n/app_localizations*.dart after editing .arb files
flutter analyze --no-pub
flutter test --no-pub                     # all unit/widget tests
flutter test --no-pub test/check/check_pipeline_test.dart                       # one file
flutter test --no-pub test/check/check_pipeline_test.dart --plain-name "<name>"  # one test
flutter test --no-pub tool/evaluate.dart  # phone-only Quality bar evaluation; fails on a missed target on the sealed split
dart run tool/release_gate.dart           # release gate: analyze + tests + phone-only evaluation, non-zero on any miss
flutter run --dart-define=USISA_GATEWAY_URL=http://10.0.2.2:8787   # emulator -> local gateway
flutter build apk --debug
flutter build apk --release               # needs android/key.properties (project key); fails without it, see RELEASE.md
cd android && ./gradlew :app:testDebugUnitTest   # Kotlin unit tests
```

USB device: `adb reverse tcp:8787 tcp:8787` and use `http://127.0.0.1:8787`.

The evaluation runs under `flutter test` (the Check pipeline imports Flutter). The labelled set is `test/fixtures/evaluation/` with a sealed 70/30 split by template (`tool/evaluation.dart`). Tune on the development split only; never weaken targets or move messages to pass. The combined (link check + AI) run is manual, see `RELEASE.md`.

Gateway (Node >= 24, no npm dependencies), deployed at https://usisa-gateway.onrender.com/ (deploy, keep-alive, quotas in `server/README.md`):

```sh
cd server && npm start      # loads ../.env (GROQ_API_KEY, GROQ_MODEL, SAFE_BROWSING_API_KEY)
cd server && npm test       # node --test *.test.mjs
```

## Architecture

- **Entry/shell**: `lib/main.dart` -> `UsisaApp` in `lib/app.dart`, which owns the shared settings, History and SMS service and builds the tab shell (Check home, History, Learn, Settings). Dependencies are injectable (`storage`, `runCheck`, `gatewayClient`, `readScreenshot`, `shares`, `sms`); widget tests pass `MemoryStorage` and fakes. On web (`kIsWeb`) the app uses in-memory storage.
- **Check pipeline** (`lib/features/check/`): `CheckPipeline.run(CheckInput)` in `check.dart` is the main seam. It reads screenshot text (OCR) if needed, runs the phone check, then optionally the online link check (`gateway_link_checker.dart`) and AI review (`gateway_ai_checker.dart`, over `lib/features/scan/ai_scan_client.dart`), and returns one `Verdict`. `phone_check.dart` is pure Dart on purpose: the background SMS entry point runs it with no UI. A link that isn't checked is never Looks safe. Screens: home, paste, screenshot, AI scan, consent, verdict; `share_source.dart` takes content shared in over `usisa/share`.
- **Storage**: `PrivateStorage` in `lib/features/history/history_store.dart` with `SecureStorage` (flutter_secure_storage) and `MemoryStorage`. `HistoryStore.generation` is a privacy counter: clearing History bumps it, and in-flight results from an older generation are discarded.
- **Gateway** (`server/index.mjs`): plain `node:http` server exposing `/healthz`, `/v1/capabilities`, `POST /v1/ai-scan`, `POST /v1/link-check`, with per-IP rate limiting, body size limit, idempotency keys, origin allow-list (`ALLOWED_ORIGIN`) and `AI_DAILY_LIMIT`. `ai_scan.mjs` calls Groq with a fixed `promptVersion` and model allow-list; `ai_schema.mjs` validates the model output and defines the warning/recommendation codes the app localizes. Changing those codes requires matching changes in `lib/features/scan/ai_models.dart` and the `.arb` files.
- **SMS (in the single build)**: the manifest declares `RECEIVE_SMS`; the user turns it on with Auto SMS protection on the home card. Kotlin side (`android/app/src/main/kotlin/com/example/usisa/`): `SmsReceiver` -> `PendingSmsStore` -> `SmsCheckWorker`, which boots a headless Flutter engine at the Dart entry point `usisaSmsBackground` (`@pragma('vm:entry-point')` in `main.dart`, implemented in `lib/features/sms/sms_background.dart`) over channel `usisa/sms_worker`. `SmsPolicy` and `SmsAlerts` decide and post the notification. The foreground app talks to `SmsBridge` over `usisa/sms`. End-to-end SMS still needs the manual emulator check in `README.md`.
- **Localization**: source of truth is `lib/l10n/app_en.arb` / `app_fil.arb` (`l10n.yaml`); the generated Dart files are committed. Every user-facing string ships in both. Filipino safety copy still needs human review.

## Notes

- Verdicts are heuristic; UI copy must not claim content is definitely safe or malicious.
- Release builds are signed with the project key from the git-ignored `android/key.properties`; there is no debug-key fallback. Release steps and the demo-day checklist are in `RELEASE.md`.
- `MOCK_TEST.md` has synthetic sample scam content for manual testing.
