# Usisa design specification

Status: the screenshot-led light UI is implemented across the Flutter app. The cream/forest/coral palette is the sole appearance; visual parity still needs review on Android hardware. See README for validation and release limits.
Date: 10 November 2026.
Implementation/evidence update: 10 November 2026.
Visual redesign revision: 10 November 2026.
Companion: [implementation plan](docs/superpowers/plans/2026-11-09-usisa-implementation.md).

## 1. Product and audience

Usisa helps people in the Philippines pause before acting on a suspicious message. It checks message text and URLs, explains warning signs, and recommends a practical next step. Typical content impersonates banks, e-wallets, government agencies, delivery services, or online sellers. People may be anxious, distracted, using an older phone, or unfamiliar with technical security language.

The primary job is: **“Help me decide what to do with this message before I tap, pay, reply, or share information.”**

Required capabilities:

- Manual scanning of typed or explicitly pasted text.
- A dedicated URL checker and per-link findings inside message results.
- Screenshot import, on-device OCR, and editable text review before analysis.
- Android incoming SMS checks after explicit consent, permissions, and distribution eligibility.
- Understandable risk classifications, quoted evidence, and safety recommendations.
- Optional Groq AI-assisted scanning of explicitly reviewed manual text, complementing the local algorithm. Automatic SMS detection stays local.

Detection cannot verify every sender or guarantee that content is safe. The app does not read private conversations in third-party messaging apps. It does not promise unrestricted or continuous monitoring.

## 2. Current project and proposed decisions

The project uses Dart/Flutter Material 3 with shared local rules, English/Filipino UI, on-device OCR, encrypted opt-in retention, and a consented URL-reputation gateway. Separate `manual` and `smsLab` Android flavors keep restricted SMS permissions out of the default build. Development identities remain `com.example.usisa` and `com.example.usisa.smslab`; signing and public release identity remain release gates.

Provider migration, 10 November 2026: the user requested a free alternative after Web Risk returned BILLING_DISABLED and confirmed noncommercial school/research use. **Google Safe Browsing is implemented**, including re-consent, linked attribution and expiry-aware warnings. Configured-key threat/no-match checks passed through the gateway and Android emulator. See [provider comparison](docs/free-url-providers.md) and [live validation](docs/provider-validation.md).

The following decisions define the approved implementation direction:

| Decision | Proposal and reason |
|---|---|
| Initial release | Android first; responsive phone and tablet layouts. Keep manual flows portable to iOS, but treat iOS release engineering as a later scope decision. |
| Architecture | Flutter Material 3, feature folders, SDK state tools, a shared Dart analysis engine, and small platform/service boundaries. |
| Account | No sign-in required. Checking a message should be immediately available. |
| Language | English and Filipino UI; analyze English, Filipino, and mixed Taglish without asking users to identify the language. Human review of Filipino copy is a release requirement. |
| Analysis | Deterministic rules locally for every scan and automatic SMS. Manual users may additionally request an independent Groq AI assessment after reviewing the text to send. URL reputation remains a separate consented service. |
| Retention | Session-only by default. Persistent history and draft restoration are separate opt-ins. |
| Visual identity | Screenshot-matched screen hierarchy, warm cream #EEE5D4 (60%), forest green #1D4A35 (30%), coral #F2452E (10%), readable system type, and evidence as the focal point. |

### Approaches considered

1. **Offline rules only:** smallest dependency and privacy footprint, but cannot identify known malicious links through a live threat list. Useful first milestone, incomplete as the full link intelligence experience.
2. **Local analysis plus optional online URL reputation — recommended:** keeps message/OCR processing local and works with limited connectivity; adds a narrow server boundary, provider costs, and explicit URL disclosure.
3. **Optional AI assistance — added by the user on 9 November 2026:** retain the recommended local core and add a manual Groq assessment for contextual, paraphrased, and obfuscated messages. This adds reviewed text transmission, operating cost, and separate evaluation. It does not replace local automatic SMS checks or establish perfect detection.

Do not present a paid tier, referral program, public dashboard, community blacklist, or account system as part of this release.

## 3. Experience principles

Apply Apple’s design principles to this safety tool as concrete interface behavior:

1. **Purpose.** Every screen helps a person decide what to do before tapping, paying, replying, or sharing information. Keep the first action obvious and avoid decorative features that slow a scan.
2. **Agency.** Keep users in control of input, AI uploads, online URL checks, SMS consent, retention, cancellation, and deletion. Make Back and Cancel predictable; preserve recoverable work.
3. **Responsibility.** Show the evidence and limits of each check. Ask permission in context, disclose what leaves the device, and never describe an unknown or no-match result as safe.
4. **Familiarity.** Use a consistent header, Back behavior, labeled root navigation, Material controls, platform status bars, and system gestures.
5. **Flexibility.** Support English and Filipino, Taglish content, screen readers, large text, one-handed phone use, landscape, and wider tablet layouts without hiding content.
6. **Simplicity.** Put the common manual scan first. Keep AI, URL reputation, SMS, and privacy decisions visible at the moment they matter without crowding the Home screen.
7. **Craft.** Align card edges and icon baselines, maintain a consistent spacing rhythm, use legible type and measured contrast, and make the same control behave the same on every screen.
8. **Delight.** Aim for calm confidence through fast feedback, helpful explanations, and a small, consistent shield/link/OCR illustration system. No alarm theatrics or celebratory effects.

Interaction follows the user's movement: pressed feedback begins on touch-down; scroll and onboarding swipes track the finger; Back gestures retrace the forward route; animations begin from their current visible position and can be interrupted. Use native Flutter transitions for navigation. Avoid overshoot except where a user gesture carries momentum. Reduced-motion settings replace spatial movement with a short opacity change while retaining immediate state feedback.

Every screen answers where the user is, what they can do, and how to leave. Put field errors beside the field, status near the action it describes, and safety advice beside the finding that triggered it. Color, haptics, and motion supplement plain-language labels; they never carry risk meaning alone.

## 4. Information architecture and primary journeys

The four labeled root destinations follow the reference Home screen: **Home**, **History**, **Learn**, and **Settings**. Show the floating rounded navigation pill only on Home; the selected destination uses a coral icon and label with no filled indicator. On wider screens, show the navigation rail only on Home. History, Learn, and Settings provide a clear return-to-Home control and respond to system Back. Full-screen scan, result, SMS setup, and AI child flows retain their own Back controls and native Back behavior.

**Primary flow:** Welcome onboarding → Home → choose Scan Message, Check a Link, Scan Screenshot, AI Scan, or Auto SMS Detection → review any text that may leave the device → analysis → explained result → optional safety recommendations and private history.

**AI flow:** AI Scan introduction → choose Text/Message, URL/Link, or Screenshot/Image → edit and review the exact text → confirm the AI submission → local checks and Groq request → attributed AI Scan Result.

**SMS flow:** Home toggle → explain local processing and temporary storage → consent → request runtime permissions → show real enabled/denied/unavailable status → local detection → generic notification → user opens the app for the full result. Automatic SMS never calls AI or online reputation.

Online link consent remains independent of AI consent. **Enable online link checks** explains that URLs will be sent to Usisa's gateway and the named provider for this and later manual checks until disabled. **Keep local only** remains available. Background SMS analysis stays local; a user can open an SMS result and separately request a foreground URL check or AI assessment after seeing the relevant disclosure and confirming that submission.

### Welcome / onboarding

Match the supplied centered welcome layout: shield illustration in the upper half, Usisa name and short purpose statement centered below it, three-page indicator, and a large thumb-reachable **Get Started** action anchored near the bottom. Keep the status bar and safe areas clear. Explain that results are warnings, not proof of authenticity. Offer English/Filipino selection and disclose session-only default behavior; saved history and draft restore remain opt-in. Do not request SMS, notification, photo, or online-service permissions here. The three dots are real page indicators for a swipeable introduction, and every page has a visible skip/start action; reduced motion disables parallax and uses a crossfade.

### Home

Match the supplied Home reference: pale cream background without the abstract wave; a red shield, **PH Scam Detector** brand, and notification affordance; a two-line headline with a coral emphasis, short supporting copy, and cropped green leaf artwork at the right edge. Follow with four lightly elevated action cards in a two-column grid (**Scan Message**, **Check a Link**, **Scan Screenshot**, **AI Scan**). Make Scan Message the primary forest-green card, keep the remaining cards cream with coral icons, and mark AI with a small **New** badge. Place the **Auto SMS Detection** row below them with a coral phone icon and an on-device switch; show permission status only when SMS is not enabled. The existing floating navigation pill appears on Home only.

The cards keep the reference icon-left, title/description-center, chevron-right composition. Each card is one accessible button; the icon and chevron are decorative to assistive technology when the same label is present. Home does not display fabricated protection scores or empty dashboard statistics. If recent scans are enabled, show only a compact recent list below the main actions.

### Standard scan and screenshot review

**Scan Message** opens a labeled, multiline input with explicit paste, clear, and **Check Message** actions. **Scan Screenshot** opens the system picker, runs OCR on device, then shows the selected image and editable recognized text with **Check This Text**, **Choose Another Image**, and **Cancel**. Explain that OCR may misread characters and URLs. Never auto-submit OCR text or send an image to AI. No camera capture or broad photo-library access is added.

### Scan Result

Match the screenshot hierarchy: (1) top risk banner with icon, plain risk label, and one-sentence meaning plus the most urgent immediate action; (2) source-labeled message card containing the exact checked excerpt; (3) **Detected Warning Signs** with compact icon/title/explanation rows; (4) prominent **Safety Recommendations** action opening tailored next steps; then any coverage details, reputation result, and full original text below the main composition. Every warning row may expand to reveal its exact source excerpt. URLs remain non-clickable and display the full host; checking a link never opens it.

Use a representative reserved-domain example such as bank-verify.example, not a real bank URL. State uncertainty and incomplete coverage near the risk label. A low result still says that no common warning signs were found and does not verify the sender.

### Link Checker

Use the supplied vertically stacked layout: back/title row, URL field with link icon and clear control, full-width **Check Link** button, result banner, **Why Is It Risky?** heading, then short finding rows with icon, title, and explanation. Show the complete normalized host and the original URL. The result has a clear coverage/provider label and check time; the banner never claims certainty. Use reserved example domains in mock data.

### SMS Detection

Use a full-screen secondary route matching the supplied screen: title and current toggle in the header, short explanation, **Recent Detections** heading, then message rows with sender/source, short preview, risk label, time, and chevron. Alerts remain generic on the lock screen. Toggling on explains temporary processing and requests runtime permissions only after the user chooses to continue. Toggling off stops new processing and clears pending work. This screen does not imply access to conversations in other messaging apps.

### Learn & Stay Safe

Use the supplied order: centered **Learn & Stay Safe** title; a large **Scam Safety Tips** feature card; **Common Scams in PH** heading; then cards for **Bank & E-Wallet Scams**, **Government Impersonation**, and **Online Selling Scams**. Each card has a distinct vector icon, concise explanation, and chevron. Article detail uses plain language and practical next steps, without unverified hotlines or affiliation claims.

### History and Settings

History uses flat accessible rows with risk, source, preview, time, and coverage; detail preserves the full content. When retention is off, show a privacy explanation and **Enable private history**, distinct from **No scans yet** when enabled. Search is debounced by 300 ms. Risk, source (text/link/screenshot/SMS), and date (all/7 days/30 days) filters combine with search using AND; show removable active-filter chips, result count, and **Clear filters**. Selection mode includes **Select**, **Select all matching** with the total count, and **Clear selection**. Confirm bulk deletion and clearing all history. Single deletion offers a five-second Undo; clearing all data offers no misleading Undo after keys/records are destroyed. Deleting a scan never deletes a phone SMS. Missing/deleted routes offer **Go to history** and **Start a new scan**. Root **Settings** contains language, AI and SMS detection, retention, online URL consent, and notification status. The light appearance is fixed to the product palette. Permission controls report actual OS access and offer a recovery path.

## 5. Reference layout specification

The attached boards are the visual source of truth for screen composition, hierarchy, and card order. Recreate the phone-frame proportions and the following top-to-bottom arrangement. The requested palette replaces the boards' navy and purple color treatment. Keep the product name **Usisa** in the same brand positions; “PH Scam Detector” is descriptive reference copy, not a product rename.

### Board 1: welcome, Home, standard result, link checker, SMS detection, Learn

1. **Welcome:** status bar; large centered shield illustration; product name; two/three lines of centered explanatory copy; three small page dots; wide bottom **Get Started** button.
2. **Home:** top brand row with icon/name and notification button; two-column hero composition with headline left and illustration right; four scan-action cards in a two-by-two grid (message, link, screenshot, AI scan); SMS detection card with right-aligned toggle; fixed bottom bar with Home, History, Learn, Settings.
3. **Scan Result:** back/title row; full-width high/caution/low banner with icon and short explanation; rounded source/message panel; **Detected Warning Signs** title and one grouped list of evidence rows; wide **Safety Recommendations** button at the bottom of the visible content.
4. **Link Checker:** back/title row; URL field with link icon and clear button; full-width **Check Link** button; risk banner; **Why Is It Risky?** heading; grouped explanation rows with icons.
5. **SMS Detection:** back/title row and active toggle aligned to the right; short explanatory paragraph; **Recent Detections** heading; vertically stacked compact detection cards with source, truncated preview, risk chip, time, and chevron.
6. **Learn & Stay Safe:** centered title; wide illustrated **Scam Safety Tips** card; **Common Scams in PH** heading; three full-width category cards for bank/e-wallet, government impersonation, and online selling.

### Board 2: AI introduction, input choice, progress, AI result

7. **AI Scan introduction:** back/title row with **Beta** pill; centered AI/document illustration; **AI-Powered Scam Analysis** heading and short description; three compact benefit rows (Multi-input, Context-aware, Actionable results); wide **Start AI Scan** button at the bottom.
8. **AI input choice:** back/title row; **What do you want to analyze?** heading; three stacked cards for **Text / Message**, **URL / Link**, and **Screenshot / Image** with one-line descriptions and chevrons; decorative AI illustration near the lower edge.
9. **Analyzing with AI:** back/title row; centered activity illustration; **Analyzing with AI…** status; compact stage list. A stage changes only when its real work starts or completes: reviewed text confirmed, on-device checks complete, AI request in flight, response validated. Do not imitate model thoughts or show a fabricated percentage; expose **Cancel** and preserve the reviewed text.
10. **AI Scan Result:** back/title row; risk banner; separate **AI Analysis** panel with attribution; **Detected Warning Signs** list; wide **Safety Recommendations** button. Keep local findings and AI assessment clearly attributed and explain disagreement.

The AI flow includes one necessary review/confirmation state between input selection and network analysis, even though that privacy step is absent from the reference board. Show the exact editable text and the destination before asking the user to confirm. AI screenshot input is OCR'd locally and reviewed as text. A URL entered here receives the separate online reputation check only with its own consent.

### Board 3: Additional flows (grouped under reference panel 13)

13a. **Screenshot text review:** keep the selected screenshot visible above the editable OCR text. Label the text as extracted, allow correction, and use **Check This Text** for a local scan or **Analyze with AI** to continue to the separate AI disclosure and confirmation.
13b. **AI submission review:** show the editable text and its input type, explain what will leave the device and reach Groq, and offer a clear **Analyze Now** confirmation plus a local-only option and Cancel. Never auto-submit OCR text.
13c. **SMS review:** show only the explicitly processed temporary SMS content and the available local scan result. Do not claim to block a sender or report to a third party; those actions are not implemented and require a separate product and platform design.

Across all boards, preserve the generous rounded cards, consistent icon-left/content/chevron-right alignment, clear vertical grouping, and fixed bottom primary actions shown in the reference. Keep long text scrollable instead of compressing it. The screenshot's sample names, domains, statuses, and risk outcomes are illustrative only; use synthetic data and reserved example domains in design/build previews.

## 6. Visual system

The screenshot composition is retained, with the exact palette supplied for this revision. The UI/UX Pro Max design-system query returned a generic corporate palette, which is superseded by the user's explicit colors. Its Flutter guidance supports constraint-based layouts and typed navigation.

### 60:30:10 color distribution

Apply these exact colors as the brand's approximate visual-area balance. Dark appearance is not supported; the app always uses this light palette regardless of the system appearance setting:

| Share | Color | Primary use |
|---|---|---|
| 60% | Warm neutral #EEE5D4 | Screen canvas, open space, onboarding background, and reading areas. |
| 30% | Forest green #1D4A35 | Brand structure, selected navigation, primary buttons, major cards, headings, and controls. Use cream foregrounds on green fills. |
| 10% | Coral #F2452E | Small visual accents, risk emphasis, selected-state markers, and carefully chosen illustration details. |

Percentages describe overall visual weight, not exact per-screen pixel counts. Keep the main screen calm: use the cream canvas as the dominant field, green for important surfaces and actions, and coral sparingly. Do not tint every icon, card, and heading coral. Evaluate each text/control pair in its final light-state composition, including large text and selected, pressed, focused, disabled, warning, and error states.

Contrast is a constraint on the supplied colors: #EEE5D4 against #1D4A35 is 8.06:1; #F2452E is only 2.96:1 against cream and 2.72:1 against forest green. Therefore, never use the exact coral for body text, small labels, essential icons, or control outlines. Use it as decorative emphasis only, or use a contrast-checked darker coral tone derived from it for high-risk text on cream. Risk remains explicitly named with an icon and text; color alone never signals danger. Green is the brand color, not proof that a sender or link is legitimate. Keep large warning text on a high-contrast cream/green surface.

### Semantic tokens

Map colors through Flutter ThemeData/ColorScheme and the shared risk-color helper; don't scatter raw hex values through screens.

| Role | Light appearance |
|---|---|
| Background | #EEE5D4 |
| Primary surface / main action | #1D4A35 |
| Primary on-surface text | #1D4A35 |
| On primary surface/action | #EEE5D4 |
| Accent marker | #F2452E (decorative; pair with a visible label) |
| High risk label | Contrast coral #B92E22 or forest text on cream |
| Caution / low / unknown | Explicit icon, shape, and text; no new brand hue required |

Use high-contrast derived neutral/green surface tones only when needed for grouped cards, inputs, dividers, and focus states. These tones are supporting shades of the three specified colors, not new brand colors. The exact 60:30:10 base remains unchanged.

### Typography

Use the native system font (Roboto on Android; platform system font on iOS) with a clear hierarchy. All measurements are Flutter logical pixels before the OS text scaler.

| Role | Size / line height | Weight |
|---|---|---|
| Home headline | 28–30 / 34–36 | 700 |
| Risk headline | 24–28 / 30–34 | 700 |
| Screen title | 22–24 / 28–30 | 600 |
| Section title | 18–20 / 24–26 | 600 |
| Body and entered message | 16 / 24 | 400 |
| Action label | 16 / 22 | 600 |
| Supporting text | 14 / 20 | 400 |
| Navigation label | 12 / 16 | 500 |

Use sentence case, readable left alignment for multi-line content, and slightly tighter leading only for large headings. Never shrink warning or evidence text to fit a fixed-height card. Respect OS text scaling and allow cards to grow.

### Layout, illustration, and components

- Use the screenshot's card sequence and rounded, compact grouping. Spacing follows 4, 8, 12, 16, 24, 32, 48 logical pixels.
- Phone side gutters are 20 logical pixels, reduced to 16 below 360; tablet gutters are 32. Use LayoutBuilder and content constraints rather than fixed device dimensions.
- Keep the same 4 root destinations on compact phones; adapt to a labeled rail on wide screens. Long-form results and Learn articles use a comfortable reading width.
- Card and field corners are 16; large feature surfaces 20; bottom sheets 24 at the top edge. Use flat grouping and subtle elevation rather than stacked glass effects.
- Buttons are at least 52 high, and every touch target is at least 48 × 48 dp on Android (44 pt on iOS); adjacent small controls have at least 8 dp separation.
- Use one consistent Material vector icon family. Prefer the existing platform icon font; no emoji as structural icons. Provide a visible label for every risk and icon-only control.
- Build the shield, link, screenshot/OCR, and AI illustrations as a restrained vector family using cream, forest green, and limited coral. Keep the reference placement and scale, but remove its purple glow, glossy metal, and excess decorative sparkles.
- Respect status/navigation bars, safe areas, keyboard insets, Back, landscape, and vertical scrolling. Never crop a URL host or place a CTA behind a system bar.

### Motion and feedback

Press feedback begins on touch-down within one frame and changes opacity/elevation without moving surrounding layout. Keep navigation on the platform's familiar path; entering and leaving a route use spatially consistent transitions. Gesture-driven onboarding or sheet movement follows the finger and remains interruptible. Use a critically damped spring or the equivalent native Flutter curve for ordinary state transitions; reserve slight bounce for momentum from a user gesture.

Default transitions stay short and purposeful: roughly 100 ms press feedback, 150 ms inline status change, and 200–250 ms for a route/sheet. These are guidance, not delays before accepting input. Respect reduced motion by removing parallax/translation and using brief crossfades. Never add looping background motion, flashing alerts, haptic noise, confetti, or fake AI progress. Shimmer and skeletons appear only when a measurable wait justifies them; preserve layout space and never delay a completed result.

## 7. Risk, coverage, and error contracts

Risk and completion are independent fields. Completed local analysis produces `low`, `caution`, or `high`; `unableToAssess` is a separate result state with no risk value. Link reputation state is one of `notRequested`, `checking`, `matched`, `noMatch`, or `unavailable`.

Proposed first rule policy, versioned as `rules-v1`:

| Evidence | Classification |
|---|---|
| Current Safe Browsing response reports a threat | High risk within its lifetime; name the threat category and source. |
| A request to disclose an OTP/password/PIN, or send money, combined with impersonation or pressure | High risk. Detect a request, not the mere presence of the word OTP. |
| Any other supported warning rule or URL anomaly | Caution; explain the exact finding. Brand mention or a legitimate OTP warning alone is not a warning rule. |
| No supported warning found after completed local analysis | Low risk, with the authenticity limitation. |
| Empty/unsupported input or analysis failed | No risk value; explain how to correct/retry. |

This is a proposed heuristic decision policy, not calibrated detection performance. Start with English/Filipino request, urgency, impersonation, prize, and advance-fee phrases; include negation and ordinary legitimate examples. Keep original text for evidence; normalization must retain a source-offset map or return explicit original spans. Never let case-folding/Unicode normalization corrupt evidence positions.

For links, flag credential-in-URL syntax, raw IP hosts, deceptive brand placement outside reviewed exact official domains, HTTP transport, recognized shorteners, and unusual/encoded host forms as separate observations. HTTPS, a `.ph` suffix, or a recognized domain does not prove the message legitimate. A no-match reputation response never clears a local finding. Do not claim to resolve shorteners, redirects, newly registered domains, or page content without implementing those checks.

| State | Required behavior |
|---|---|
| Initial / no history | One next action; distinguish retention off from an empty saved list. |
| Invalid input | Inline field error after submit/blur; preserve original content. |
| Reading screenshot | Preserve image and controls; cancellation is available. |
| Checking message/links | Keep input available; prevent duplicate submission for that revision. |
| Partial / offline | Show completed local findings plus “Link reputation not checked” or “Link check unavailable.” Retry only the failed lookup. |
| Scan failed | No low-risk fallback; retain text and show Retry. |
| Permission denied/revoked | Accurate capability status and Settings/manual-scan recovery. |
| Nothing matched filters | Explain active filters; offer Clear filters. |
| Missing saved scan | Explain it is unavailable and offer History/new scan. |
| Save failed | Keep session result visible and mark “Not saved”; do not claim persistence. |

No-result and not-checked link states never use a green success checkmark. When local findings are low but a link remains unchecked, the coverage notice appears beside the headline and says **“Link safety is unknown.”**

## 8. All 20 requested UX patterns

| # | Pattern | Application to Usisa |
|---|---|---|
| 1 | Optimistic UI updates | Adapt: immediate benign preference changes with rollback on save failure. Risk verdicts, permission grants, and completed checks wait for real confirmation. |
| 2 | Skeleton loaders | Adapt: explicit progress indicators during local initialization, OCR and SMS review. Defer list skeletons until a measured wait warrants them; no fabricated scan verdicts. |
| 3 | Command palette | Defer: direct scan actions fit a phone better. Reconsider for a larger desktop product. |
| 4 | Persistent sidebar navigation | Adapt: the reference uses labeled Home, History, Learn, and Settings bottom navigation on phones; use a rail on wider layouts and preserve drafts/scroll state. |
| 5 | Loading and empty states | Adopt: specify initial, empty, filtered-empty, loading, partial, offline, denied, failed, and success states. |
| 6 | Autosave | Adapt: preferences automatically save; in-memory input survives navigation; persistent drafts require opt-in. |
| 7 | Debouncing | Adopt: 300 ms history search; no automatic network requests while typing a message. |
| 8 | Throttling | Adapt: one active scan per revision, duplicate SMS event suppression, bounded server requests; distinct messages must not disappear. |
| 9 | Smart form validation | Adopt: visible labels, inline correction, whitespace checks, explicit input limits, and HTTP(S)-only URL mode. |
| 10 | Bulk list actions | Adopt for retained history: explicit selection, count, clear selection, and confirmed deletion. |
| 11 | Reusable data table | Adapt: shared history rows, filters and selection in a width-limited list; details open as a secondary route. No horizontally scrolling phone table. |
| 12 | Advanced filtering | Adopt a small useful subset: risk, source, date, combined search, count, and removable filters. |
| 13 | Keyboard shortcuts | Adapt: standard editing, focus traversal, Escape/back dismiss, Enter search; accessible visible actions remain primary. Multiline Enter inserts a newline. |
| 14 | Tier-based indicators | Adapt to risk labels with icon and explanation; no subscription tiers. Unavailable is not a risk tier. |
| 15 | Onboarding data capture | Adapt: match the three-dot welcome layout and Get Started action; collect no name/email/phone or account data. Language and privacy preferences live in Settings; permissions are requested only when used. |
| 16 | Referral and affiliate pages | Defer: outside the scam-checking task; never encourage sharing private scan content for growth. |
| 17 | Custom 404 page | Adapt: recoverable missing/deleted result route, including expired notification targets. |
| 18 | Mobile-optimized layouts | Adopt: 320 logical pixels upward, thumb-reachable actions, safe areas, keyboard handling, scalable text, tablet rail. |
| 19 | Destructive action protection | Adopt: confirmation for bulk/all deletion, reliable single-delete Undo, explicit draft clearing. |
| 20 | Graceful error recovery | Adopt: retained input, partial findings, specific Retry, cancellation and stale-response protection. |

## 9. Data, security, and platform boundaries

- Limit manual input to 10,000 Unicode code points, a URL to 2,048 characters, and ten distinct URLs per scan. Refuse excess with an editable explanation; never silently truncate. Preserve duplicate occurrences for evidence while looking up each distinct URL once.
- Decode images off the UI thread with a 20 MB compressed-file and 20-megapixel decoded-image ceiling; validate before OCR and explain oversized/unsupported files. Select suitable image scaling without discarding legible text.
- Keep ordinary session input/results in memory. Optional encrypted history exposes the latest 100 completed scans for at most 30 days; one optional encrypted text draft can be restored within 24 hours. Expired content is rejected on access, cleaned at foreground expiry deadlines, and cleaned again on startup/resume even when draft restoration is off. A closed/stopped app cannot guarantee physical deletion at an exact deadline: encrypted files can remain until next use. Disclose this before opt-in, surface cleanup failure, and offer immediate Clear saved data. Never retain screenshot files in history.
- Show the provider and last checked time next to each link. Safe Browsing warnings expire at the returned lifetime or a five-minute ceiling, whichever is sooner; request duration is subtracted and deadlines use device time to avoid server clock skew extending warnings. Expired Safe Browsing evidence cannot raise risk or show Google attribution; independent local findings remain. Permanent history saves local findings and check/source metadata without caching Safe Browsing verdicts. Existing Web Risk records keep their original source and explicitly historical warnings; they are never relabeled as Safe Browsing. No timer issues network requests.
- Scheme-less domain links are inspected with an explicitly disclosed assumed HTTPS scheme; the original text is preserved, and consent shows the exact URL to transmit. This does not fetch the page or validate HTTPS legitimacy.
- Prefer `flutter_secure_storage` for this bounded prototype store after measuring target-device size/latency. Persist each record separately and serialize mutations. If measured limits require a database, switch to an encrypted database rather than placing message content in preferences or plaintext files.
- Exclude retained scan content and temporary SMS data from Android cloud/device-transfer backups; persistent storage failure must be visible. Clearing saved data cancels in-flight saves and clears private drafts, history, and pending retained scan data without deleting phone SMS.
- Consent to URL reputation checking explains that the full URL, including path/query, reaches Usisa's gateway and its named reputation provider. That endpoint receives no message text, separately collected sender metadata, or screenshot. The separately consented AI endpoint receives only the final reviewed text and requested response language. Offer local-only checking. No background SMS uploads.
- A small service gateway keeps provider credentials server-side. URL reputation and AI scanning use separate endpoints and consent boundaries. Outbound calls use fixed provider APIs; never fetch submitted pages, expand redirects, or resolve arbitrary targets. Apply input limits, timeouts, abuse limits, and sanitized logs without URLs/message bodies. An embedded mobile secret is not authentication.
- Reputation provider: Google Safe Browsing v4 Lookup for the confirmed noncommercial school/research scope, with server-only credentials. Require re-consent under disclosure version2, qualified warning copy and linked Google advisory attribution only for current Google evidence. Provider no-match means not listed, not safe. Reassess licensing before commercial use.
- SMS support is a gated Android capability, not a switch that can manufacture permission eligibility. Google Play restricts SMS permissions and its anti-smishing exception has evidence/review requirements. Prototype receipt and background processing on actual target Android versions before promising the feature. [SMS policy](https://support.google.com/googleplay/android-developer/answer/10208820)
- Request only capabilities actually used: no contact access, SMS sending/deletion, bulk inbox reading, accessibility-service scraping, or notification-listener workaround. Runtime consent and store approval are separate requirements.
- SMS alerts are generic by default: “A message needs your review.” No sender/body/URL on the lock screen. Notification permission is separate on Android 13+. Turning checks off stops new processing and clears pending jobs. [Android notifications](https://developer.android.com/develop/ui/compose/notifications/notification-permission)
- Enabling SMS checks also discloses temporary encrypted processing storage: at most 20 events, expiring 15 minutes after receipt, excluded from backup. This is separate from optional permanent history. Alerts may be delayed by Android scheduling; no checks are promised while force-stopped. If the queue fills, mark checks degraded and report that some messages could not be checked instead of silently claiming coverage. [Android persistent work](https://developer.android.com/develop/background-work/background-tasks/persistent)
- The native temporary SMS queue owns a durable privacy generation and serialized commit gate. Each event captures it; completion and notification dispatch recheck it. Disabling SMS or clearing saved data invalidates pending work and erases its records/notifications. Permanent history has one foreground writer with an independent erasure generation; clear-all waits for both native invalidation and serialized local erasure. Foreground import captures both scopes, so a delayed import cannot undo a clear. History and draft preferences remain independent. A future background history writer must use a durable shared gate before it is introduced.
- Temporary SMS reviews become inaccessible after 15 minutes. WorkManager schedules encrypted-file cleanup, and every queue access also rejects/deletes expired content. Android can delay cleanup or prevent it while force-stopped; physical deletion at an exact wall-clock deadline is not promised. Only a result explicitly opened with history enabled may remain in the separate 30-day history.

## 10. Accessibility, evaluation, and completion

Design and implementation must support TalkBack, logical focus order, meaningful control labels, selected/disabled states, visible focus, and a single announcement of result/error changes. All gesture actions have buttons. Color, haptics, and animation never carry risk meaning alone.

Require 4.5:1 contrast for ordinary text and 3:1 for large text and essential control outlines. Validate actual composed controls in the fixed light palette. Check at 320, 390, 600, and 840 logical pixels, landscape, keyboard open, and at least 200% text scaling; do not clamp OS scaling. The reading order is risk, coverage, recommendation, evidence, then details. [Flutter accessibility](https://docs.flutter.dev/ui/accessibility)

Use synthetic/de-identified English, Filipino, and Taglish evaluation cases, including legitimate bank notices, legitimate OTP warnings, payment requests, hostile URLs, and ambiguous messages. Keep rule-development examples separate from held-out evaluation. Report precision, recall, false-positive rate, per-language/per-category results, and sample counts; set deployment thresholds from reviewed data rather than claiming an invented accuracy figure. Evaluate OCR transcription separately because an incorrect URL changes the subsequent check.

The user bypassed independent PH labeling and Filipino-copy review for the development handoff. Those checks remain unverified. The frozen public-data baseline in `docs/public-dataset-baseline-2026-11-10.md` reports source-category counts and historical smishing-label comparisons, with explicit exclusions; it establishes no PH accuracy or measured AI improvement.

Acceptance includes no/one/100 retained scans; storage expiry; long emoji/combining-character text; URLs with long queries and deceptive hosts; blank/partial OCR; multiple mixed-status links; offline launch; network loss; cancelled/retried scan; permission revocation; background app/process loss; expired notification targets; fixed light appearance under both system appearance settings; large text; and reduced motion.

Success criteria: a person can start a manual scan without an account or SMS permission, understand a finding and next step, see exactly which checks were incomplete, recover input after failure, and erase retained app data. Public claims about detection and automatic SMS availability require evaluation and platform evidence.

## 11. Design sources and remaining release decisions

This revision applies Apple Design principles (purpose, agency, responsibility, familiarity, flexibility, simplicity, craft, delight; immediate feedback; spatial consistency; interruptible motion; reduced motion) and UI/UX Pro Max accessibility, touch-target, responsive-layout, and Flutter guidance. The Pro Max generated style/palette was not adopted because the user supplied an exact screen reference and palette. CSS/React/GSAP prescriptions do not apply to this Flutter specification. Current implementation/evidence is recorded in README and the completion audit.

Primary technical references checked on 9 November 2026:

- [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations): adapt SDK state and separation of concerns to project size.
- [ML Kit text recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2/android): bundled recognizer supports immediate model availability; follow its current SDK requirements when selecting the Flutter wrapper.
- [Web Risk Lookup](https://docs.cloud.google.com/web-risk/docs/lookup-api): URL threat-list lookup with match types and expiration.
- [Safe Browsing Lookup](https://developers.google.com/safe-browsing/v4/lookup-api) and [usage requirements](https://developers.google.com/safe-browsing/v4/usage-limits): current free noncommercial provider, attribution and warning expiry.
- [Android broadcasts](https://developer.android.com/develop/background-work/background-tasks/broadcasts/broadcast-exceptions): background broadcast rules are only one part of capability feasibility.

Release decisions with external dependencies: SMS distribution/permission eligibility, public gateway hosting/quotas, final application ID and signing identity, reviewed local language content, and measured detection thresholds. Local Safe Browsing credentials and live validation are complete; no public hosting or production-release readiness is implied.

## 12. Groq AI-assisted scanning

Planned on 9 November and explicitly included in the MVP by the user on 10 November 2026. Implemented with server-only Groq calls, editable review, per-submission confirmation and separate local/AI evidence. Detailed delivery plan: [Groq AI scanning](docs/superpowers/plans/2026-11-09-groq-ai-scanning.md).

### Purpose and analysis modes

The local algorithm remains fast, offline, and useful for consented incoming SMS. Optional AI analysis adds context for indirect requests, paraphrases, mixed Taglish, and wording designed to avoid simple phrase rules. Both approaches can be bypassed and can misclassify content; do not describe AI as foolproof or assume broader language accuracy without evaluation.

The Home **AI Scan** card opens the introduction shown in Board 2 and then offers Text/Message, URL/Link, and Screenshot/Image inputs. Keep ordinary on-device scanning as the default route and make the AI route visibly labeled Beta until evaluation justifies broader claims. AI scans still run local checks alongside an independent AI assessment; never send local scores/findings to the model or make the AI merely restate the algorithm. AI selection never changes automatic SMS behavior.

### User journey and privacy

1. Enter/paste text or review locally extracted screenshot text.
2. Select **AI assisted** and tap **Review for AI check**.
3. Show the exact editable text that will leave the device. Explain: “This text will be sent to Usisa's server and Groq for an AI assessment. Remove any codes or personal details you do not want to share.” Names, numbers and URLs inside that text are included unless the user edits them. Do not promise automatic removal of sensitive data.
4. **Send this text for AI check** confirms only this submission. **Keep on device** returns to local analysis. No AI uploads from typing, clipboard polling, background tasks, or opening a saved result. No persistent conversation is created.
5. Run local analysis on the final reviewed text as well. If the user changed the text, mark it as the reviewed version; do not merge results from two different texts into one verdict.
6. Preserve the input and completed local result while AI is checking. Offer Cancel, then retry only on an explicit action after failure.

OCR remains on-device; the image, image metadata, contacts and separately collected SMS sender data never go to the AI endpoint. An SMS result can be sent only after the user opens it, reviews the text and confirms the manual action. URL reputation consent does not authorize AI text uploads; AI consent does not enable URL reputation checks.

### Result presentation

Show one conservative headline plus separate **On-device findings** and **AI assessment** sections. The overall assessed risk is the highest of local risk, validated AI risk, and a matched reputation threat. AI low risk never erases a deterministic warning or a threat-list match. Explain disagreement instead of implying consensus.

AI coverage states: not requested, checking, completed, unable to assess, unavailable, and cancelled. A timeout/refusal/schema failure is not low risk. Use “On-device checks complete; AI assessment unavailable” when appropriate. An AI-only high finding is visibly attributed to AI and accompanied by its matching quoted evidence. No confidence percentage, “AI verified,” or “safe” certification.

Require short quoted evidence that appears exactly in the submitted reviewed text; validate it server-side and independently on the device. Discard the model's free-form summary at the gateway. The response carries the fixed `assessment_complete` summary code, and the app explains risk, warning codes and recommendations using reviewed English/Filipino copy. This prevents invented contact details or links in model prose from becoming advice. Older retained prose is discarded while validated evidence remains. The model must not claim to have visited URLs or assert real-time threat intelligence. A separate reputation service owns that check.

The same cream/forest/coral palette, contrast rules, type scale, loading states, reduced motion and 48-pixel hit targets apply. AI uses the same restrained illustration family and action system; it does not add a purple palette, chat UI, animated mascot, or fake thinking progress.

### Model and configuration

The configured development model is `openai/gpt-oss-120b`, with prompt `ph-scam-v1`, low reasoning effort, strict structured output and suppressed reasoning output. Compare `openai/gpt-oss-20b` for latency/cost before changing the default. Both support strict structured outputs; there is no automatic fallback model. A 20-message held-out synthetic diagnostic is recorded in `docs/ai-evaluation.md`; it does not establish real-world Philippine scam accuracy. [Models](https://console.groq.com/docs/models), [structured outputs](https://console.groq.com/docs/structured-outputs)

Use server-only `GROQ_API_KEY` and `GROQ_MODEL`. The ignored worktree-root `.env` already contains both; implementation changed neither value. No key belongs in Flutter assets, Dart defines, source, logs or browser bundles. Only synthetic fixtures were used for live verification. Standard APKs need a configured public gateway URL to use AI; emulator development uses `http://10.0.2.2:8787`.

The loopback gateway limits AI to ten requests/minute/socket IP, four concurrent calls and 50 calls/day/process by default (`AI_DAILY_LIMIT`). Its daily counter resets on restart and is not an account spending limit. It coalesces matching in-flight submission keys and aborts disconnected work where possible, with a 15-second provider deadline and no automatic retries. Mobile requests time out after 18 seconds; cancellation or backgrounding makes late responses inert. Reopening history never resumes an upload. Public deployment needs trusted ingress and verified account spending controls.

Review Groq account data controls before release. Provider retention depends on those controls and service conditions; do not promise zero retention from an API key alone. The app gateway does not retain raw prompts or responses in logs, caches, traces, or analytics. [Groq data controls](https://console.groq.com/docs/your-data)
