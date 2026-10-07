# Remote config

The authoritative schema for this app's remote config blob. Read before adding
a key.

## Where it lives

Oink does **not** use Firebase Remote Config (`app.yaml` → `features.remote_config: false`). The config is a public JSON file:

- Live URL: `https://raw.githubusercontent.com/OuadieZerhouni/app-configs/main/oink-pet/config.json`
  (`kRemoteConfigUrl` in `lib/core/remote_config.dart`)
- Source of truth in this repo: `config/config.json`. Edit here, copy to the `app-configs` repo, push. raw.githubusercontent
  caches for ~5 minutes; the app adds a 10-minute cache-buster, so a change reaches users on their next launch within ~15 min.

`test/remote_config_test.dart` asserts that `config/config.json` parses to **exactly the code defaults**, so publishing the
file as committed can never change behaviour. Changing a live value therefore means: edit the copy in `app-configs` only, and
note it in the table at the bottom of this file.

## How the app reads it

- Startup never waits on the network: it applies the cached copy (SharedPreferences `remoteConfigCache`) or the code
  defaults, then fetches in the background (6 s timeout) and applies the result live.
- A fetch that fails, times out, or returns malformed JSON is ignored, and the last good copy stays.
- Every value is type-checked; numbers are clamped; an unknown key is ignored; a missing key keeps its code default.

## Rules

- **Config tunes behaviour; it never invents it.** A flag may turn a built feature off or change a number. It cannot add an item,
  a food, or a screen.
- **Every key has a safe code default**, because the very first launch on a new install has no fetched config yet.
- `ads.enabled` is read but **never acted on** in v1 (there is no ad code). It exists so the schema does not change when ads arrive.

## Keys

| Key | Type | Default | Clamp / rule | Effect |
|---|---|---|---|---|
| `schemaVersion` | int | 1 | | Informational |
| `minSupportedVersion` | semver | `1.0.0` | | If the app is older **and** `updateUrlIos` is set, a blocking "please update" dialog shows |
| `latestVersion` | semver | `1.0.0` | | Informational (no nag for optional updates) |
| `updateUrlIos` | url | `""` | empty = never prompt | Set to `https://apps.apple.com/app/id<APP_ID>` once the App Store record exists |
| `announcement.enabled` | bool | false | needs a non-empty `id` and a title or body | One dialog per `id`, shown once per install |
| `announcement.id` | string | `""` | | Change it to show a new announcement |
| `announcement.title` / `.body` | `{lang: text}` or string | | falls back to `en`, then any language | |
| `announcement.url` | url | `""` | optional | Adds an "Open" button |
| `features.miniGame` | bool | true | | Apple Catch button in the dock |
| `features.dailyGift` | bool | true | | Daily acorn gift button |
| `features.seasonalItems` | bool | true | | Master switch for seasonal foods/outfits |
| `economy.drainMultiplier` | number | 1.0 | 0.2 – 3 | Speed at which needs drop |
| `economy.restMultiplier` | number | 1.0 | 0.2 – 3 | Speed at which energy refills while asleep |
| `economy.dailyGiftBase` | int | 5 | 1 – 50 | Day-1 gift; the streak adds +1/day, capped at 7 |
| `economy.priceMultiplier` | number | 1.0 | 0.25 – 4 | Closet prices (free items stay free) |
| `seasonal.<id>` | `{enabled, from: "MM-DD", to: "MM-DD"}` | halloween 10-01→11-07, winter 12-01→01-10 | invalid dates keep the built-in window; windows may wrap the new year | Only ids the code knows (`halloween`, `winter`) unlock anything |
| `reviewPrompt.enabled` | bool | true | | iOS rating prompt after a happy moment |
| `reviewPrompt.minDays` | int | 3 | 1 – 60 | Days since adoption before asking |
| `reviewPrompt.minLevel` | int | 3 | 1 – 50 | Pig level before asking |
| `ads.enabled` | bool | false | | Reserved; ignored in v1 |
| `links.privacyPolicy` / `links.support` | url | the `app-configs` pages | | Settings links |
| `links.supportEmail` | string | `""` | | Reserved; not shown in v1 (support goes through the support page) |

## Change log of live values

| Date | Key | From → To | Why |
|---|---|---|---|
| 2026-10-07 | (initial publish) | — | Matches code defaults |
