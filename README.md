# Usisa

Flutter/Dart scam checks for messages and links in the Philippines. The app explains potential warning signs in English and Filipino and accepts English, Filipino and Taglish input.

The manual-scanning milestone is implemented. The sideloaded automatic-SMS build is in progress; AI assistance is planned separately. No detection method guarantees authenticity or catches every scam.

## Current capabilities

- Local text and HTTP(S) URL checks with evidence and practical safety advice.
- Android/iOS screenshot selection, bundled on-device Latin OCR and editable review before scanning. Native device validation is still required.
- Optional encrypted history (latest 100 scans, 30 days), a separately optional 24-hour text draft, local search/filters, and protected deletion. Both retention settings default off.
- English/Filipino interface, system/light/dark appearance, compact bottom navigation and wider navigation rail using the 60:30:10 palette.
- Optional URL-reputation gateway with separate consent, typed unavailable states and no provider key in the app. Requires configuration; no live provider lookup has been verified.

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

Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`. This is a development build, not a signed store release. The application identity/signing and distribution evidence remain release decisions.

## Optional URL-reputation gateway

The small Node 24+ gateway holds provider credentials. It does not fetch submitted sites or follow their redirects. It sends only consented URLs to the fixed Google Web Risk API, with input limits, timeouts, rate/concurrency limits, no raw URL logs and no persistent response cache.

Set `WEB_RISK_API_KEY` in the worktree-root `.env` for the server. For browser development, also set `ALLOWED_ORIGIN` to the exact preview origin; do not use a wildcard. Missing provider configuration reports unavailable.

```powershell
cd server
npm start
```

The server binds to loopback on port 8787 by default and explicitly loads `../.env` if present. A public deployment needs TLS, trusted ingress abuse controls and a provider budget; none is deployed by this change.

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
node --test server/reputation.test.mjs
dart compile js tool/web_scanner_check.dart -o .verification/web_scanner_check.cjs
node -e "globalThis.self = globalThis; require('./.verification/web_scanner_check.cjs');"
```

The JavaScript check covers the real scanner, including ID generation; VM tests alone did not catch a browser bit-shift issue. Create `.verification` first on a fresh checkout. Windows desktop plugin builds may require Developer Mode/symlink support; Android and web evidence are recorded separately.

## Data and detection limits

Messages are processed locally unless the user explicitly requests a disclosed external check. No background clipboard reads, automatic link opening, third-party chat scraping or SMS sending/deletion is implemented. Suspicious URLs are displayed as text.

The first rules are versioned Dart constants shared by manual/OCR and the planned SMS worker. Rule changes currently require an app release. They are heuristics, not trained or calibrated probabilities. Evaluation on separate PH examples, native lifecycle/OCR checks, and a human Filipino copy review remain required before release.

Learn guidance draws on the [BSP fraud/scam primer](https://www.bsp.gov.ph/Media_and_Research/Primers%20Faqs/How_much_do_you_know_about_Fraud_and_Scam.pdf), [GCash account protection](https://help.gcash.com/hc/en-us/articles/19578518834457-How-can-I-protect-my-GCash-account), and [BPI social-engineering guidance](https://www.bpi.com.ph/personal/bank/digital-banking/online/cybersecurity/social-engineering-attacks). The app has no affiliation with these organizations.
