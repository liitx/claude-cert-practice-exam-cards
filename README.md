# Claude Cert Practice Cards

Flashcards for studying Claude certification exams. Flip a card, mark whether you got it, filter down to your misses, and drill until they stick.

**Live:** https://liitx.github.io/claude-cert-practice-exam-cards/

## What's in the library today

The CCA-F deck. 57 cards across four subjects: Customer Support, Multi-Agent, Code Generation, and Claude Code CI integration. Each card is a real-world scenario you'd see on the exam. The ones flagged "you missed this" include the wrong answer most people pick, so you can rewire the reflex.

More decks land as new Claude certs ship, or as people share decks they've built.

## How to use it

Open the site. Pick a deck from the dropdown. Use the filter chips at the top to focus on your misses, your review pile, the ones you've got, or all of them.

Tap or press space to flip a card. Mark **Review** for "come back to this", **Got it** for "locked in". Your progress saves automatically and stays in your browser.

Keyboard shortcuts:

- `space` flips the card
- `←` / `→` move between cards
- `1` marks Review, `2` marks Got it

## Building your own decks

Click `+ Deck`, give it a name, pick a first subject with a color. Then click `+ Card` and fill in the fields. You'll set a subject by tapping a colored chip, type a topic, write the situation, write the correct answer, and add an optional reasoning note. There's a checkbox to flag a card as one you originally missed, with what you picked.

The fields match the shape of the official cards on purpose. Same study flow, same chip filters.

### Worked example

Say a "Claude API Foundations" exam shows up and you want to prep.

1. Tap `+ Deck`. Name it "API Foundations". First subject: "Tool Use", whatever color.
2. Tap `+ Card`. Pick the Tool Use chip. Situation: "Your agent makes four sequential tool calls per resolution and latency is hurting you." Answer: "Batch related tool calls in a single turn." Save.
3. Keep adding cards. Add more subjects with the `+ new` chip in the card form when topics expand.
4. Switch to the "All" filter and drill.

The same flow works for anything you're memorizing. Subject chips and the missed-card framing aren't AI-specific.

## Sharing what you build

If a deck turned out useful, click **share to library** at the bottom of the page. A GitHub issue opens with your deck as JSON in the body. From there:

1. The repo's GitHub Action wakes up, runs validation against the JSON, and merges it into `decks.json`.
2. GitHub Pages rebuilds. Your deck shows up for everyone after the next refresh, usually within a couple of minutes.
3. If anything's malformed, the bot comments on your issue explaining what to fix.

You need a GitHub account to file the issue. That's the only place anyone signs in.

Per-card additions work the same way. If you only added cards to an existing shared deck, the button sends just those additions.

## Where your stuff lives

Two separate stores, intentionally:

- **`decks.json`** in this repo is the shared library. Public, in version control, auto-ingested from issues.
- **Your browser's localStorage** holds your progress, private decks you've built, and overlay cards or subjects you've added on top of shared decks. Nothing local ever leaves your browser unless you click share.

Reset progress clears only your local state. Deleting a private deck removes only your local copy. The shared library is never touched by anything you do client-side.

## What's coming

- More cert decks as Anthropic ships new exams. If you've prepped for one already, please share what you built.
- Markdown in card text so submissions can have inline code styling like the original cards do.
- Spaced-repetition scheduling layered on top of the Review and Got it marks.
- Tags and filters across decks once there's more than a handful in the library.

File an issue for anything else you want.

## Tech notes

Static site. Vanilla HTML, CSS, and JavaScript. No build step, no backend, no analytics. The library lives in `decks.json`, fetched at page load. An embedded snapshot inside `index.html` is the offline fallback.

Auto-ingest runs in `.github/workflows/ingest-submission.yml` and `scripts/ingest.js`. Validation lives in the script. Auto-merge is enabled on the repo so accepted submissions land without manual review.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the maintainer-side details.
