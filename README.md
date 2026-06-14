# Claude Cert Practice Cards

Flashcards for studying Claude certification exams. Each card has a question and an answer you flip to see, plus a way to mark what you missed so you can drill those later. You can build your own decks for anything you want to memorize. Decks you build can be pushed back to the shared library so other people can study them too.

Live site: https://liitx.github.io/claude-cert-practice-exam-cards/

## What's in the library

The CCA-F deck. 57 cards across four subjects covering Customer Support, Multi-Agent, Code Generation, and Claude Code CI integration. Cards flagged "you missed this" include the wrong answer most test-takers pick, plus a short note on the reasoning trap.

More cert decks land as new exams ship or as people share what they've built.

## Studying

Open the site and pick a deck from the dropdown. Tap or press space to flip a card. Mark **Review** for "come back to this" or **Got it** for "locked in". The filter chips at the top narrow the view to your misses, your review pile, the cards you've nailed, or all of them.

Arrow keys move between cards. Press 1 to mark Review, 2 to mark Got it. Your progress saves automatically and stays in your browser. Refresh the page and you land back on the same deck, the same filter, and the same card.

## Building decks and cards

Tap **+ Deck**, name it, pick a first subject and color. Then **+ Card** to add cards. Every card has a subject as a tappable colored chip, a free-text topic, and content that depends on the card type.

### Card types

**Basic** is the original flashcard shape. A situation prompt, the correct answer, and an optional reasoning blurb.

**Multiple choice** has a question and a list of choices with one marked correct. The front shows the choices as tappable buttons. The back highlights the correct one and shows your pick if it differed.

**Select all that apply** is the same shape with multiple correct choices. You toggle as many as you want on the front. The back tells you whether your selection matched.

**True / False** is a statement with one of two answers, rendered as two large buttons.

**Fill in the blank** is a question with a text input. You can list multiple accepted answers, one per line. Matching is case-insensitive and trims whitespace.

For any type you can attach an image up to 800KB, flag the card as one you originally missed on the exam, and add an optional explanation that shows on the back alongside the structured answer. The back face also shows a correct, wrong, or no-answer badge based on what you picked.

## Subjects

Subjects are the colored labels on every card. The **subjects** link in the deck-meta row opens a sheet for adding, renaming, and deleting them.

Renames work for any subject including the built-in CCA-F ones, with the new label layered on top via a local override. Delete is blocked when a subject still has cards attached or when it's the deck's last subject.

## Sharing what you build

Click **share to library** at the bottom of any deck where you've added something. A GitHub issue opens with your deck as JSON in the body. From there it's automated:

1. A GitHub Action picks up the issue, runs validation, and merges your JSON into `decks.json`.
2. GitHub Pages rebuilds the site.
3. The new content shows up for everyone on the next refresh, typically 1 to 2 minutes later.

If the submission fails validation, the bot comments on your issue with what to fix. You need a GitHub account to file the issue. That's the only place anyone signs in.

## Library updates

A small **library** button sits next to the counter at the top. Quiet when there's nothing new. When new decks or cards land in the shared library, it picks up a green badge with the count. Tap to sync and the new content folds into your view.

Checks happen when you tab back into the page, when the window regains focus, or when you tap the button. No background polling.

## Cross-device without going public

`localStorage` is per-browser and per-device, so anything private you've built on one device doesn't show up on another. Two ways to bridge that:

1. **Share to library** as described above. Goes public, lands on every device.
2. **Export and import**. Both have links in the deck-meta row. Export this deck or everything you've made, copy the JSON to your clipboard or download a `.json` file, then paste it into the import sheet on the other device. Stays private.

## Where your data lives

Two stores, intentionally independent:

- `decks.json` in this repo is the shared library. Public, in version control, auto-ingested from issues.
- Your browser's localStorage holds your progress, any private decks you've built, and overlay cards or subjects you've added on top of the shared library. Nothing in localStorage leaves your browser unless you click share or export.

Resetting progress clears only your local state. Deleting a private deck removes only your local copy. The shared library is untouched by anything you do client-side.

## What's coming

- Matching cards where you drag items between two columns to pair them. Scoped out of phase 1.
- More cert decks as Anthropic ships new exams. If you've prepped for one already, please share.
- Markdown in submitted text so community submissions can render inline code formatting like the original cards do.
- Spaced-repetition scheduling on top of the existing Review and Got it marks.

File an issue for anything else you want.

## Tech notes

Static site. Vanilla HTML, CSS, and JavaScript. No build step, no backend, no analytics. `decks.json` is fetched at page load. An embedded snapshot inside `index.html` is the offline fallback.

Auto-ingest runs in `.github/workflows/ingest-submission.yml` and `scripts/ingest.js`. Auto-merge is enabled on the repo so accepted submissions land without manual review.

See `CONTRIBUTING.md` for the maintainer-side flow.
