# Is the Yissuh Filipino SMS dataset usable for scam measurement?

Ticket: heliokii/Usisa#7. Checked 2026-11-21 against
[Yissuh/Filipino-Spam-SMS-Detection-Model](https://github.com/Yissuh/Filipino-Spam-SMS-Detection-Model)
at its default branch (last push 2023-12-10). Terms follow `GLOSSARY.md`: a **Scam** tries to take money,
account access or personal info; a **Harmless promo** is everyday "spam" and gets **Looks safe**.

## Short answer

**Partly usable, and only after relabelling.** The licence is permissive and the data is real Philippine SMS
from 2022-2023, but it is small (873 rows, 561 labelled `spam`) and its `spam` label does not mean Scam.
In a 100-row sample of `spam` rows, about **19% are Scams**, **4% are Harmless promos**, 1% is a mislabelled
OTP code, and **about 76% are online gambling/casino ads**. Usisa's glossary has no category for gambling ads
yet. Someone has to decide how to treat them before this data can measure verdicts. The `ham` side is useful
as-is for false positives: it has real personal texts, OTPs, receipts and telco/e-wallet promos.

## Licence

- BSD 3-Clause (`LICENSE`, "Copyright (c) 2023, Alexander"; GitHub API reports `bsd-3-clause`).
- Reuse, including redistributing derived files, is allowed if the copyright notice and disclaimer are kept.
  The licence does not cover the SMS senders' text or any personal data left in it (see Privacy below).
- Provenance is not documented. The README only says it is a third-year Data Analytics project at TUP Manila.
  It does not say how messages were collected or labelled, or who labelled them.

## Files

| File | What it is |
|---|---|
| `data-set.csv` | 625 rows, `label,message`. Not valid UTF-8 (Latin-1/mixed; mixed CRLF/LF/NEL line endings). |
| `merged-set.csv` | 873 rows, `label,message`, UTF-8. A superset: 603 of its rows appear verbatim in `data-set.csv`, plus about 250 extra spam rows. **This is the file the notebook trains on** (`pd.read_csv('merged-set.csv', encoding="ISO-8859-1")`). |
| `spam-detection.ipynb` | Training notebook (1.5 MB, has outputs, no markdown explanation). |
| `spam_model.joblib`, `vectorizer.joblib` | Pickled model and vectorizer. **Do not load them**: unpickling runs arbitrary code. |
| `all_links.py` | A Python list of about 150 spam URLs and domains (mostly casino sites, a few phishing domains such as a `binance-com.web.app` lookalike). |
| `brands.py`, `my_stopwords.py`, `spell_corrector.py`, `sample_usage.py`, `__pycache__/` | Preprocessing helpers. Not data. |

## Rows, labels, duplicates

| | `data-set.csv` | `merged-set.csv` |
|---|---|---|
| Rows | 625 | 873 |
| `spam` / `ham` | 313 / 312 | 561 / 312 |
| Exact duplicates (case-insensitive, beyond first) | 3 | 19 |
| Near-duplicates (digits and punctuation stripped) | 23 | 41 |
| Rows containing a URL/domain | 314 | 517 |

Columns are just `label` (`spam`/`ham`) and `message`. There is no date, sender, language or sub-category
column. Names are mostly masked as `<REAL NAME>`, with some `<AMOUNT>`, `<CODE>` and `<REFERENCE NUMBER>`.

The duplicate counts understate redundancy. Many spam rows come from the same template with only the domain
changed ("Claim the BARAHA B0NUS ... web: pinasX.life", W+/WinningPlus, SBET, 177BET, PWIN777). As a rough
estimate, 561 spam rows hold about 200-300 distinct templates.

There is **label noise across classes**: a Facebook OTP code is labelled `spam`, and a near-identical Cashbee
loan-app ad appears once as `spam` and once as `ham`.

## Language mix

These counts come from a word-list heuristic over `merged-set.csv` (common Tagalog function words vs common
English words), so treat them as rough:

| | English | Filipino | Taglish | Too short / unknown |
|---|---|---|---|---|
| spam (561) | 370 (66%) | 129 (23%) | 41 (7%) | 21 |
| ham (312) | 108 (35%) | 147 (47%) | 19 (6%) | 38 |

Spam leans English because most casino blasts are English templates. Ham leans Filipino and text-speak
("Gud am pwd bng pki punta ka d2"), which the synthetic fixtures barely cover.

## What the `spam` rows actually are (sample of 100)

I took 100 `spam` rows from `merged-set.csv` (Python `random.seed(7)`, `random.sample`) and classified each
one by hand using the glossary:

| Bucket | Count | Examples (paraphrased) |
|---|---|---|
| **Scam**: phishing / account access | 6 | "[BDO-ALERT] account on hold, verify at onlinebdo-banking.online", GCash "on-hold, verify" via iplogger.org, casino-membership "update your info" form |
| **Scam**: fake prize / "free money" bait | 6 | "you have won the prize 999P to enter ccb8.xyz", "free money 500 with no deposit condition, please login ..." |
| **Scam**: job / task / investment | 5 | "promoter, daily salary", "Araw-araw na suweldo 5000, 1-2 hours a day", "one registration from becoming a millionaire" app |
| **Scam**: advance-fee loan / email lure | 2 | "Mr. Michael ... unsecured loan 100k-5M, reply YES", "respond to this email for good news" |
| **Gambling ad** (online casino, sabong, slots, bingo) | 76 | "Register at <casino>, 100% deposit bonus, gcash", sabong rebates, "JILI GAMES LIBRENG 1088P" |
| **Harmless promo** | 4 | Lazada solar-light sale, condo listing, bingo-hall event, registered lending-app ad |
| **Other / mislabelled** | 1 | Facebook OTP code |

So about **19% Scam / 76% gambling ad / 4% Harmless promo / 1% other**. With n=100 the uncertainty on each
share is about ±8 points.

Why gambling ads are a separate bucket: most push unsolicited deposits to throwaway domains (`*.xyz`,
`*.life`, `*.pw`, rotating `wplus*`/`sbet*` names) and look like unlicensed operators. Some (for example
BingoPlus) are licensed brands. Under the current glossary they are neither clearly a Scam nor clearly a
Harmless promo. **Product decision needed:** do unsolicited gambling ads get Looks safe, Be careful, or a
split by licensed vs throwaway-domain? The decision changes the dataset's scam share from about 19% to about
95%.

The `ham` rows (skimmed 50) are roughly 40% personal chat, 30% transactional (OTPs, GCash/Maya receipts,
deliveries, contribution postings), 20% telco/e-wallet promos (Smart, Globe, Maya, GCash) and 10% government
or NTC scam advisories. That makes `ham` a good **Looks safe** set, including hard cases: real promos, OTP
messages that say "don't share", and advisories that contain the word "SCAM".

## Effort to relabel scam vs harmless

- Pass 1: cluster near-duplicate templates, then label 200-300 templates and propagate. About **2-3 hours**
  for one person at about 30 s per template.
- Pass 2: a second person labels a 100-row overlap to check agreement. About **30-45 min**.
- Ham check: skim 312 rows for mislabels such as OTP or loan-ad rows that sit on the wrong side. About **1 hour**.
- Total: **about half a day**, plus the gambling-policy decision, which matters more than the labelling time.
  Expected yield: only about **100-110 real Scam rows** (19% of 561), heavily weighted to BDO/GCash phishing
  and prize bait. Coverage of seller, government-ayuda or OTP-relay scams is thin.

## Comparison with Usisa's synthetic fixtures

| | `evaluation_messages.json` | `ai_messages.json` | Yissuh `merged-set.csv` |
|---|---|---|---|
| Rows | 36 | 26 | 873 |
| Scam / not / ambiguous | 20 / 12 / 4 | 13 / 10 / 3 | about 105 / about 770 incl. gambling (after relabel) |
| Languages | 8 each of English, Filipino, Taglish, obfuscated, plus 4 ambiguous | 9 English / 8 Filipino / 9 Taglish | about 55% English, 32% Filipino, 7% Taglish |
| Categories | bank, wallet, government, seller, prize, link, obfuscation, paraphrase... | adds OTP reminder, prompt injection, safety advice | casino ads dominate; phishing, prize, job scams |
| Real or synthetic | synthetic, balanced | synthetic, dev/held-out split | real 2022-23 SMS, unbalanced |

The two complement each other. The fixtures cover scam *types* evenly but have **no gambling-ad and no
telco/e-wallet promo category**, which are the two biggest real-world classes here. The Yissuh ham set would
add realistic Harmless-promo and transactional negatives that the fixtures lack. If anything is imported,
import a **small, hand-picked, rewritten subset** (for example 20-40 templates with domains and names
replaced) as a new fixture, not the raw CSV.

## Privacy

Masking is incomplete. One row still has a surname after `<REAL NAME>`, one starts "Dear <first name>", and
some ham rows contain partially masked phone numbers and GCash sender names. Do not copy raw rows into the
repo. Rewrite anything that gets imported.

## Other public PH sources

- **Kaggle "Philippine Spam/Scam SMS" by bwandowando**
  ([dataset](https://www.kaggle.com/datasets/bwandowando/philippine-spam-sms-messages)). Spam and scam texts
  the owner personally received, version 51, about 234 KB, updates stopped around Aug 2024.
  **Licence CC BY-NC-SA 4.0**: non-commercial and share-alike, so check that it fits Usisa's distribution
  before bundling any of it. It is spam-only (no ham) and larger and more recent than Yissuh. It is the best
  next candidate.
- **mematello/taglish-spam-detection** (GitHub, no licence file): `dataset/final_spam_ham_dataset.csv`, 7,507
  rows merged from an English spam set and a Filipino spam set. With no licence, reuse is not allowed by
  default. Useful only to look at for ideas.
- **Ronn02/BERT-TagalogSpamDetection** (GitHub, no licence): small `dataset.csv` (about 26 KB). Same
  licence problem.
- **drvii/data-analysis-spam-sms-ph**: an analysis of the bwandowando Kaggle set (its `dataset.csv` is a copy
  of it). Not an independent source.
- No public, labelled *scam-vs-promo* PH dataset turned up. Official advisories (NTC, CICC / Scam Watch
  Pilipinas, bank and e-wallet security pages) are good sources for writing new synthetic Scam fixtures, but
  they are not datasets.

## Method / sources

- Repo metadata and licence: `gh api repos/Yissuh/Filipino-Spam-SMS-Detection-Model`; files from a shallow
  clone, read as data only (no notebook, script or joblib file was run or loaded).
- Counts, duplicates and the language heuristic: small throwaway Python scripts run outside the clone with
  `python -I`. The 100-row sample used `random.seed(7)` over `merged-set.csv` `spam` rows.
- Fixture counts: `test/fixtures/evaluation_messages.json`, `test/fixtures/ai_messages.json` on `main`
  (a862497).
- Other sources: `gh search repos` plus each repo's API metadata and README; Kaggle metadata from
  `kaggle.com/api/v1/datasets/view/bwandowando/philippine-spam-sms-messages`.
