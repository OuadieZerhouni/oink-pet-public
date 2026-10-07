# SPEC — Oink (kawaii baby pig virtual pet)

> The contract for v1.0. A feature is done when its acceptance criteria pass — not when it feels done.
> Niche: rotation 37 ("the next OuO", typed-token capture). `oink` has US traffic T96/D60 in applyra, and its only
> pig-pet app had 0 ratings. Research: `../../research/niche-research/niche-scout/history/2026-10-06_rotation37-next-ouo-tokens.md`.
> ASO: `ASO.md`.

## One line

A tiny piglet that lives in your phone and genuinely needs you: feed it, give it a bubble bath, rub its belly, play a
catch game and tuck it in, while it grows up and you dress it up. Free, no ads, no in-app purchases, fully offline, no
account.

## Audience & tone

Cozy-game and kawaii-animal fans, kids-at-heart teens to adults, English-speaking storefronts first. They open it a few
times a day for a few calm minutes. The tone is warm, soft and gently needy ("I'm hungry!"), never guilt-tripping: the pet
never dies and nothing is lost.

### Why it is not OuO or Neko (Apple 4.3)

OuO and Neko are reaction toys with "no hunger bar, nothing decays". Oink is a **care-loop pet**: four needs that change
over real time, care tools (food tray, sponge and shower, a mini-game, sleep), growth from piglet to pig with level
unlocks, and a wardrobe and rooms bought with acorns earned through care. Different species, full-body art, different
mechanics and a different art style (soft vector, not ink or pixel).

## Screens

| Screen | Purpose | Entry |
| --- | --- | --- |
| Onboarding | piglet peeks out of a basket, you name it, four quick tips | first launch only |
| Home | the only main screen: top bar, need meters, room + pig, action dock, speech bubble, daily gift | launch |
| Feed tray | sheet of foods dragged onto the pig's mouth | dock → Feed |
| Bath mode | scrub mud with a sponge, rinse with the shower | dock → Bath |
| Apple Catch | 45 s catch mini-game | dock → Play |
| Sleep | lights dim, pig sleeps, energy refills | dock → Sleep |
| Closet | Hats, Glasses, Neck, Rooms | dock → Closet |
| Diary | the pig's stats (favourite food, days together, …) | top bar |
| Settings | sound, haptics, language, rename, privacy, support, about, start over | top bar |

## Features

### F1 — Onboarding

**Acceptance criteria**
- [x] On first launch the piglet peeks out of a basket, then a name step offers suggestion chips that fill the field when tapped; an empty name becomes "Oinky" (shown as the hint).
- [x] Confirming the name shows four quick tips (Feed, Bath, Love, Grow), then lands on Home with the pig named as entered.
- [x] Onboarding never appears again on later launches (persisted).

### F2 — Home and the painted pig

The pig is drawn procedurally (`PigPainter`), breathes and blinks, and its eyes follow the finger.

**Acceptance criteria**
- [x] Top bar shows the pig's name, a level ring and the acorn count; four meters show Tummy, Clean, Fun and Energy (0–100).
- [x] The bottom dock has Feed, Bath, Play, Sleep and Closet; each opens its mode.
- [x] A speech bubble states mood or the most urgent need (e.g. "My tummy is rumbling…") and stays anchored above the pig.
- [x] Idle life: breathing and blinking; the pupils track a finger held on the screen.
- [x] Growth stage is visible: piglet (levels 1–4), little pig (5–9), big pig (10+) render with different body proportions.
- [x] Portrait iPhone only; safe areas respected; layout holds on a 320×568 phone at 1.6× text scale with no overflow.

### F3 — Pig interactions (gesture zones)

| Zone | Gesture | Reaction |
| --- | --- | --- |
| Snout | tap | "oink!" (random of 6) and a snout squish, with a speech bubble |
| Head | tap | happy ^^ eyes, ears perk, hearts |
| Belly | tap, or rub back and forth | giggle, legs kick, hearts; Fun rises |
| Ear | tap | ear flops, snort |
| Tail | tap | the tail spins, surprised "oink?" |

**Acceptance criteria**
- [x] Each zone in the table produces its listed reaction and sound.
- [x] Rubbing the belly back and forth raises Fun.
- [x] Tapping or rubbing a sleeping pig makes it grumble ("Five more minutes…"); it stays asleep.
- [x] Each reaction gives a light haptic when haptics are on.

### F4 — Feed

**Acceptance criteria**
- [x] The Feed tray lists foods; basic foods are free and unlimited, treats show a lock with their unlock level.
- [x] Dragging a food onto the pig's mouth makes it munch, raises Tummy and grants XP.
- [x] With a full tummy (96+) the pig refuses: "I'm full!" and a head shake, and Tummy does not change.
- [x] The diary (tap the name in the top bar) shows the favourite (most-eaten) food.

### F5 — Bath

**Acceptance criteria**
- [x] Entering Bath shows mud spots on the pig in proportion to how low Clean is.
- [x] Rubbing the sponge over the pig makes bubbles and removes spots.
- [x] The shower rinses the bubbles; the pig sparkles when clean and Clean is raised.

### F6 — Play: Apple Catch

**Acceptance criteria**
- [x] Dragging moves the pig left and right to catch falling apples, stars and acorns; bees must be dodged.
- [x] A round lasts 45 s with a visible countdown, then shows a result.
- [x] The result pays acorns of score ÷ 3 (capped at 40 per round) and raises Fun by 25. Three bee stings end a round early.

### F7 — Sleep

**Acceptance criteria**
- [x] Sleep dims the lights; the pig sleeps with Zzz and soft snores (only while Home is on screen); Energy refills, including while the app is closed.
- [x] Tapping the moon (or the dock's Wake button) wakes the pig.
- [x] Between 22:00 and 07:00 local, an awake pig with no urgent need says it is sleepy.

### F8 — Needs, XP and acorns (pure Dart, unit-tested)

**Acceptance criteria**
- [x] Needs decay per hour (tummy −6, clean −3, fun −5, energy −4 awake / +15 asleep), tunable by remote config.
- [x] Elapsed time is applied on resume with an injectable clock; needs floor at 5 and the pig never dies.
- [x] Level *n* needs `20 + 12·n` XP; levelling up celebrates with a sound, a reaction and a level-up dialog.
- [x] Daily gift of 5 acorns + streak bonus (streak capped at 7), claimable once per local day from a button on Home.
- [x] Feeding or bathing when that need is low pays a small acorn bonus.
- [x] Acorns are spent only in the Closet; there is no real money anywhere.

### F9 — Closet

**Acceptance criteria**
- [x] Tabs for Hats, Glasses, Neck and Rooms; each item is locked by level or by an acorn price.
- [x] Buying deducts acorns; items cannot be bought without enough acorns.
- [x] Equip and unequip with a live preview on the pig; a room changes the Home background.
- [x] Seasonal items appear or hide by remote config.

### F10 — Settings and persistence

**Acceptance criteria**
- [x] Sound and haptics toggles take effect immediately and persist.
- [x] Rename pig, privacy, support and About entries work.
- [x] Start over asks for confirmation, then returns to onboarding with fresh state.
- [x] Pet state is one versioned JSON blob in shared_preferences (settings and the config cache are separate keys); corrupt data falls back to safe defaults without crashing.

### F11 — Remote config

URL: `https://raw.githubusercontent.com/OuadieZerhouni/app-configs/main/oink-pet/config.json`. See `docs/REMOTE_CONFIG.md`.

**Acceptance criteria**
- [x] Every key has a code default; the published JSON equals the code defaults.
- [x] Malformed or out-of-range values fall back or are clamped.
- [x] First launch works with no network.

### F12 — Quality bar

**Acceptance criteria**
- [x] 60 fps idle animation with capped particle counts.
- [x] Sound respects the silent switch (ambient session) and does not stop other audio.
- [x] Unit, widget and pixel tests cover every system and the main flows (onboarding, pet, feed, bath, play, sleep, gift, closet, settings); what only a device shows is driven by `/test-drive`; `flutter analyze` is clean and `flutter test` passes.

## Non-goals

- No ads, IAP, analytics, account or login in v1 (`ads.enabled` in the config is reserved and must stay unread).
- No widget, no notifications, no iPad layout, no landscape.
- English only in v1. No Arabic, Turkish, Indonesian or Malay locale, ever (see `ASO.md`).
- No death or loss state.

## Data & permissions

- Stored locally only: the pet state blob and settings in shared_preferences.
- Network: one anonymous GET of the public GitHub config JSON, cached.
- OS permissions: none.
- App Privacy: **Data Not Collected**.

## Monetization

none.

## Store

- Category: Games → Simulation (primary) + Casual.
- Age rating notes: no violence, gambling or user-generated content → 4+. Not in the Kids category.
- Keyword seeds: oink, cute pig, piglet, pig simulator, pig game, virtual pet, pet games, kawaii, bubble bath, dress up.
- Privacy policy: `https://github.com/OuadieZerhouni/app-configs/blob/main/oink-pet/PRIVACY.md` (support alongside, see `ASO.md`).
