# Contributing decks and cards

The shared library lives in [`decks.json`](./decks.json). Everything else (your progress, decks you create privately) stays in your browser's localStorage.

## Submitting a deck or new cards

1. Open the [live site](https://liitx.github.io/claude-cert-practice-exam-cards/).
2. Create a new deck, or add cards/subjects to any existing deck.
3. Click **"share to library"** at the bottom of the page. A GitHub issue opens with the JSON payload prefilled.
4. Submit the issue. A maintainer reviews and either edits `decks.json` directly or asks for changes.

If the deck is large enough that the URL would exceed GitHub's limit, the JSON is copied to your clipboard automatically — paste it into the issue body.

## Maintainer flow

For each submission issue:

1. Sanity-check the JSON in the issue body.
2. Decide whether it's a new deck (`type: "new-deck"`) or additions to an existing deck (`type: "cards-for-deck"`).
3. Edit `decks.json`:
   - New deck: pick a stable `id` (lowercase, hyphenated) and append the deck object under `decks`.
   - Additions: find the target deck by `targetDeckId`, then append the cards and merge any new subjects into `scenarios`.
4. Bump `updated` to today's date.
5. Commit, push, close the issue with a link to the commit.

## Updating the embedded fallback

`index.html` has an embedded copy of the deck data so the site works while `decks.json` is loading (and offline after the first visit). If you edit `decks.json` directly and want the embedded snapshot to match, regenerate it with:

```bash
node -e "
const fs = require('fs');
const json = JSON.parse(fs.readFileSync('decks.json','utf8'));
console.log(JSON.stringify(json.decks[0].cards));
"
```

Drift is OK in practice — the fetched JSON always wins at runtime.

## Data shape

```json
{
  "id": "deck-id",
  "name": "Deck name",
  "scenarios": {
    "KEY": { "label": "Display label", "color": "#7c83ff" }
  },
  "cards": [
    {
      "id": "unique-card-id",
      "scn": "KEY",
      "topic": "Subtopic",
      "q": "Situation or question",
      "a": "Correct approach",
      "why": "Reasoning",
      "miss": false,
      "pick": "optional, only if miss=true"
    }
  ]
}
```

`q`, `a`, and `why` may contain inline `<code>` tags — those render as monospace in the app.
