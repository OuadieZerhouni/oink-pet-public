# SPEC — Oink (kawaii baby pig virtual pet)

**Niche:** rotation 37 ("the next OuO", typed-token capture). `oink` has US traffic T96/D60 in applyra, and its only
pig-pet app had 0 ratings. Research: `../../research/niche-research/niche-scout/history/2026-10-06_rotation37-next-ouo-tokens.md`.
ASO: `ASO.md`.

**v1 promise:** a tiny piglet that lives in your phone and genuinely needs you. Feed it, give it a bubble bath, rub its
belly, play a catch game, and tuck it in. It grows up and you dress it up. Free, **no ads, no in-app purchases**, works
fully offline, and needs no account.

## Why it is not OuO or Neko (Apple 4.3)
OuO and Neko are reaction toys with "no hunger bar, nothing decays". Oink is a **care-loop pet**:
- It has four needs that change over real time.
- It has care tools (food tray, sponge and shower, a mini-game, sleep).
- It grows from piglet to pig and unlocks things as it levels up.
- It has a wardrobe and rooms bought with acorns earned through care.

It is a different species with full-body art, different mechanics and a different art style (soft vector, not ink or pixel).

## Screens
1. **Onboarding (first launch only):** the piglet peeks out of a basket, you name it (default "Oinky", with suggestion
   chips), then three quick tips.
2. **Home** (the only main screen):
   - Top bar: the pig's name and level ring, and the acorn count.
   - Four need meters: Tummy, Clean, Fun, Energy.
   - Centre: the room background and the pig.
   - Bottom: an action dock with Feed, Bath, Play, Sleep and Closet.
   - A speech bubble shows mood and needs ("I'm hungry!").
   - A daily gift button appears when a gift is available.
3. **Feed tray:** a sheet of food. Drag food onto the pig's mouth to make it munch.
   - Basic foods are free and unlimited.
   - Treats unlock by level.
   - A full tummy means the pig refuses with "I'm full!" and a head shake.
4. **Bath mode:**
   - Mud spots appear as Clean drops.
   - Rubbing the sponge over the pig makes bubbles and scrubs the spots away.
   - The shower rinses, and the pig sparkles when clean.
5. **Play:** "Apple Catch". Drag the pig left and right to catch falling apples and acorns and dodge bees. A round lasts
   45 s and earns acorns and Fun.
6. **Sleep:**
   - The lights dim, the pig sleeps with Zzz and soft snores, and Energy refills, even while the app is closed.
   - Tap the moon to wake it.
   - At night (22:00–07:00 local) the pig says it is sleepy.
7. **Closet:** tabs for Hats, Glasses, Neck and Rooms.
   - Each item is locked by level or by an acorn price.
   - You can equip or unequip items with a live preview.
   - Seasonal items can be switched by remote config.
8. **Settings:** sound, haptics, language, rename pig, privacy, support, about, and start over (with confirmation).

## Pig interactions (gesture zones on the painted pig)
| Zone | Gesture | Reaction |
| --- | --- | --- |
| Snout | tap | "oink!" (random of 6) and a snout squish, with a speech bubble |
| Head | tap | happy ^^ eyes, ears perk, hearts |
| Belly | tap, or rub back and forth | giggle, legs kick, hearts; Fun rises |
| Ear | tap | ear flops, snort |
| Tail | tap | the tail spins, surprised "oink?" |

All reactions respect state: a sleeping pig grumbles and stays asleep.

## Systems (pure Dart, unit-tested)
- **Needs:** tummy, clean, fun and energy, each 0–100.
  - Decay per hour, tunable by remote config: tummy −6, clean −3, fun −5, energy −4 awake / +15 asleep.
  - Elapsed time is applied on resume with an injectable clock. A pet never dies; decay floors at 5.
- **XP and level:** level *n* needs `20 + 12·n` XP. Growth stage: piglet (levels 1–4), little pig (5–9), big pig (10+).
- **Acorns:**
  - Daily gift of 5 + streak bonus, with the streak capped at 7.
  - Small rewards for caring when a need is low.
  - The mini-game pays its score ÷ 3.
  - Acorns are spent only in the Closet. There is no real money anywhere.
- **Persistence:** one JSON blob in shared_preferences, with a versioned schema and safe defaults on corrupt data.

## Remote config (GitHub JSON, no secrets)
URL: `https://raw.githubusercontent.com/OuadieZerhouni/app-configs/main/oink-pet/config.json`. Every key has a code
default, and malformed values fall back. First launch works with no network. See `docs/REMOTE_CONFIG.md`.

## Quality bar
- 60 fps idle animation, with particle counts capped.
- Portrait iPhone only, with safe areas respected and text scale clamped.
- Sound respects the silent switch and has a settings toggle. Haptics use light impacts.
- Unit, widget and pixel tests cover every system and every user flow (see `test/`).
