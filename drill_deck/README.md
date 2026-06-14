# drill_deck

Flutter Web port of the Claude Cert Practice Cards study app. This is the
in-progress rewrite. The live site at
[liitx.github.io/claude-cert-practice-exam-cards](https://liitx.github.io/claude-cert-practice-exam-cards/)
continues to serve the static `../index.html` until cutover.

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

## Build for production

```bash
flutter build web --release \
  --base-href=/claude-cert-practice-exam-cards/ \
  --pwa-strategy=none
```

The output in `build/web/` deploys to the `gh-pages` branch via
`.github/workflows/deploy.yml` (manual trigger until cutover).

## Test

```bash
flutter test
```

## Phase progress

- [x] Phase 1 — scaffold + theme + storage + migration
- [ ] Phase 2 — read-only study view (basic + MC)
- [ ] Phase 3 — all card types + progress
- [ ] Phase 4 — private decks + card management
- [ ] Phase 5 — library sync + share + Ask Claude
- [ ] Phase 6 — deploy cutover + polish
