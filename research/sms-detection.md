# Why incoming SMS is never detected

Research for heliokii/Usisa#5. Researched 2026-11-21 against commit `a862497`. Only the code was read: none of this was run on an emulator or phone.

## Short answer

1. **The build you normally run cannot detect SMS. This is by design.** `pubspec.yaml` sets `default-flavor: manual`, and the README says to use `flutter run --flavor manual`. In `manual`, `BuildConfig.SMS_ENABLED = false`, and its merged manifest has **no `RECEIVE_SMS` permission and no `<receiver>`**. Both are declared only in `android/app/src/smsLab/AndroidManifest.xml`. So Android never delivers `SMS_RECEIVED` to the app. Even if it did, `SmsReceiver.permitted()` returns false because `BuildConfig.SMS_ENABLED` is false. The SMS switch is greyed out (`onChanged: widget.sms.supported ? ... : null`). This is the main reason.
2. **In `smsLab`, three things must all be true before anything happens:** the RECEIVE_SMS runtime grant, the in-app switch turned on (`PendingSmsStore.enabled` defaults to `false`), and POST_NOTIFICATIONS granted on Android 13+. POST_NOTIFICATIONS is requested only from Settings, not by the SMS switch. **Low-risk texts are deleted with no notification** (`PendingSmsStore.complete` -> `remove` when `risk == "low"`). A normal test text such as "hi" therefore looks like "nothing detected" even when the whole pipeline worked.
3. **Android itself allows this design.** `SMS_RECEIVED_ACTION` is on the list of implicit-broadcast exceptions, so a manifest receiver still works when the app targets API 36. Delivery can still be lost or delayed in three cases: after a **force-stop** (stricter on Android 15), when the WorkManager job is deferred in a low **standby bucket** (Restricted bucket after 8 days without use on Android 13+), and on **OEM builds (Xiaomi, Oppo, Vivo, Samsung)** whose battery managers block autostart or kill the process.
4. **Play policy:** a non-default-SMS app may hold `RECEIVE_SMS` only through a Play-approved exception, declared in the Permissions Declaration Form. The candidate exceptions are "Caller ID, spam detection, and/or spam blocking" and "Anti-SMS phishing". Anti-SMS phishing requires a track record of significant protection, and Usisa does not have one yet. Separately, in the Philippines, Play Protect's enhanced fraud protection is on by default and **blocks sideloaded installs** (from a browser, messaging app or file manager) of apps that declare `RECEIVE_SMS`. Sharing the `smsLab` APK with testers over Messenger or Drive will usually fail to install.

## 1. The code path, step by step

| Step | File | What must hold | Where it breaks silently |
|---|---|---|---|
| Build | `android/app/build.gradle.kts` | flavor `smsLab` (`SMS_ENABLED=true`, id `com.example.usisa.smslab`) | `manual` (the default in `pubspec.yaml`) has `SMS_ENABLED=false` |
| Manifest | `src/smsLab/AndroidManifest.xml` | `RECEIVE_SMS`, `POST_NOTIFICATIONS`, `<receiver .SmsReceiver exported=true permission=BROADCAST_SMS>` with `SMS_RECEIVED` filter | `src/main` declares only `INTERNET`. `manual` has no receiver at all |
| Install | — | `smsLab` installs as a **separate app** (`.smslab` suffix) next to `manual` | Testing the `manual` app while texting = no receiver |
| Opt-in | `app.dart` `_setSmsEnabled` -> `SmsService.setEnabled` -> `MainActivity.requestSmsPermissions` -> `SmsBridge "setEnabled"` | User accepts disclosure, grants RECEIVE_SMS, then `store.setEnabled(true)` | If the grant is denied, `enable` is false and the switch flips back. Nothing tells the user why |
| Receive | `SmsReceiver.onReceive` | action matches, `permitted()`, `store.enabled`, one originating address, PDUs present | Returns early with no log on every guard |
| Queue | `PendingSmsStore.put` | enabled, generation matches, < 20 queued, body ≤ 10,000 code points, not a duplicate (15 min) | `DUPLICATE`/`STALE`/`DISABLED` drop silently. `FULL` shows "queue-limit" only if notifications are allowed |
| Schedule | `SmsCheckWorker.enqueue` | Unique one-time work (not expedited) + 15-min expiry worker | Deferred by Doze / standby bucket / OEM killers (see §2–3) |
| Evaluate | `SmsCheckWorker.evaluate` -> headless `FlutterEngine(..., automaticallyRegisterPlugins=false)` -> `usisaSmsBackground` (`@pragma('vm:entry-point')` in `lib/main.dart`) -> `runSmsBackground` | Dart side calls `takeEvent`, runs `ScamAnalyzer`, calls `complete` within 30 s | The analyzer imports only `dart:math` and local files, so it should not need plugins. Runtime is **unverified** (the README says smsLab flows were never checked) |
| Commit | `PendingSmsStore.complete` | generation still matches and still enabled | `risk == "low"` -> **event deleted, no notification** |
| Alert | `SmsAlerts.show` | POST_NOTIFICATIONS (API 33+), notifications enabled, channel not blocked | `allowed()` false -> returns silently. The SMS switch never asks for POST_NOTIFICATIONS. Only Settings does (`settings_screen.dart`) |
| Expiry | `SmsPolicy.TTL_MS` = 15 min | Review the event within 15 min | Older events are erased on read, so the "Recent detections" list empties itself |

The code itself looks correct. "Never detected" is best explained by testing the `manual` flavor (step 1), or by testing `smsLab` with a benign text and no notification permission (the last three rows). Recommended next step (not done here, since app code was out of scope): add `Log.d` at each early return in `SmsReceiver`/`PendingSmsStore.put`, and show a status line in the SMS screen when notifications are off.

## 2. Android version rules

- **Manifest receiver for SMS is allowed on every API level.** Android 8.0+ blocks manifest receivers for most implicit broadcasts, but `Telephony.Sms.Intents.SMS_RECEIVED_ACTION` and `WAP_PUSH_RECEIVED_ACTION` are exempt ("SMS recipient apps rely on these broadcasts"). https://developer.android.com/develop/background-work/background-tasks/broadcasts/broadcast-exceptions
- **Delivery time is not guaranteed.** On Android 14, broadcasts to cached apps can be deferred. "Important" manifest-declared broadcasts temporarily lift the app out of the cached state. https://developer.android.com/develop/background-work/background-tasks/broadcasts
- **`goAsync()` work must finish fast (under 10 s).** The process can be killed after `onReceive()`, so long work belongs in a job. Usisa does this correctly: encrypt + write + enqueue on an executor, then hand off to WorkManager. Same page as above.
- **Force-stop.** An app in the stopped state receives no broadcasts until the user opens it again. Android 15 also **cancels all PendingIntents** when an app is force-stopped, and leaves the stopped state only through user action. OEM "clean"/"boost" buttons often force-stop. https://developer.android.com/about/versions/15/behavior-changes-all#enhanced-stop-states
- **App Standby Buckets (API 28+).** These decide how soon the `SmsCheckWorker` job runs on battery. The **Restricted** bucket (Android 12+) allows jobs once a day in a 10-minute batched window, and applies **even while charging**. On Android 13+, an app enters Restricted after **8 days** without user interaction (45 days on 12/12L). Tapping a notification promotes the app to Active. Check the bucket with `adb shell am get-standby-bucket com.example.usisa.smslab`. https://developer.android.com/topic/performance/appstandby
- **Consequence for Usisa:** the receiver will usually fire, but the scan and alert can be delayed by hours for a user who rarely opens the app. By then the 15-minute TTL has also expired, so the event is discarded. Moving the scan into the receiver's `goAsync()` window (the Dart analyzer is fast, but a cold engine start is not), or using an expedited job (`setExpedited`), would reduce this. Not tested.

## 3. OEM battery killers (common in PH)

Rankings and settings are from dontkillmyapp.com, a community site and not a vendor source. Samsung and Xiaomi score 5/5 (worst), Oppo 4/5 and Vivo 3/5. https://dontkillmyapp.com/

| Vendor | What it does | What the user must change |
|---|---|---|
| Xiaomi (MIUI/HyperOS) | Per-app **Autostart** is off by default, so manifest receivers do not wake the app. Battery saver kills background work | Apps > Usisa > *Autostart* on. Battery saver = *No restrictions*. Lock in Recents. https://dontkillmyapp.com/xiaomi |
| Oppo / realme (ColorOS) | Kills background services when the screen turns off. Startup manager blocks auto-launch | Allow *Auto launch*. Disable battery optimization. Lock in Recents. https://dontkillmyapp.com/oppo |
| Vivo (Funtouch/OriginOS) | Blocks background loading without **Autostart** | Autostart on. *High background power consumption* allowed. https://dontkillmyapp.com/vivo |
| Samsung (One UI) | "Sleeping"/"Deep sleeping" apps after a few days unused. Adaptive battery | App > Battery > *Unrestricted*. Add to "Never sleeping apps". https://dontkillmyapp.com/samsung |

No code can grant these settings. The app can only detect symptoms and show the user instructions. These problems never show up on a Pixel emulator.

## 4. Google Play SMS / Call Log policy

Source: Play Console Help, "Use of SMS or Call Log permission groups", https://support.google.com/googleplay/android-developer/answer/10208820

- `RECEIVE_SMS` is restricted. Normally only the **default SMS handler** may request it, and only for its core functionality.
- Non-default apps may get a **temporary exception** for listed use cases when no alternative exists. Relevant ones:
  - **"Caller ID, spam detection, and/or spam blocking"**. This covers `RECEIVE_SMS` (and READ_SMS, READ_CALL_LOG, etc.).
  - **"Anti-SMS phishing"**. This requires "a track record of significant protection for users", shown through analyst reports, benchmarks or similar. A new app does not meet that bar.
- The use must be the app's **core functionality**, and the app must submit the **Permissions Declaration Form** in Play Console. Apps without a declaration, or that fail the policy, can be removed. The form must be resubmitted if the use changes.
- The developer guidance for Play Protect warnings recommends asking for the minimum permissions possible. https://developers.google.com/android/play-protect/warning-dev-guidance
- **Implication:** a Play build with `RECEIVE_SMS` must make SMS scanning a core feature and file under "spam detection". Approval is at Google's discretion. Keeping SMS out of the Play (`manual`) flavor, as the repo does now, is the safe default. The other option is the share-to-Usisa / paste flow, which needs no permission.

### Sideloaded testing in the Philippines

- Play Protect **enhanced fraud protection** blocks installs of apps declaring `RECEIVE_SMS`, `READ_SMS`, notification-listener or Accessibility when installed from "Internet-sideloading sources" (browsers, messaging apps, file managers). https://security.googleblog.com/2024/02/piloting-new-ways-to-protect-Android-users-from%20financial-fraud.html , https://developers.google.com/android/play-protect/warning-dev-guidance
- It is **on by default in the Philippines** (launched Feb 2025; Google PH reported 3.2M blocked installs). This comes from press coverage, not a Google page: https://mb.com.ph/2025/2/12/google-s-enhanced-play-protect-aims-to-block-over-3-2-million-high-risk-install-attempts
- Installs via `adb`/`flutter run` are not one of the listed sources, so developer installs should work. Sending the APK to testers over Messenger or Drive will likely be blocked. Use Play internal testing instead.
- Unverified: Android 13+ "restricted settings" may also gate the SMS permission for sideloaded apps (only secondary sources say so). If the permission dialog never appears, check App info > ⋮ > *Allow restricted settings*.

## 5. Reproducing it

### Emulator (what it can show)

```sh
flutter run --flavor smsLab          # NOT the default 'manual'
# In the app: SMS switch on, grant SMS; Settings -> enable notifications.
adb emu sms send 09171234567 "Your GCash account is locked. Verify at http://gcash-verify.example now"
adb logcat -s ActivityManager:I WM-WorkerWrapper:I flutter:I
adb shell am get-standby-bucket com.example.usisa.smslab
adb shell am set-standby-bucket com.example.usisa.smslab restricted   # simulate a neglected app
adb shell am force-stop com.example.usisa.smslab                       # then send again: expect nothing
adb shell dumpsys deviceidle force-idle                                # Doze
```

`sms send <number> <text>` injects an inbound SMS through the emulated modem. The `adb emu` form is a one-shot wrapper. https://developer.android.com/studio/run/emulator-console#sms

Things to check on the emulator: flavor/manifest wiring, permission flow, receiver -> store -> worker -> headless Dart -> notification, low-risk silent drop, Doze/bucket/force-stop effects, and the 15-minute expiry.

### Only a real device shows

- OEM autostart/battery-manager kills (Xiaomi, Oppo, Vivo, Samsung). The emulator runs stock AOSP.
- Real carrier PDUs: multipart/concatenated SMS, sender IDs with letters ("GCASH"), Unicode/Filipino text, dual-SIM `EXTRA_SUBSCRIPTION_INDEX`, carrier retry duplicates (the 200-entry/15-min `seen` cache is a known shortcut).
- Play Protect sideload blocking and restricted-settings prompts on a real Google-certified device.
- Real standby-bucket and ML-predicted bucket behaviour after days of non-use.
- Interaction with the default SMS app (Google Messages spam filtering does not block the broadcast, but OEM SMS apps vary; unverified).

## Open questions

- Has anyone run `smsLab` end to end? The README says the flows are unverified.
- Should the alert also fire for low-risk messages during development, to confirm the pipeline runs?
- Product decision: is the Play exception worth pursuing, or should SMS stay in the lab flavor with share/paste as the shipping flow?
