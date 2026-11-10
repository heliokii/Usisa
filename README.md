# Usisa

Flutter/Dart scam checks for messages and links in the Philippines. The app explains potential warning signs in English and Filipino and accepts English, Filipino and Taglish input.

The local manual app, sideloaded SMS Lab and optional Groq AI assistance are implemented for the development MVP and tested on an Android emulator. Live URL checks use Google Safe Browsing for the confirmed noncommercial research scope. Physical-phone validation remains open. No detection method guarantees authenticity or catches every scam.

## Current capabilities

- Local text and HTTP(S) URL checks with evidence and practical safety advice.
- Optional AI assistance for reviewed text, links and OCR text. Every submission has an editable outbound preview and confirmation. Independent local/AI findings retain the stronger warning. AI failure/cancellation keeps local checks usable; automatic SMS stays local.
- Android/iOS screenshot selection, bundled on-device Latin OCR and editable review before scanning. Offline Android emulator tests cover image bounds, failures and picker Activity recovery; physical-phone and iOS runtime validation remain open.
- Optional encrypted history (latest 100 scans, review access expires after 30 days), a separate draft restorable within 24 hours, local search/filters and protected deletion. Both start off. Expired files are cleaned while the app runs or on next use; closed/stopped apps cannot erase at an exact deadline. Cleanup failures are shown.
- English/Filipino interface, system/light/dark appearance, compact bottom navigation and wider navigation rail using the 60:30:10 palette.
- Optional URL-reputation gateway with separate consent, Google attribution, expiry-aware warnings and no provider key in the app. Live threat/no-match checks have passed through the Android emulator and gateway. Saved history keeps local findings and check metadata without caching Safe Browsing verdicts.

Browser previews use memory only. OCR and automatic SMS are native capabilities; a browser render does not prove them.

## Run the mobile app

Use Flutter 3.47.5 / Dart 3.13.4 or a compatible newer toolchain. Android minimum SDK is 24; the resolved OCR wrapper bundles the Latin recognizer. Keep the checked-in lockfile.

Runtime checks now cover API24 and API35 emulators. On Android 7.0/API24, encrypted storage/manual scanning, offline OCR, three encrypted SMS queue tests, an incoming SMS after process removal, cold notification routing and manually confirmed live AI all passed. These checks do not replace carrier, physical-phone or human accessibility validation.

The optimized SMS Lab release build also passed offline OCR with editable review, headless incoming SMS and cold notification routing on API35. Release rules preserve ML Kit's reflectively loaded constructors and suppress only the unbundled optional script classes. APK signing verification and static 16 KB ZIP/native-library alignment checks pass; a 16 KB runtime device has not been tested. Release builds still use the development signing key and are for validation only.

```powershell
flutter pub get
flutter gen-l10n
flutter run
```

For the portable browser preview:

```powershell
flutter run -d chrome
```

This worktree has a locally installed SDK under `.toolchain/android-sdk`, excluded from Git. To use it for Android builds in PowerShell:

```powershell
$env:ANDROID_HOME = (Join-Path (Get-Location) '.toolchain/android-sdk')
flutter build apk --debug --no-pub
```

The default flavor is `manual`; its APK is `build/app/outputs/flutter-apk/app-manual-debug.apk`. It omits restricted SMS permissions and the receiver.

For the user-selected sideloaded SMS development build:

```powershell
flutter build apk --debug --flavor smsLab --no-pub
flutter run --flavor smsLab
```

SMS APK: `build/app/outputs/flutter-apk/app-smslab-debug.apk`, development ID `com.example.usisa.smslab`. The two flavors install separately. These use development signing and are not public/store releases. Release identity/signing, physical-device calibration and Google Play eligibility remain gates.

In SMS Lab, open Settings → Incoming SMS checks and confirm the disclosure before Android asks for RECEIVE_SMS. Review notifications have their own enable action. No READ_SMS, SEND_SMS, notification listener, inbox scan or third-party conversation access is requested. Android's permission-group wording can be broader than the actual RECEIVE_SMS permission.

Authenticated system receipt queues encrypted event references, and WorkManager invokes the same Dart rules in a headless Flutter engine. Checks work without an open Activity but Android can delay them. Force-stop prevents receipt; reopening does not replay the inbox. Caution/high results produce generic private alerts; low results stay quiet. The Recent SMS reviews screen works with notifications denied. Temporary review access expires after 15 minutes, with a maximum of 20 events. Cleanup is scheduled and also runs on queue access; Android may delay physical deletion. Disabling SMS or Clear saved data invalidates workers, erases temporary records and cancels alerts. History and private drafts are independent opt-ins.

## Optional URL-reputation gateway

The small Node 24+ gateway holds provider credentials. It does not fetch submitted sites or follow their redirects. It sends only consented URLs to the fixed Google Safe Browsing v4 Lookup API, with input limits, timeouts, rate/concurrency limits, no raw URL logs and no persistent response cache. Safe Browsing is free for noncommercial use; reassess licensing before revenue-generating use.

Enable **Safe Browsing APIs** in the Google project and set `SAFE_BROWSING_API_KEY` in the worktree-root `.env` for the server. For browser development, also set `ALLOWED_ORIGIN` to the exact preview origin; do not use a wildcard. Missing provider configuration reports unavailable. Keys stay on the server.

```powershell
cd server
npm start
```

The server binds to loopback on port 8787 by default and explicitly loads `../.env` if present. A public deployment needs TLS, trusted ingress abuse controls and suitable quotas; none is deployed by this change.

The free-provider migration is implemented; see `docs/free-url-providers.md` and `docs/provider-validation.md`. Existing Web Risk consent is reset for re-consent. Current Google warnings expire within the returned lifetime or five minutes, whichever is sooner. Small server/device clock differences are handled without extending the lifetime. Legacy Web Risk records retain their original source; no Web Risk calls remain.

Supply only the public gateway URL to Flutter, for example:

```powershell
flutter run -d chrome --dart-define=USISA_GATEWAY_URL=http://127.0.0.1:8787
```

For Android emulator development, run `flutter run --flavor manual --no-pub --dart-define=USISA_GATEWAY_URL=http://10.0.2.2:8787`. Release gateways must use HTTPS. Builds made without `USISA_GATEWAY_URL` show that configuration is needed; provide the deployment URL when building an online-enabled APK. The server's allowed browser origin and this gateway URL are different settings.

## Optional AI assistance

Set server-only `GROQ_API_KEY` and `GROQ_MODEL=openai/gpt-oss-120b` in the worktree-root `.env`, then use the same gateway URL above. The current local configuration has passed synthetic live inference and native Android review/confirmation. `/v1/capabilities` advertises AI independently of URL reputation; missing or unsupported model configuration remains unavailable. No automatic model switch occurs. Never add `.env` to Flutter assets or pass keys through Dart defines. The user-owned `.env.example` is left untouched.

Choose **AI assisted**, review/edit the exact text, then confirm **Send this text for AI check**. Only that text and response language go to Usisa’s gateway and Groq. Names, codes, numbers and links inside the text are included unless edited out. Images and separately collected sender metadata are excluded. URL-check consent does not authorize AI. Groq retention depends on account data controls; zero retention is not assumed. See [Groq data controls](https://console.groq.com/docs/your-data).

The combined development handoff is `build/mvp/Usisa-MVP-SMS-AI.apk`, with local SMS plus manual AI and URL reputation. It uses `http://127.0.0.1:8787` through `adb reverse tcp:8787 tcp:8787`, allowing emulator or USB-connected phone development while the gateway stays on the computer. Setup and feature walkthrough: `build/mvp/HANDOFF.md`. Rebuild with `flutter build apk --debug --flavor smsLab --no-pub --dart-define=USISA_GATEWAY_URL=http://127.0.0.1:8787`.

The older emulator-enabled builds are `build/mvp/app-smslab-ai-dev-debug.apk` (automatic local SMS plus manual AI) and `build/mvp/app-manual-ai-dev-debug.apk` (manual only). They use `http://10.0.2.2:8787`. Phone use away from an ADB tunnel requires a configured HTTPS gateway; no public endpoint is deployed.

The gateway validates exact evidence quotes and approved action codes. It makes no tool calls, fetches no submitted links and keeps no raw-message logs or completed-result cache. AI has a 15-second upstream deadline, four-call concurrency cap, ten requests/minute/socket IP and a default 50-call/day/process cap (`AI_DAILY_LIMIT`). In-flight matching submission keys coalesce; conflicts reject. Cancellation attempts to abort work but does not reverse an upload or refund consumed tokens. Mobile timeouts, backgrounding and stale responses do not erase local findings or recreate cleared history. Retries require review and confirmation again.

Free-form model summaries are discarded at the gateway. The app explains the risk and approved warning/action codes in reviewed English/Filipino copy. Exact evidence quotes remain visible, and invented contact details or links in model prose cannot become recommendations. Editing a saved scan replaces its reviewed version under the same scan identity.

These local controls reset on restart and do not replace organization spending limits, authentication or trusted public ingress. Public hosting, verified account retention/spend settings and real-world PH evaluation remain release gates. No endpoint has been published. A 20-message synthetic comparison with separate development examples lives in `docs/ai-evaluation.md`; unavailable and unassessed responses are counted, and no accuracy claim follows.

## Checks

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test integration_test/manual_scan_test.dart -d emulator-5556 --flavor manual --no-pub
flutter test integration_test/ocr_native_test.dart -d emulator-5556 --flavor manual --no-pub
flutter test integration_test/reputation_native_test.dart -d emulator-5556 --flavor manual --no-pub --dart-define=USISA_GATEWAY_URL=http://10.0.2.2:8787
flutter test integration_test/ai_native_test.dart -d emulator-5556 --flavor manual --no-pub --dart-define=USISA_GATEWAY_URL=http://10.0.2.2:8787
node --test server/*.test.mjs
dart run tool/evaluate.dart
dart compile js tool/web_scanner_check.dart -o .verification/web_scanner_check.cjs
node -e "globalThis.self = globalThis; require('./.verification/web_scanner_check.cjs');"
```

Opt-in synthetic AI checks send fixture text to Groq and consume account quota. From `server`, set `USISA_RUN_AI_SMOKE=1` and run `node --env-file=../.env ai_smoke.mjs` for one call. For the frozen 20-message diagnostic, run `dart run tool/ai_local_evaluate.dart` from the project root, then set `USISA_RUN_AI_EVAL=1` and run `node --env-file=../.env ai_evaluate.mjs` from `server`. Neither script retries failed calls.

The JavaScript check covers the real scanner, including ID generation; VM tests alone did not catch a browser bit-shift issue. Create `.verification` first on a fresh checkout. Windows desktop plugin builds may require Developer Mode/symlink support; Android and web evidence are recorded separately.

Integration-test runs build a test entrypoint. Rebuild with `flutter build apk --debug --flavor manual --no-pub` before sharing the normal app. Android JVM/instrumentation tests live under `android/app/src/test` and `android/app/src/androidTest`; the picker-recovery test requires a Google API emulator. See `docs/completion-audit.md` for the task-by-task evidence and remaining gates.

## Data and detection limits

Messages are processed locally unless the user explicitly requests a disclosed external check. No background clipboard reads, automatic link opening, third-party chat scraping or SMS sending/deletion is implemented. Suspicious URLs are displayed as text.

The first rules are versioned Dart constants shared by manual/OCR and the SMS worker. Rule changes require an app release. They are heuristics, not calibrated probabilities. A 36-example synthetic diagnostic set lives in `test/fixtures/evaluation_messages.json`; `dart run tool/evaluate.dart` generates `docs/evaluation.md`. Five of 20 labeled scams were missed in that small set; no accuracy claim is appropriate. Paraphrases/obfuscation remain limitations of both approaches; AI adds a separately attributed assessment.

For PH research data, [Scott Lee Chua's published SMS collection](https://github.com/scottleechua/data/tree/main/spam-and-marketing-sms) has 8,895 records under CC BY 4.0, of which 1,997 unredacted spam/ads/government messages remain after excluding private/OTP categories. Source categories still need independent fraud-label review. A separate [Mishra/Soni smishing dataset](https://data.mendeley.com/datasets/f45bkkt8pr/1) provides ham/spam/smishing labels under CC BY 4.0, without establishing PH/Taglish coverage. Both pinned files were checked locally, outside app assets; no dataset text was uploaded to Groq or Safe Browsing and no embedded URL was visited.

The frozen local baseline assessed all 7,968 eligible messages. In the historical Mendeley comparison, after conflicting-label exclusion and exact deduplication, the rules alerted on 188 of 594 smishing-labeled messages and 28 of 4,834 ham messages. This exposes substantial local-rule misses; it is not Philippine accuracy or evidence of AI improvement. No detector was tuned from these results. Source integrity, exclusions, counts and reproduction details are in `docs/public-dataset-baseline-2026-11-10.md`; dataset recommendations remain in `docs/dataset-options-2026-11-10.md`.

The user explicitly bypassed the independent PH labeling/Filipino reviewer step for this development handoff. The prepared blind sample remains unlabeled and copy remains human-unverified; this does not establish detection accuracy or public-release readiness.

API35 emulator evidence includes incoming SMS after process removal, generic notification content, cold notification routing, offline OCR with editable review and picker Activity recreation, native secure-storage/manual integration, consented live Safe Browsing results, and reviewed manual Groq assessment. Native policy/encryption instrumentation and Dart race/permission tests are included. Real carrier/dual-SIM behavior, device-maker battery restrictions, TalkBack and human Filipino review still require physical-device/release validation. See `docs/feasibility.md`, `docs/completion-audit.md`, `docs/provider-validation.md`, `docs/ai-evaluation.md` and `docs/release-checklist.md` for the detailed evidence boundary.

Learn guidance draws on the [BSP fraud/scam primer](https://www.bsp.gov.ph/Media_and_Research/Primers%20Faqs/How_much_do_you_know_about_Fraud_and_Scam.pdf), [GCash account protection](https://help.gcash.com/hc/en-us/articles/19578518834457-How-can-I-protect-my-GCash-account), and [BPI social-engineering guidance](https://www.bpi.com.ph/personal/bank/digital-banking/online/cybersecurity/social-engineering-attacks). The app has no affiliation with these organizations.
