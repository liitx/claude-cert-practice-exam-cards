# Claude Cert Practice Cards

Practice flashcards for studying Claude certs. Build your own decks or share them back to the library so others can study with you.

**[Open the live site](https://liitx.github.io/claude-cert-practice-exam-cards/)**

---

## In the library

| Deck | Cards | Subjects |
| --- | --- | --- |
| CCA-F | 57 | Customer Support, Multi-Agent, Code Generation, Claude Code CI |

More decks land as new exams ship or people share what they've built.

---

## Study

Open the site and pick a deck. Tap a card to flip it. Mark **Review** to come back to it or **Got it** when you've locked it in. The filter chips at the top focus on your misses, your review pile, or the cards you've nailed.

| Key | Action |
| --- | --- |
| `space` | flip the card |
| `← →` | move between cards |
| `1` | mark Review |
| `2` | mark Got it |

Progress saves to your browser. Refresh brings you back to the same deck, filter, and card.

---

## Build your own

Tap **+ Deck**, name it, pick a first subject and color. Then **+ Card** and pick a card type.

| Type | Shape |
| --- | --- |
| Basic | situation, correct answer, optional reasoning |
| Multiple choice | one correct from a list |
| Select all that apply | any number correct from a list |
| True / False | one of two |
| Fill blank | typed answer, multiple accepted spellings, case-insensitive |

Attach an image up to 800KB on any card. Flag cards you missed on the real exam.

The **subjects** link in the footer row opens a sheet to add, rename, and delete subjects. Built-in subjects can be renamed but not deleted while cards still reference them.

---

## Skip the typing: have Claude write the deck

The app has a prompt generator built in. Tap **ask claude** in the footer row, fill in a topic, pick a card type and how many you want, and copy the prompt. Paste it into Claude, paste the JSON Claude gives you back into the **import** sheet, done.

The Import sheet validates the JSON against the schema and points at any specific problems (missing fields, wrong types, out-of-range indices) before anything lands.

| Type | Required fields per card |
| --- | --- |
| `basic` | `a` (correct answer text) |
| `mc` | `choices` (2+ strings), `correct` (index) |
| `ms` | `choices`, `correct` (array of indices) |
| `tf` | `correct` (`true` or `false`) |
| `fib` | `accepted` (array of accepted answers) |

Every card type also takes `topic`, `q`, `why`, `miss`, `pick`, and `image` as optional fields where they apply.

---

## Share back to the library

Tap **share to library** at the bottom of any deck where you've added something. A GitHub issue opens with your deck as JSON.

1. A GitHub Action validates the JSON.
2. Auto-merges into `decks.json`.
3. Pages rebuilds. Everyone sees it on next refresh.

Failed validation comments on the issue with what to fix. You need a GitHub account to file the issue. Nothing else asks you to sign in.

---

## Stay in sync

A small **library** button next to the counter is quiet by default. When new decks or cards land, it shows a green badge. Tap to sync. Checks run on tab focus and window focus, not on a timer.

For private cross-device moves, **export** and **import** are in the footer row. Export this deck or everything, copy the JSON or download a `.json` file, then paste it into the import sheet on the other device.

---

## Where your data lives

- **`decks.json`** in this repo is the shared library. Public and version-controlled.
- **Your browser's localStorage** holds your progress, private decks, and any overlays on shared decks. Nothing here leaves your browser unless you share or export.

Reset progress only touches your local state. Delete a private deck only deletes your local copy.

---

## Coming next

- Matching cards. Scoped out of phase 1.
- More cert decks as Anthropic ships new exams.
- Markdown in submitted text so submissions can use inline code styling.
- Spaced-repetition scheduling on top of Review and Got it.

File an issue for anything else you want.

---

## Under the hood

Static site. Vanilla HTML, CSS, and JS. No build, no backend, no analytics.

`decks.json` is fetched at page load. An embedded snapshot in `index.html` is the offline fallback. Auto-ingest runs in `.github/workflows/ingest-submission.yml` and `scripts/ingest.js`.

See `CONTRIBUTING.md` for maintainer details.
