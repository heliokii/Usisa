# Usisa

Flutter/Dart scam checks for messages and links in the Philippines. The app explains potential warning signs in English and Filipino and accepts English, Filipino and Taglish input.

The local manual app and sideloaded SMS Lab are implemented and tested on an Android emulator. Physical-phone and live URL-provider validation remain open; AI assistance is planned separately. No detection method guarantees authenticity or catches every scam.

## Current capabilities

- Local text and HTTP(S) URL checks with evidence and practical safety advice.
- Android/iOS screenshot selection, bundled on-device Latin OCR and editable review before scanning. Offline Android emulator tests cover image bounds, failures and picker Activity recovery; physical-phone and iOS runtime validation remain open.
- Optional encrypted history (latest 100 scans, review access expires after 30 days), a separate draft restorable within 24 hours, local search/filters and protected deletion. Both start off. Expired files are cleaned while the app runs or on next use; closed/stopped apps cannot erase at an exact deadline. Cleanup failures are shown.
- English/Filipino interface, system/light/dark appearance, compact bottom navigation and wider navigation rail using the 60:30:10 palette.
- Optional URL-reputation gateway with separate consent, typed unavailable states and no provider key in the app. The configured key's live test currently fails with Google `BILLING_DISABLED`; successful provider coverage is not yet verified.

Browser previews use memory only. OCR and automatic SMS are native capabilities; a browser render does not prove them.

## Run the mobile app

Use Flutter 3.47.5 / Dart 3.13.4 or a compatible newer toolchain. Android minimum SDK is 24; the resolved OCR wrapper bundles the Latin recognizer. Keep the checked-in lockfile.

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

The small Node 24+ gateway holds provider credentials. It does not fetch submitted sites or follow their redirects. It sends only consented URLs to the fixed Google Web Risk API, with input limits, timeouts, rate/concurrency limits, no raw URL logs and no persistent response cache.

Set `WEB_RISK_API_KEY` in the worktree-root `.env` for the server. For browser development, also set `ALLOWED_ORIGIN` to the exact preview origin; do not use a wildcard. Missing provider configuration reports unavailable.

```powershell
cd server
npm start
```

The server binds to loopback on port 8787 by default and explicitly loads `../.env` if present. A public deployment needs TLS, trusted ingress abuse controls and a provider budget; none is deployed by this change.

The user now requires a free option for noncommercial school/research use. Google Safe Browsing is the researched replacement recommendation; see `docs/free-url-providers.md`. The gateway still uses Web Risk until migration, consent/attribution/expiry changes and live validation are complete. Do not enable Web Risk billing as part of that replacement.

Supply only the public gateway URL to Flutter, for example:

```powershell
flutter run -d chrome --dart-define=USISA_GATEWAY_URL=http://127.0.0.1:8787
```

Android emulators can use `http://10.0.2.2:8787` in debug builds once debug cleartext networking is configured; release gateways must use HTTPS. The server's allowed browser origin and this gateway URL are different settings.

`GROQ_API_KEY` remains server-only. The planned AI feature recommends `GROQ_MODEL=openai/gpt-oss-120b`; no AI endpoint or model call is implemented yet. Never add `.env` to Flutter assets or pass keys through Dart defines. See `DESIGN.md` and the AI plan under `docs/superpowers/plans/`.

## Checks

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test integration_test/manual_scan_test.dart -d emulator-5556 --flavor manual --no-pub
flutter test integration_test/ocr_native_test.dart -d emulator-5556 --flavor manual --no-pub
node --test server/reputation.test.mjs
dart run tool/evaluate.dart
dart compile js tool/web_scanner_check.dart -o .verification/web_scanner_check.cjs
node -e "globalThis.self = globalThis; require('./.verification/web_scanner_check.cjs');"
```

The JavaScript check covers the real scanner, including ID generation; VM tests alone did not catch a browser bit-shift issue. Create `.verification` first on a fresh checkout. Windows desktop plugin builds may require Developer Mode/symlink support; Android and web evidence are recorded separately.

Integration-test runs build a test entrypoint. Rebuild with `flutter build apk --debug --flavor manual --no-pub` before sharing the normal app. Android JVM/instrumentation tests live under `android/app/src/test` and `android/app/src/androidTest`; the picker-recovery test requires a Google API emulator. See `docs/completion-audit.md` for the task-by-task evidence and remaining gates.

## Data and detection limits

Messages are processed locally unless the user explicitly requests a disclosed external check. No background clipboard reads, automatic link opening, third-party chat scraping or SMS sending/deletion is implemented. Suspicious URLs are displayed as text.

The first rules are versioned Dart constants shared by manual/OCR and the SMS worker. Rule changes require an app release. They are heuristics, not calibrated probabilities. A 36-example synthetic diagnostic set lives in `test/fixtures/evaluation_messages.json`; `dart run tool/evaluate.dart` generates `docs/evaluation.md`. Five of 20 labeled scams were missed in that small set; no accuracy claim is appropriate. Paraphrases/obfuscation remain a limitation and motivate the planned AI assessment.

API35 emulator evidence includes incoming SMS after process removal, generic notification content, cold notification routing, offline OCR with editable review and picker Activity recreation, and native secure-storage/manual integration. Native policy/encryption instrumentation and Dart race/permission tests are included. Real carrier/dual-SIM behavior, device-maker battery restrictions, TalkBack and human Filipino review still require physical-device/release validation. A live Web Risk test correctly returned unavailable after Google rejected it with `BILLING_DISABLED`; no Groq inference was called. See `docs/feasibility.md`, `docs/completion-audit.md`, `docs/provider-validation.md` and `docs/release-checklist.md` for the detailed evidence boundary.

Learn guidance draws on the [BSP fraud/scam primer](https://www.bsp.gov.ph/Media_and_Research/Primers%20Faqs/How_much_do_you_know_about_Fraud_and_Scam.pdf), [GCash account protection](https://help.gcash.com/hc/en-us/articles/19578518834457-How-can-I-protect-my-GCash-account), and [BPI social-engineering guidance](https://www.bpi.com.ph/personal/bank/digital-banking/online/cybersecurity/social-engineering-attacks). The app has no affiliation with these organizations.
