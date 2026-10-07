# ASO — Oink v1.0 (iOS)

Paste-ready App Store listing. Full research (keyword T/D tables, competitor teardown, name checks, risk notes):
`personal/research/niche-research/niche-scout/history/2026-10-07_oink-aso.md`. All T/D numbers are applyra **estimates**
measured 2026-10-06. The only real volume check is Apple Search Ads (see `owner-todo.md`, GATE-ASA).

## Listing — en-US (primary). en-GB = identical copy

| Field | Text | Count |
|---|---|---|
| App Name | `Oink: Cute Pig Virtual Pet` | 26/30 |
| Subtitle | `Baby Piglet Care Simulator` | 26/30 |
| Keywords | `game,games,piggy,kawaii,mini,cozy,animal,pets,bath,bubble,feed,grow,outfits,dress,pink,friend,micro` | 99/100 |
| Promotional Text | `Meet your new baby piglet! Feed it, give it bubble baths, rub its round belly and hear it giggle. Care for it every day to grow it up and unlock cute outfits. No ads.` | 166/170 |
| Category | Games → **Simulation** (primary) + **Casual** | |
| Age rating | **4+**. Do **not** opt into the Kids category | |
| Price | Free | |
| App Privacy | **Data Not Collected** (no analytics, no ads, no account; the only network call is a GET of a public JSON config) | |
| Support URL | `https://github.com/OuadieZerhouni/app-configs/blob/main/oink-pet/SUPPORT.md` | |
| Privacy URL | `https://github.com/OuadieZerhouni/app-configs/blob/main/oink-pet/PRIVACY.md` | |

The home-screen name stays **Oink** (`CFBundleDisplayName`). The exact store name "Oink" is taken (Roshka S.A.), which is why
the store name carries a suffix.

Indexed from Name + Subtitle (so not repeated in Keywords): oink, cute, pig, virtual, pet, baby, piglet, care, simulator.
Phrases Apple can build across fields: `cute pig` (US T33/D25, GB T46/D25), `pig simulator` (US T39/D28), `piglet` (US T74/D49),
`pig game`, `pet games`, `cozy games`, `virtual pig`, `baby pig`, `pig care`, `mini pig`, `kawaii pig`.

**Never in metadata:** `tamagotchi` (Bandai), `oinky` (competitor brand), `peppa`, `pou`, `Oink Games`, `free`, `kids` / `for kids`,
`widget`, `farm`. Never title it `Oink cute pet` (mirrors OuO's title pattern → 4.3 sibling risk).

## Description (checked line by line against the v1.0 build)

```text
Meet your new best friend: a tiny, round, pink baby piglet who needs YOU.
Feed it, give it bubble baths, rub its belly and listen to it oink, snort and giggle. Care for it every day and watch it grow from a wobbly piglet into a proud, happy pig.

No ads. No in-app purchases. No account. Just you and your pig.

FEED YOUR PIGLET
• Drag apples, carrots, corn and sweet treats right to its snout
• New snacks unlock as your pig grows, from watermelon to cupcakes
• Your diary remembers its favorite food

BUBBLE BATH TIME
• Piglets love mud. You love a clean piglet
• Scrub away the mud with a soapy sponge, then rinse
• Squeaky clean pigs are the happiest pigs

BELLY RUBS & CUDDLES
• Pet its head, boop its snout, rub that round little belly
• Every touch gets a reaction: oinks, snorts, giggles and happy wiggles
• Its eyes follow your finger

APPLE CATCH
• A quick mini-game: slide your pig to catch falling apples
• Golden stars and acorns are worth more. Watch out for bees!
• Earn acorns to spend in the closet

GOODNIGHT, PIGGY
• When your pig gets sleepy, turn off the light and let it snore
• It rests up while you are away

WATCH IT GROW
• Raise your baby piglet into a grown-up pig, step by step
• Level up with every feed, bath and cuddle
• A daily gift of acorns, bigger every day you come back

DRESS IT UP
• Hats, flower crowns, bows, glasses, scarves and bow ties
• Five cozy rooms, from a little barn to a snowy winter day
• Seasonal surprises for Halloween and winter

MADE WITH CARE
• Free, with no ads and no in-app purchases
• Works offline
• No sign-up, no account, no data collected
• Short, calm sessions: a few happy minutes a day

Whether you love pigs, kawaii animals or cozy virtual pet games, Oink is a small, warm place to come back to every day. Your piglet is waiting. Say hello and hear its first oink!
```

Claims → code: foods and unlock levels (`lib/pet/catalog.dart`), favorite food (`PetStats.favoriteFood`, shown in the diary),
eyes follow the finger (`PigView`), mini-game items (`apple_catch_logic.dart`), sleep restores energy while away (`DecayRates`),
daily gift streak (`Economy.dailyGift`), outfits/rooms/seasonal items (`catalog.dart`). If a feature is cut or a remote-config
flag turns one off (mini-game, daily gift, seasonal), edit the matching line before the next submission.

**What's New** (not shown for 1.0; keep for 1.0.1): "Thanks for adopting a piglet! Small fixes and even more giggles. Tell us which outfit to add next."

## Availability

Untick these storefronts in App Store Connect → Pricing and Availability (protects OuO's audience; measured pig demand there is
zero): Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman, Egypt, Jordan, Iraq, Lebanon, Libya, Tunisia, Algeria, Morocco, Yemen, Turkey,
Indonesia, Malaysia, Brunei, Pakistan, Bangladesh, Maldives, Azerbaijan, Kazakhstan, Uzbekistan, Kyrgyzstan, Tajikistan, Turkmenistan,
Senegal, Mali, Niger, Gambia, Mauritania, Chad, Sierra Leone, Guinea-Bissau, Afghanistan. Do not cross-promote Oink inside OuO.

## Screenshots (captions, in order)

1. "Your own baby piglet" — home, piglet with bow, happy
2. "Belly rubs = giggles" — hearts burst over the pig
3. "Bubble bath time!" — bath mode, sponge and bubbles
4. "Snack time, yum!" — feed tray open, apple being dragged
5. "Dress it up" — closet with crown + glasses
6. "Catch apples & acorns" — mini-game mid-run

## Keyword check — Applyra, 2026-10-07 (after submission of 1.0.0)

Applyra Keywords Inspector, measured the day 1.0.0 went to review. These are Applyra's estimates (not Apple Search Ads
popularity). Autocomplete = where the store suggests the term; Market = ratings on a typical top-ranking app.

| Keyword | Store | Difficulty | Traffic | KEI | Competitor strength | Autocomplete | Market | Where it is in our listing |
|---|---|---|---|---|---|---|---|---|
| oink | US | Medium | **High** | 1.60 | 64 | 96 (3 chars, #1) | 26 (~38 ratings) | name |
| oink | GB | Easy | **High** | 2.53 | 22 | 76 (3 chars, #3) | 14 (~6) | name |
| piglet | US | Medium | **High** | 1.51 | 15 | 74 (4 chars, #2) | 24 (~27) | subtitle |
| piglet | GB | Medium | **High** | 1.49 | 11 | 70 (4 chars, #1) | 23 (~23) | subtitle |
| cute pig | US | Easy | Medium | 1.32 | 23 | 33 | 30 (~60) | name |
| cute pig | GB | Easy | Medium | 1.84 | 25 | 46 | 26 (~34) | name |
| pig simulator | US | Easy | Medium | 1.39 | 38 | 39 | 42 (~328) | name + subtitle |
| pig game | US | Medium | Medium | 1.24 | 55 | 56 (4 chars, #1) | 53 (~1k) | name + keywords |
| oink oink | US | Medium | Medium | 1.16 | 35 | 50 | 20 (~14) | name (one word) |
| pet games | US | Medium | Medium | 1.05 | **85** | 59 | 74 (~27k) | name + keywords |
| cute pet | US | Medium | Medium | 0.62 | 41 | 38 | 67 (~11k) | name; OuO cute pet ranks #23 |
| virtual pig | US | Easy | Low | 0.27 | 42 | 0 (not suggested) | 48 (~791) | name |

**Verdict: the shipped listing is aimed right.** The two highest-demand terms, `oink` and `piglet`, are in the name
and subtitle, and both have weak competition. The only pig *pet* apps ranking on them are "OiNK - Raise a Cute Pig"
(0 ratings, 2024) and "Piglet Garden" (134 ratings). On the old GATE-ASA bar (oink strong, cute pig decent), both pass.
`pet games` / `cute pet` are long-term: their top apps hold 11k–27k ratings.

**Watch:** "My Virtual Pet Pig **Oinky**" (221 ratings, 2014) ranks #2 for `virtual pig`. `Oinky` is our default pig
name and is visible in screenshots 1–4. It is not in the name, subtitle or keywords, but for 1.0.1 re-shoot the
screenshots with another name (the scene seed's `name`), so no competitor brand appears in store art.

**For 1.0.1 (keywords are locked while 1.0.0 is in review):** the field carries both `game` and `games`; Apple
matches plurals, so drop `games` and spend the 6 characters on an untested term, then re-inspect.

## Later (v1.1, only if English shows traction)

ja (`豚育成` T78/D30) and ko (`돼지 게임` T89/D29) listings are drafted in the research file §4.2. Both need a native-speaker read.
No Arabic, Turkish, Indonesian or Malay listing, ever.
