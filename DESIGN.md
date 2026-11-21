# DESIGN.md

## Brief

- **Audience:** everyday smartphone owners in the Philippines, with emphasis on elderly people (low confidence with apps, weaker eyesight, wary of making mistakes). Many use Messenger daily and know chat UIs.
- **Purpose:** tell people, in one plain answer, whether a text, link or screenshot is a scam, and what to do next. Also protects them automatically from incoming scam SMS.
- **Tone:** calm, protective, plain-spoken. Like a careful relative, not a security product. Never alarmist on harmless content; firm on dangerous content.
- **Constraints:**
  - Flutter on Android (minSdk 24), English and Filipino.
  - Brand-new UI: do not reuse the old screens, widgets or design.
  - Bottom nav with four tabs: Check, History, Learn, Settings.
  - Four Verdicts only: Looks safe, Be careful, Dangerous, Couldn't check (see GLOSSARY.md).
  - On the verdict: Read aloud and Send to family. In-app text size setting that also respects the phone's setting.
  - Normal text size by default.
  - Colour is never the only carrier of meaning: every verdict has an icon and a word.
  - Touch targets at least 48dp. Contrast at least 4.5:1 for text.

## Tokens

Reference style supplied by the owner (indigo base, warm pastel accents, big rounded cards, geometric circles). Contrast computed with the WCAG formula.

| Token | Value | Use | Contrast |
|---|---|---|---|
| primary | #4A44C9 | header blocks, filled buttons, SMS card | white on it 7.1:1 |
| background | #EEF0FF | app background (lavender) | ink on it 13.8:1 |
| surface | #FFFFFF | sheets, cards | |
| ink | #1F1D4D | body text | 15.7:1 on white |
| ink-muted | #5B5A7A | secondary text | 6.6:1 on white |
| yellow | #FFD66B | accent shapes, message tile, switch track | ink on it 11.2:1 |
| lilac | #C9C7FF | link tile | ink on it 9.8:1 |
| mint | #A8E6D4 | screenshot tile | ink on it 11.1:1 |
| coral | #FFC2B8 (tile), #FF8A8A (dots) | AI scan tile, accent dots | ink on tile 10.2:1 |
| orange | #FF8A4C | header quarter shape (decoration only) | |
| safe | #166534 on #E8F6EC | Looks safe | 6.4:1 on tint |
| careful | #92400E on #FDF1DC | Be careful | 6.3:1 on tint |
| danger | #B91C1C on #FDE8E8 | Dangerous | 5.5:1 on tint |
| unknown | #334155 on #ECEFF3 | Couldn't check | 9.0:1 on tint |

- **Type:** a rounded geometric sans to match the references (pick in the build: e.g. Poppins or Quicksand, checked for legibility at small sizes); the prototype used the system font. Scale: 12 / 14 / 16 (body) / 20 / 24 / 32 (headline, verdict word).
- **Spacing:** 4, 8, 12, 14, 16, 20, 24, 28.
- **Radius:** 28 (tiles, cards), 36 (sheet top), stadium (buttons).
- **Shadow:** none; depth comes from colour blocks and the overlapping white sheet.

## Direction

Chosen: **Tile grid** (prototype variant A, round 3).

- **Home (Check tab):** an indigo header with a layered geometric composition (large yellow circle that drifts slowly, orange quarter shape, white ring, small dots) and a time-of-day greeting ("Magandang umaga/hapon/gabi!") over the headline "Is this text a scam?". A lavender sheet with a 36 radius top overlaps it. On the sheet: "What do you want to check?" and a 2x2 grid of bright tiles (Scan a message, Check a link, Scan a screenshot, AI scan), then the Auto SMS protection card.
- **Tiles carry no icons.** Each is identified by its colour, its own geometric motif in the top-right (two circles / quarter circle / dot cluster / ring), a bold title and a one-line subtitle.
- **Auto SMS protection card:** indigo, with title, status line ("12 texts checked today" / "Texts are not being checked") and a real switch (yellow track when on). Decoration stays on the left so nothing sits behind the switch.
- **Verdict screen:** a header block in the verdict's colour with circles, a plain white verdict icon, and the verdict word large. A white sheet holds: the action line in a tinted box, "Why" with up to 3 reasons, "Really goes to <real destination>" when there's a link, then two full-width stadium buttons, **Send to family** (filled indigo) and **Read aloud** (outlined), both text-only. "You checked" shows the original message last.
- **Bottom nav:** flat white with a hairline top border (no rounded corners), four tabs: Check, History, Learn, Settings. The nav is the only place with icons besides the verdict icon.
- **Icons:** used sparingly; never boxed in containers.
- **Motion:** a staggered entrance on home (fade + 16px rise, 320ms ease-out, 60ms apart), tile press scale to 0.96 (120ms), and a slow 6s drift on the big header circle. All of it is off when the phone asks for reduced motion.
- Prototype: branch `prototype/ui-direction`, `lib/prototype_ui/`.

## Decision log

- R0: Tokens proposed from ui-ux-pro-max output; verdict colours added; contrast computed (WCAG formula); safe darkened from #15803D (4.5:1) to #166534.
- R1: First prototype (One big button / Chat / Scale and steps) rejected by owner: wanted today's four-feature home and a modern style from supplied references.
- R2: Rebuilt in the reference style (Tile grid / Card list / Bold hero); owner picked Tile grid.
- R3: Removed boxed icons from tiles, SMS card and verdict buttons; flattened the nav (rounded corners showed the page colour); brighter tiles, layered header and motion added for "life"; the ON chip became a switch. Approved.
