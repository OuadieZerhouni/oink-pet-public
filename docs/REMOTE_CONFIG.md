# Remote config

The authoritative schema for this app's remote config blob. Read before adding
a key.

## The four-file convention

| File | Role |
| --- | --- |
| `remote_config_current.json` | Snapshot of what is **live** right now |
| `remote_config_proposed.json` | Changes staged for the next push |
| `remote_config_template.json` | Every key with a safe default and a comment |
| `remote_config_android_test.json` | Android/dev overrides |

Keeping `current` in the repo is what makes "what is live?" answerable without
opening a console — and reviewable in a diff. Validate JSON after every edit;
a malformed blob degrades to code defaults silently, which looks like the
feature never shipped.

## Rules

- **Config tunes behaviour; it never invents it.** A flag may change a number,
  a probability, or a phrase list. It must not be able to request behaviour the
  app has no code for.
- **Every key has a code default** that is safe on its own, because the very
  first launch on a new install has no fetched config yet.
- **Kill switches default to off.** A feature ships dark and is enabled
  deliberately, per platform if needed.
- Malformed values clamp or fall back; they never crash. One test per config
  section asserts this.

## Sections

_(Add one `##` block per section as the app grows, each listing keys, types,
clamps, and the code default.)_
