# Read aloud, Share into Usisa, and Send to family (Android)

Research for [#9](https://github.com/heliokii/Usisa/issues/9). Checked 2026-11-21 against Flutter 3.47.5 / Dart 3.13.4, minSdk 24, AGP 9.1.0, Kotlin 2.4.0 (from `android/settings.gradle.kts`).

## Recommendations

| Need | Use | Version |
|---|---|---|
| Read the verdict aloud | `flutter_tts` | `^4.2.5` |
| Show up in the Share menu (text, links, images) | Extend the existing `MainActivity` intent capture plus a `usisa/share` MethodChannel. Fallback: `receive_sharing_intent` | native, or `^1.9.0` |
| "Send to family" | `share_plus` | `^13.3.1` |

---

## 1. Read aloud (English and Filipino)

### Package

**`flutter_tts` 4.2.5**, published 2026-01-05. It has 150/160 pub points, about 1.6k likes and about 786k downloads in the last 30 days. Last push to `dlutton/flutter_tts` was 2026-01-05, with 226 open issues. The repo is not archived. ([pub.dev](https://pub.dev/packages/flutter_tts), [repo](https://github.com/dlutton/flutter_tts))

- Maintenance: steady but slow. There are a handful of releases a year and a large issue backlog. No well-maintained competitor wraps Android `TextToSpeech` more thinly, so there is no better pick.
- It wraps the platform `android.speech.tts.TextToSpeech`. No audio goes to a server from our side. The engine is whatever the phone's default is: usually "Speech Services by Google", but some OEMs, such as Samsung, ship their own engine.
- Android-only APIs it exposes ([README](https://github.com/dlutton/flutter_tts#readme)): `isLanguageInstalled`, `areLanguagesInstalled`, `getEngines`, `setEngine`, `getDefaultEngine`, `getDefaultVoice`, and `getVoices`. On Android, each voice includes `quality`, `latency`, `network_required` and `features`. `isLanguageAvailable` and `setLanguage` work on all platforms.
- Required manifest entry for apps targeting Android 11+ ([README](https://github.com/dlutton/flutter_tts#android), [Android docs](https://developer.android.com/reference/android/speech/tts/TextToSpeech)). Without it, the engine can be invisible to the app under package visibility rules:
  ```xml
  <queries>
    <intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>
  </queries>
  ```
  Usisa already has a `<queries>` block (for `PROCESS_TEXT`), so this entry goes inside it.
- The minSdk requirement is 21. Usisa's 24 is fine.

### Is a Filipino voice on typical PH phones?

- **Google's on-device engine has a Filipino voice, but it is not guaranteed to be downloaded.** Google added Filipino to its Android TTS engine around 2017. The source for this is the changelog for "Speech Recognition & Synthesis" as mirrored on APKMirror. That is a secondary source, and I found no first-party Google page listing the engine's current languages. Google's Cloud TTS (a different product) has supported `fil-PH` since 2019 ([Google Cloud blog](https://cloud.google.com/blog/products/ai-machine-learning/cloud-text-to-speech-expands-its-number-of-voices-now-covering-33-languages-and-variants)).
- Voice data is downloaded per language. A phone set to English usually has only English voices installed, so Filipino may report "missing data" until the user downloads it. Downloading happens in Settings > Text-to-speech > engine settings > Install voice data.
- **Unverified:** Samsung's own TTS engine (the default on many Samsung phones) and other OEM engines may have no Filipino voice at all. **Test on real devices before promising Filipino audio.** The minimum is one Samsung phone and one phone running stock Google TTS.
- Locale tags vary by engine. Try `fil-PH` first, then `tl-PH`, since some engines and older Android versions report Tagalog as `tl`. Java's `Locale` historically mapped `fil` to `tl`.

### What happens when it's missing

Platform behaviour, per the [`TextToSpeech` reference](https://developer.android.com/reference/android/speech/tts/TextToSpeech):

- `isLanguageAvailable` / `setLanguage` return `LANG_MISSING_DATA` (the language is known but its data is not installed) or `LANG_NOT_SUPPORTED` (the engine has no such language).
- `flutter_tts.setLanguage` returns `1` on success and `0` on failure on Android. If the call fails, the engine keeps its previous language. **The Filipino text would then be read with an English voice, which sounds garbled.** We must check availability before speaking. We must never "just try".
- If a voice has `network_required: true`, it fails offline. Prefer voices without that flag.

### Fallback (smallest sensible)

1. When the user opens the Read aloud control, call `isLanguageAvailable('fil-PH')`, then `'tl-PH'`. Cache the result.
2. If Filipino is available, read the Filipino verdict with it.
3. If it isn't, **read the English verdict with the English voice** and show a one-line note. Example: "Walang Filipino na boses sa phone na ito — binabasa sa English." Optionally add a link to TTS settings, which opens with the intent `com.android.settings.TTS_SETTINGS`.
4. If even English is unavailable (no engine at all, which is rare), hide the Read aloud control.

Skipped: a cloud TTS fallback such as Google Cloud TTS `fil-PH`. It costs money, needs network access, and sends verdict text off the device. Revisit only if device testing shows Filipino is missing on most phones.

---

## 2. Appearing in the Android Share menu

### What Android needs (any approach)

These are `ACTION_SEND` intent filters on the launcher activity ([Android: receiving simple data](https://developer.android.com/training/sharing/receive)):

```xml
<intent-filter>
  <action android:name="android.intent.action.SEND" />
  <category android:name="android.intent.category.DEFAULT" />
  <data android:mimeType="text/plain" />
</intent-filter>
<intent-filter>
  <action android:name="android.intent.action.SEND" />
  <category android:name="android.intent.category.DEFAULT" />
  <data android:mimeType="image/*" />
</intent-filter>
```

- Links arrive as `text/plain` in `EXTRA_TEXT`. Usually it's just the URL, sometimes it's "title + URL". Usisa's existing link detection can pull the URL out. Links need no separate filter. A `VIEW` filter would make Usisa a browser candidate, which is not what we want.
- Images arrive as a `content://` URI in `EXTRA_STREAM`. **Don't** register `*/*` or `SEND_MULTIPLE` unless needed. Each extra filter puts Usisa in more share sheets for content it can't check.

### Options compared

**A. `receive_sharing_intent` 1.9.0**, published 2026-06-24. It has 150 points, about 810 likes, and about 171k downloads in 30 days. The last commit was 2026-10-01, with 266 open issues. ([pub.dev](https://pub.dev/packages/receive_sharing_intent), [repo](https://github.com/KasemJaffer/receive_sharing_intent), [CHANGELOG](https://github.com/KasemJaffer/receive_sharing_intent/blob/master/CHANGELOG.md))
- Actively maintained in 2026. 1.9.0 requires Flutter 3.38+, migrated to Flutter's built-in Kotlin, and uses AGP 9.2.1 / Kotlin 2.4.0 / compileSdk 37. That fits Usisa's toolchain.
- API: `getInitialMedia()` for cold start (call `reset()` afterwards), and `getMediaStream()` for warm start. Both return `SharedMediaFile` with `type` (`text`/`url`/`image`/...) and `path`.
- `content://` handling, from [`FileDirectory.kt`](https://github.com/KasemJaffer/receive_sharing_intent/blob/master/android/src/main/kotlin/com/kasem/receive_sharing_intent/FileDirectory.kt): it resolves MediaStore paths where possible. Otherwise it **copies the stream into `cacheDir`** and hands Dart a file path. Copy failures for cloud-backed items are caught and logged (fixed 2026-10-01, #404). You don't need to handle URI permission lifetimes.
- The README example manifest includes `READ_EXTERNAL_STORAGE` and `*/*` filters. Copy only what we need. No storage permission is required for `ACTION_SEND` URIs, because the sender grants read access.

**B. `share_handler` 0.0.25**, published 2025-07-29. It has about 161 likes and about 99k downloads in 30 days. The last commit was 2026-03-14 and is unreleased. ([pub.dev](https://pub.dev/packages/share_handler), [repo](https://github.com/AboutShout/share_handler))
- Its strength is iOS share extensions and Android direct-share shortcuts. There has been no pub release in over a year, and the version is still 0.0.x. **Not recommended.**

**C. Native intent capture plus MethodChannel (recommended)**
- Usisa already does exactly this for notification taps. In [`MainActivity.kt`](../android/app/src/main/kotlin/com/example/usisa/MainActivity.kt), `capture(intent)` runs from `onCreate` (cold start) and `onNewIntent` (warm start). It stores a pending value that Dart pulls via `takeNotification()`, and calls `bridge.notifyOpen` when warm. The `usisa/sms` channel and its contract tests already exist.
- Share support is the same shape: in `capture()`, if `intent.action == ACTION_SEND`:
  - for `text/*`, take `getStringExtra(EXTRA_TEXT)`.
  - for `image/*`, read `EXTRA_STREAM` with `IntentCompat.getParcelableExtra(intent, EXTRA_STREAM, Uri::class.java)`. The untyped overload is deprecated in API 33, per the receive guide. If `androidx.core` isn't on the app's compile classpath, use a two-line `Build.VERSION.SDK_INT >= 33` branch instead. Then `contentResolver.openInputStream(uri)` into a file in `cacheDir`. This matches the plugin's approach and gives `ocr_service_native.dart` the file path that `InputImage.fromFilePath` already expects.
  - store `{type, value}` as pending; Dart takes it on startup and listens for a push when warm.
- That's roughly 30–40 lines of Kotlin, with no new dependency, no unused iOS share-extension setup, and the code is covered by the existing channel-test pattern.
- Do the copy off the main thread, or keep it small. Cap the size (for example, reject anything over 20 MB) because the sender controls the stream (trust boundary).

**Why C over A:** the cold/warm plumbing the plugin provides is already written in this app. The only new part is about 15 lines to copy a `content://` stream to cache. If the native route grows (multiple images, video, odd providers), switch to `receive_sharing_intent ^1.9.0`. It is the maintained option.

### Cold vs warm start gotchas

- **Cold start:** the intent is on `getIntent()` in `onCreate`. Dart isn't listening yet, so the value must be held until Dart asks for it. Usisa's pending-and-take pattern already does this. Clear it after the take so a rotation or recreate doesn't re-run the check. The existing code does the same with `removeExtra` and saved state.
- **Warm start:** `onNewIntent` only fires if the activity is reused. Usisa uses `launchMode="singleTop"`. By default, a `SEND` from another app starts the target activity **in the sender's task**. So sharing from Messenger usually creates a *new* `MainActivity` (cold path) and does not call `onNewIntent`. The plugin README suggests `singleTask` to always reuse one instance. That changes back-stack behaviour for the whole app, so only consider it if duplicate Usisa instances become a problem. Both paths must work either way.
- **Recents relaunch:** relaunching from Recents can re-deliver the original share intent. Android marks it with `FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`. Ignore the share when that flag is set, or the same Check re-runs.
- **Starting the Check:** Android's guidance is to "let them confirm and edit the shared content before your app uses it", especially for text ([receive guide](https://developer.android.com/training/sharing/receive)). The same guide warns that "the wrong MIME type might be set, or an image being sent might be extremely large", and says to do file I/O off the main thread. Usisa sends checked text to its server, so the safe default is to **open the Check screen prefilled and require one tap to run it**. This is a product decision. Auto-submit is easy if the team wants it. Run the check only after the user's consent and onboarding state allow it. A share received before onboarding is finished should be held, not dropped.
- **URI lifetime:** the read grant on a `content://` URI lasts only while the receiving activity is alive. Copy the data immediately; don't store the URI.
- **Mixed shares:** some apps send an image *and* `EXTRA_TEXT` (a caption). Prefer the image, and keep the text as context.

---

## 3. "Send to family" share sheet

**`share_plus` 13.3.1**, published 2026-10-01. It is a Flutter Community plugin with about 4k likes and about 5.6M downloads in 30 days. ([pub.dev](https://pub.dev/packages/share_plus), [repo](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/share_plus/share_plus))

- It is the standard way to do this. On Android it wraps `ACTION_SEND` via the system chooser.
- Current API: the old static `Share.share` is deprecated.
  ```dart
  await SharePlus.instance.share(ShareParams(text: verdictMessage));
  ```
  It returns a `ShareResult`. On Android, the status may be `unavailable` because the chooser doesn't always report the choice. Don't depend on it.
- Requirements: Flutter 3.38.1+ and AGP ≥ 8.12.1. Usisa has AGP 9.1.0, so it's fine.
- The cheaper alternative is to do it natively on the same MethodChannel (`Intent.createChooser(Intent(ACTION_SEND).setType("text/plain").putExtra(EXTRA_TEXT, msg), null)`). That's about 5 lines of Kotlin. `share_plus` is still the recommendation because it is the well-known standard. If keeping dependencies at zero matters more, the native call is a fine substitute, since it's text-only.

---

## Not verified against a primary source

These are from platform knowledge and were not re-checked against docs for this note:

- The default task placement of `SEND` targets.
- `FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY` re-delivery.
- The URI-grant lifetime.
- `flutter_tts.setLanguage` returning `1`/`0`.
- The `fil` → `tl` locale mapping.
- Samsung TTS's language coverage.

Confirm each during implementation or device testing.

## Open items to verify on devices

1. Run `getEngines`, `getVoices` and `isLanguageAvailable('fil-PH' / 'tl-PH')` on a Samsung phone (Samsung TTS default) and on a stock Google TTS phone (for example Xiaomi or Realme).
2. Share from Messenger, Viber, SMS (Google Messages), Chrome and Google Photos, with the app both closed and in the background.
3. Share a Google Photos image that isn't downloaded yet (a cloud-only item). The copy should fail gracefully.
