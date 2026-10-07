# Test drive — Oink 1.0.0+1 · 2026-10-07 13:20
iPhone 17 Pro (8E58B515) · iOS Simulator, Xcode 27.0 · build 56 s (then 30 s with clock seam) · commit f605124 · seams: DEBUG_RESET_FIRST_RUN, DEBUG_INSPECTOR, then DEBUG_CLOCK_OFFSET_HOURS=10 (no reset)

PASS 43 · FAIL 0 · BLOCKED 1 · SKIP 3   (of 47 criteria incl. F0)

Audio is not observable on the simulator and the app has no sound-trace seam, so sound halves of criteria cite the
widget tests that assert on `SfxPlayer.log` (`test-drive/20261007-1301/unit-widget-tests.log`).

| Criterion | Verdict | Evidence | Note |
| --- | --- | --- | --- |
| F0 builds for the simulator | PASS | test-drive/20261007-1301/F1-c1-basket.png | fixed since the previous report (deployment target 15.0) |
| F1-c1 basket, name step, chips, Oinky default | PASS | test-drive/20261007-1301/F1-c1-basket.png, test-drive/20261007-1301/F1-c1-name-step.png, test-drive/20261007-1301/F1-c1-chip-peanut.png | chip "Peanut" filled the field |
| F1-c2 four tips, then Home with the name | PASS | test-drive/20261007-1301/F1-c2-tips.png, test-drive/20261007-1301/F1-c2-tips-scrolled.png, test-drive/20261007-1301/F2-c1-home.png | 4th tip is below the fold (Finding 1) |
| F1-c3 onboarding never returns | PASS | test-drive/20261007-1301/F1-c3-relaunch-plus10h.png | reinstall + relaunch went straight to Home with Peanut |
| F2-c1 name, level ring, acorns, four meters | PASS | test-drive/20261007-1301/F2-c1-home.png | |
| F2-c2 dock opens each mode | PASS | test-drive/20261007-1301/F4-c1-feed-tray.png, test-drive/20261007-1301/F5-c1-bath-mud.png, test-drive/20261007-1301/F6-c1-game-ready.png, test-drive/20261007-1301/F7-c1-asleep.png, test-drive/20261007-1301/F9-c1-closet-hats.png | |
| F2-c3 bubble states mood / urgent need, anchored | PASS | test-drive/20261007-1301/F7-c3-night-line-45s-band.png, test-drive/20261007-1301/F3-c1-snout-oink-bubble.png | observed the mood line on the 20 s tick; the need-line choice (`mostUrgent`) is unit-tested |
| F2-c4 breathing, blinking, pupils track finger | PASS | test-drive/20261007-1301/F2-c4-idle-sheet.png, test-drive/20261007-1301/F2-c4-eyes-follow-finger.png | eye highlights shift with the finger; subtle with solid-dark eyes |
| F2-c5 stage proportions differ | PASS | test-drive/20261007-1301/F2-c5-stages.png | rendered by the app's PigPainter (pig_preview_dump_test); level 5 not reachable in-session |
| F2-c6 portrait, safe areas, 320×568 @1.6× | PASS | test-drive/20261007-1301/F2-c1-home.png, test-drive/20261007-1301/unit-widget-tests.log | small-phone layout from widget tests |
| F3-c1 zone reactions + sounds | PASS | test-drive/20261007-1301/F3-c1-snout-oink-bubble.png, test-drive/20261007-1301/F3-c1-tail-oinkQ.png, test-drive/20261007-1301/F3-c1-ear-flop.png, test-drive/20261007-1301/unit-widget-tests.log | head and sounds via widget tests; see Finding 2 |
| F3-c2 belly rub raises Fun | PASS | test-drive/20261007-1301/unit-widget-tests.log | "snout tap always says Oink!; a belly rub raises Fun" |
| F3-c3 sleeping pig grumbles on tap or rub | PASS | test-drive/20261007-1301/unit-widget-tests.log | widget test incl. rub + snore + no snore behind Settings |
| F3-c4 haptics | SKIP | — | needs a real device |
| F4-c1 free foods, treats locked with level | PASS | test-drive/20261007-1301/F4-c1-feed-tray.png | "Lv 2" lock |
| F4-c2 drag → munch, Tummy and XP up | PASS | test-drive/20261007-1301/F4-c2-feed-apple-sheet.png | Tummy 79.6→97.5, XP 1→3, "Yum!" |
| F4-c3 full → "I'm full!", head shake, Tummy unchanged | PASS | test-drive/20261007-1301/F4-c3-full-refusal-sheet.png | Tummy stayed 97.5 |
| F4-c4 diary shows favourite food | PASS | test-drive/20261007-1301/F4-c4-diary.png | "Favorite snack: Apple" |
| F5-c1 mud in proportion to low Clean | PASS | test-drive/20261007-1301/F5-c1-bath-mud.png | splotch at Clean 59.5 |
| F5-c2 sponge bubbles, spots removed | PASS | test-drive/20261007-1301/F5-c2-scrub-sheet.png | Clean 59.4→95 |
| F5-c3 shower rinses, sparkle, Clean raised | PASS | test-drive/20261007-1301/F5-c3-rinse-sheet.png | Clean 100, "Squeaky clean!" |
| F6-c1 drag to catch, bees to dodge | PASS | test-drive/20261007-1301/F6-c1-midgame.png, test-drive/20261007-1301/F6-c3-result.png | |
| F6-c2 45 s countdown, then result | PASS | test-drive/20261007-1301/F6-c1-game-ready.png, test-drive/20261007-1301/F6-c1-midgame.png, test-drive/20261007-1301/F6-c3-result.png | 45→30; ended early on 3 stings (allowed) |
| F6-c3 pays score ÷ 3, Fun +25 | PASS | test-drive/20261007-1301/F6-c3-result.png, test-drive/20261007-1301/F6-c3-home-after-game.png | score 11 → +3 acorns; Fun 81.6→99.9 (cap) |
| F7-c1 dim, Zzz, snores, Energy refills | PASS | test-drive/20261007-1301/F7-c1-asleep.png, test-drive/20261007-1301/unit-widget-tests.log | snore + refill-while-closed via tests |
| F7-c2 tapping the moon wakes | PASS | test-drive/20261007-1301/F7-c1-asleep.png, test-drive/20261007-1301/F7-c2-moon-woke.png | |
| F7-c3 night line 22:00–07:00 | PASS | test-drive/20261007-1301/F7-c3-night-line.png, test-drive/20261007-1301/F7-c3-night-line-45s-band.png | "It's late… bedtime?" at 23:1x (clock +10 h) |
| F8-c1 decay rates | PASS | test-drive/20261007-1301/F6-c3-home-after-game.png, test-drive/20261007-1301/F1-c3-relaunch-plus10h.png | +10 h: tummy −60, clean −30, fun −50, energy −40, exact |
| F8-c2 elapsed time on resume, floor 5 | PASS | test-drive/20261007-1301/F1-c3-relaunch-plus10h.png, test-drive/20261007-1301/unit-widget-tests.log | |
| F8-c3 XP curve; level-up celebration | BLOCKED | test-drive/20261007-1301/F4-c4-diary.png | curve visible (12/32 XP to level 2); reaching level 2 takes ~20 XP of care and the app has no XP seam, so the dialog was not seen. Logic: pet_logic_test "level up emits events" |
| F8-c4 daily gift once a day | PASS | test-drive/20261007-1301/F8-c4-gift-dialog.png | 13→18; button gone afterwards |
| F8-c5 care bonus when need low | PASS | test-drive/20261007-1301/unit-widget-tests.log | bath at Clean 59 (not low) correctly paid none |
| F8-c6 acorns only spent in Closet | PASS | test-drive/20261007-1301/unit-widget-tests.log, test-drive/20261007-1301/F9-c3-wearing-crown.png | |
| F9-c1 tabs; level/price locks | PASS | test-drive/20261007-1301/F9-c1-closet-hats.png | |
| F9-c2 buy deducts; too poor blocked | PASS | test-drive/20261007-1301/F9-c2-buy-confirm.png, test-drive/20261007-1301/F9-c3-wearing-crown.png, test-drive/20261007-1301/F9-c2-too-poor-snackbar.png | 18→3; "You need 27 more acorns…" |
| F9-c3 equip with live preview; room → Home | PASS | test-drive/20261007-1301/F9-c3-wearing-crown.png, test-drive/20261007-1301/F1-c3-relaunch-plus10h.png, test-drive/20261007-1301/unit-widget-tests.log | room background via widget test |
| F9-c4 seasonal items by config | PASS | test-drive/20261007-1301/F9-c1-closet-hats.png, test-drive/20261007-1301/unit-widget-tests.log | Witch hat shown in its October window; hide-by-config unit-tested |
| F10-c1 toggles apply and persist | PASS | test-drive/20261007-1301/F10-c2-about.png, test-drive/20261007-1301/F10-c1-sound-off-persisted.png | Sounds off survived reinstall |
| F10-c2 rename, privacy, support, About | PASS | test-drive/20261007-1301/F10-c2-settings.png, test-drive/20261007-1301/F10-c2-rename-dialog.png, test-drive/20261007-1301/F10-c2-about.png | external links not opened |
| F10-c3 start over → onboarding | PASS | test-drive/20261007-1301/unit-widget-tests.log | widget test |
| F10-c4 one versioned blob; corrupt → defaults | PASS | test-drive/20261007-1301/F1-c3-relaunch-plus10h.png, test-drive/20261007-1301/unit-widget-tests.log | |
| F11-c1 published JSON == defaults | PASS | test-drive/20261007-1301/unit-widget-tests.log | |
| F11-c2 junk falls back / clamps | PASS | test-drive/20261007-1301/unit-widget-tests.log | |
| F11-c3 first launch with no network | PASS | test-drive/20261007-1301/unit-widget-tests.log | |
| F12-c1 60 fps, capped particles | SKIP | test-drive/20261007-1301/unit-widget-tests.log | particle cap tested; fps needs a profile build on a device |
| F12-c2 silent switch, mixes with other audio | SKIP | — | needs a real device |
| F12-c3 tests cover systems and main flows; analyze/test green | PASS | test-drive/20261007-1301/unit-widget-tests.log | 58 passed, 3 skipped (dev tools) |

## Regressions
None. The previous report had only F0 FAIL, which now passes.

## Findings
1. **Onboarding:** the 4th tip ("Care every day to grow up…") is below the fold on iPhone 17 Pro, and nothing hints that the list scrolls. Evidence: test-drive/20261007-1301/F1-c2-tips.png vs test-drive/20261007-1301/F1-c2-tips-scrolled.png.
2. **Touch zones:** one tap at (276,390), on the right ear, produced the belly reaction ("Hehe, that tickles!"), and the diary counts that belly rub. It did not reproduce: the same point gave the ear flop next time (test-drive/20261007-1301/F3-c1-ear-flop.png), and a widget-test probe maps that point to the ear. This is possibly a simulator touch artifact, since the earlier burst frames show the pig mid-hop. Watch it on device.
3. **Night room:** at 23:xx (clock +10 h) the awake room still shows a daytime window. It only darkens while asleep (test-drive/20261007-1301/F7-c3-night-line.png). This is cosmetic and not a criterion.
4. **Missing seams:** there is no XP/level seam, so F8-c3's dialog could not be reached. There is no sound-trace log, so audio can only be checked in widget tests.

## Next for /build
None (no FAIL rows).
