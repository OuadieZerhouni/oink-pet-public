# Owner to-do — Oink v1.0

Everything below needs your Apple/Codemagic accounts or your ears, so it was left for you. The code, config, icon and listing
text are done (`ASO.md`). Work top to bottom; each gate unblocks the next.

## GATE-BUNDLE-ID — register the App ID
- developer.apple.com → Identifiers → **+** → App IDs → App.
- Bundle ID (explicit): `com.ouadieZerhouni.oinkPet`. Description: `Oink`.
- No capabilities needed (no push, no App Group, no IAP in v1).

## GATE-ASC-RECORD — create the App Store Connect record (reserves the name)
- App Store Connect → Apps → **+** → New App. Platform iOS.
- Name: `Oink: Cute Pig Virtual Pet` · Primary language: English (U.S.) · Bundle ID: the one above · SKU: `oink-pet-ios`.
- Do this soon: the name is only checked for uniqueness at creation.
- Then copy the numeric Apple ID into `app.yaml` → `app.app_store_id`, and into the config as
  `"updateUrlIos": "https://apps.apple.com/app/id<APPLE_ID>"` (in the `app-configs` repo; see `docs/REMOTE_CONFIG.md`).

## GATE-GITHUB-CODEMAGIC — first build
- Codemagic → Add application → GitHub → `OuadieZerhouni/oink-pet` (private; grant Codemagic access if asked).
- It picks up `codemagic.yaml` (workflow **testFlight**, integration `OUADIE ZERHOUNI`, the same one OuO uses).
- Start the build. It runs `flutter analyze` + all tests before building, then uploads to TestFlight (never auto-submits).

## GATE-DEVICE — 15 minutes with the TestFlight build on a real iPhone
The sounds were synthesized in code (`tools/audio/synth.py`) and the haptics were never felt on hardware. Check:
- [ ] Oinks, snorts, giggles sound cute, not harsh (tap snout, rub belly, tickle ears). Volume balance vs. munch/bubbles.
- [ ] Sounds respect the silent switch (ambient session) and don't stop your music.
- [ ] Haptics feel light on taps and the gift/level-up.
- [ ] Smooth animation (no jank) on your oldest iPhone; battery fine after 10 minutes.
- [ ] Apple Catch: the pig follows your finger; 45 s round; acorns paid out.
- [ ] Leave the app 8+ hours, come back: needs dropped, pig still fine, gift available next day.
If any sound is off: say which one and it can be re-synthesized, or allow the ElevenLabs key `sound_generation` permission
(the current key got 401) and they can be regenerated as real recorded-style pig sounds.

## GATE-LISTING — fill the store page (all text is in `ASO.md`)
- [ ] Name, subtitle, keywords, promo text, description (en-US), then **add English (U.K.)** with the identical text.
- [ ] Category: Games → Simulation + Casual. Age rating questionnaire: all "None" → 4+. Do **not** tick "Made for Kids".
- [ ] App Privacy: **Data Not Collected**.
- [ ] Support URL and Privacy URL (in `ASO.md`).
- [ ] Pricing: Free. **Availability: untick the 37 storefronts listed in `ASO.md`** (protects OuO's Saudi audience).
- [ ] Screenshots 6.9" (1320×2868) and 6.5" (1242×2688), six slides, captions in `ASO.md`. Easiest: TestFlight on a Pro Max,
      take them in the app, caption in your usual tool.
- [ ] App Review notes: "Offline virtual pet. No account, no login, no ads, no purchases."

## GATE-ASA — keyword popularity check (Apple Search Ads, manual)
- US: `oink`, `cute pig`, `piglet`, `pig simulator`, `pig game`, `oink oink`, `cute pet`, `pet games`
- GB: `oink`, `cute pig`, `piglet`
- Healthy if `oink` US ≥ 20 **and** `cute pig` ≥ 10. If `oink` US is high but the impressions are "pink" shoppers, ignore it.

## After launch
- First update: re-read reviews; flip `features.*` or `economy.*` in the remote config if something feels off (no rebuild).
- v1.1 options in `ASO.md` (ja / ko listings) only if English shows traction.
- Known factory issue (not Oink-specific): the app-factory Info.plist template comment contains `--regen`, which is invalid
  inside an XML comment. Oink's copy was reworded; fix `app-factory/template/ios/Runner/Info.plist` so a regen doesn't bring it back.
