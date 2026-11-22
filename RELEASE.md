# Releasing Usisa

Four steps, in order: the release gate, the manual full-AI evaluation, the signed APK, then the demo-day checklist.

## 1. Release gate (every release candidate)

```sh
dart run tool/release_gate.dart
```

It runs `flutter analyze --no-pub`, `flutter test --no-pub` and the phone-only Quality bar evaluation (`flutter test --no-pub tool/evaluate.dart`). All three steps always run. It exits non-zero and lists the blocking steps if any of them fails. The evaluation fails when a phone-only target is missed on the sealed split. Don't loosen a target or move messages between splits to make it pass. Tune the phone check on the development split, then re-run.

## 2. Manual full-AI evaluation (before each release, and after any prompt or model change)

This runs the whole labelled set (about 500 messages, both splits) through the online link check and AI review on the live gateway.

1. Raise `AI_DAILY_LIMIT` on Render to at least `600` for the day (see [server/README.md](server/README.md)). Otherwise the run uses up the day's AI calls and its later answers are Couldn't check.
2. Wake the gateway: `curl https://usisa-gateway.onrender.com/healthz` until it returns `{"status":"ok"}`, then check that `/v1/capabilities` shows both AI and link checks.
3. Run it. The gateway allows 10 AI calls a minute per address, so expect about 50 minutes:

   ```sh
   flutter test --no-pub tool/evaluate.dart --dart-define=USISA_EVAL_AI=true --dart-define=USISA_GATEWAY_URL=https://usisa-gateway.onrender.com
   ```

4. Save the printed report with the release notes: the date, the `GROQ_MODEL`, the prompt version (`promptVersion` in `server/ai_scan.mjs`) and pass or fail. A miss on the sealed split blocks the release just as it does in step 1.
5. Set `AI_DAILY_LIMIT` back afterwards, unless the demo is the same day.

## 3. Signed release APK

Every release is signed with the project key. Android only installs an update over an earlier version when the signing key matches and the version code is higher. A release build without the key fails on purpose; it never falls back to debug keys.

**Once, by the owner.** Create the keystore and keep it, and its passwords, outside the repo with a backup. If the key is lost, installed copies can't be updated. They have to be uninstalled, which deletes their History.

```sh
keytool -genkeypair -v -keystore usisa-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias usisa
```

Then create `android/key.properties`. It is git-ignored, as are `*.jks` and `*.keystore`. `storeFile` is relative to `android/`, or absolute:

```properties
storeFile=C:/path/outside/repo/usisa-release.jks
storePassword=...
keyAlias=usisa
keyPassword=...
```

**Each release:**

1. Bump `version:` in `pubspec.yaml`. The number after `+` is the Android version code and must be higher than in any APK already handed out (for example `1.0.0+1` to `1.0.1+2`).
2. Build: `flutter build apk --release`. The APK is `build/app/outputs/flutter-apk/app-release.apk`.
3. Check the signature: `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`. `apksigner` is in the Android SDK `build-tools`. The SHA-256 must match the project key, not "Android Debug".
4. Check the upgrade on a phone that has the previous release with some History: `adb install -r build/app/outputs/flutter-apk/app-release.apk`. It must install without "signatures do not match", and History must still be there.

The application ID is `com.usisa.app`. Builds from before the rebuild used `com.example.usisa`, which Android treats as a different app, so those phones need the old app uninstalled.

## 4. Demo-day checklist

**The day before**

- [ ] The release gate and the full-AI evaluation have been run on the build being shown, and the results are saved.
- [ ] Set `AI_DAILY_LIMIT` on Render high enough for the audience (for example `500`). The default `50` is shared by every user for the whole UTC day.
- [ ] The keep-alive pingers (cron-job.org, UptimeRobot) are enabled and green. See [server/README.md](server/README.md#keep-alive).
- [ ] Charge the phones and the laptop. Pack a USB cable for each demo phone.

**Each demo phone**

- [ ] Install the signed release APK (`adb install -r ...`). If it was sideloaded, Google Play Protect may show "Unsafe app blocked" or offer a scan. Choose **More details > Install anyway**, or scan it, and repeat on every phone, because Play Protect decides per phone. Open the app once afterwards to check that Play Protect didn't remove it.
- [ ] Set the language you will demo in (Settings). Run one check and say yes to the first-use consent for online checks, so AI review and link checks are available.
- [ ] Turn on **Auto SMS protection** on the home card. Allow SMS and, on Android 13 or newer, notifications. If a permission was denied earlier, allow it in the app's system settings.
- [ ] Turn off battery optimisation for Usisa (Settings > Apps > Usisa > Battery > Unrestricted). Xiaomi, Oppo, Vivo and Samsung battery managers can stop the background text check otherwise.
- [ ] Clear History, or prepare it on purpose, so nothing private shows on screen.
- [ ] Run one Scan a message with the sample from [MOCK_TEST.md](MOCK_TEST.md) to confirm the phone works offline.

**Thirty minutes before**

- [ ] Wake the gateway: `curl https://usisa-gateway.onrender.com/healthz` returns `{"status":"ok"}`, and `/v1/capabilities` shows AI and link checks configured. A cold start takes up to about a minute.
- [ ] Run one AI scan on a phone to confirm the AI answers, not Couldn't check.

**SMS demo over adb (emulator)**

`adb emu sms send` only works on an emulator. On a real phone, send the texts from a second phone.

```sh
adb emu sms send 09171234567 "Hi Ma, uuwi ako mamaya"
adb emu sms send 09171234567 "Your GCash account is locked. Verify at http://gcash-verify.example now"
```

The first text only raises "N texts checked today". The second raises the count and shows a "Dangerous text" notification. Tap it to open the check, which is also in History as "From your texts". If nothing happens, run `adb logcat -s WM-WorkerWrapper:I flutter:I`.

**If something fails during the demo:** with the gateway asleep or out of quota, the app shows Couldn't check for online checks, and the phone check still works. Say so, and carry on with Scan a message.
