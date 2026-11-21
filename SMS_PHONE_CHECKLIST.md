# Scam text protection: real-phone checklist

Widget tests fake the Android SMS bridge, so delivery, permissions and background survival can only be
proven on real phones. Run this before every demo on a **Samsung**, a **Xiaomi** and an **Oppo or Vivo**
phone. Install with adb (Play Protect may block an SMS app installed from a browser, Messenger or a file manager):

```sh
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Send test texts from a second phone. Use the synthetic scam text in `MOCK_TEST.md`; for a harmless text,
send something like "See you at 5". On the emulator, `adb emu sms send 09171234567 "<text>"` fakes a text.

Write the phone, Android version and date next to each run. Tick only what you saw happen.

## 1. Setup

- [ ] Fresh install: the first screen is "Protect me from scam texts".
- [ ] "Turn on protection" shows **one** Android permission flow asking for SMS and notifications (Android 13+ shows both prompts back to back).
- [ ] After allowing both, home shows the Auto SMS protection switch **on** and "0 texts checked today".
- [ ] Samsung, Xiaomi, Oppo, Vivo: "Let Usisa keep running" appears; "Open settings" opens the phone's autostart or battery page (or Usisa's app info page). Allow background running / remove the battery limit there.
- [ ] Any other maker (for example a Pixel): no background-running step.
- [ ] Settings > Protection shows the same switch state as home; turning it off in one turns it off in the other.

## 2. Delivery

- [ ] App open: a scam text gives a "Dangerous text" or "Be careful" notification within about 10 seconds.
- [ ] App swiped away from recents: same result.
- [ ] Phone locked: notification shows the verdict and sender, **not** the message text.
- [ ] Tapping the notification opens Scan a message for that text and shows its Verdict.
- [ ] A harmless text gives **no** notification, and the "texts checked today" count goes up by one.
- [ ] The warned text is in History marked "From your texts". Delete it, close and reopen Usisa: it does **not** come back.

## 3. Multipart texts

- [ ] A scam text over 160 characters (the `MOCK_TEST.md` text works) gives one notification, and the opened check shows the whole message joined.

## 4. Dual SIM

- [ ] A scam text to SIM 1 notifies.
- [ ] A scam text to SIM 2 notifies.

## 5. A day idle

- [ ] Leave the phone unplugged and untouched for 24 hours with Usisa not opened. Then send a scam text: it still notifies within about a minute.
- [ ] Reboot the phone, do not open Usisa, send a scam text: it still notifies.

## 6. Recovery

- [ ] Android settings > Apps > Usisa > Permissions: turn off Notifications. Back in Usisa, home shows "Scam text protection is off" with **Fix**.
- [ ] Fix asks for the permission again (or opens Usisa's app info page if Android won't ask). After allowing, the banner goes away and the switch is on.
- [ ] Repeat with the SMS permission.

## Results

| Phone | Android | Date | 1 | 2 | 3 | 4 | 5 | 6 | Notes |
|-------|---------|------|---|---|---|---|---|---|-------|
|       |         |      |   |   |   |   |   |   |       |
