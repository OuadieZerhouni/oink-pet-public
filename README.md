# Oink

A kawaii baby-pig virtual pet for iPhone. Feed it by dragging snacks to its snout, give it bubble baths, rub its belly,
tuck it in, play Apple Catch for acorns, and spend them on hats, glasses and rooms. It grows from piglet to big pig as you care
for it. No ads, no in-app purchases, no account; works offline.

- Flutter 3.44 / Dart 3.12, iOS-first, iPhone portrait. Everything is drawn in code (pig, rooms, icons); sounds are synthesized
  (`tools/audio/synth.py`).
- Remote config: a public JSON on GitHub (`docs/REMOTE_CONFIG.md`).
- Store listing: `ASO.md`. What is left for the owner (accounts, device check, store page): `owner-todo.md`.
- Product spec: `SPEC.md`. Working notes for Claude Code: `CLAUDE.md`.

```bash
flutter pub get && flutter gen-l10n
flutter analyze && flutter test
flutter run
```
