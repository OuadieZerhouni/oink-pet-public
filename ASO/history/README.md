# ASO history

One file per app version, `v<version>.md`, recording two things:

1. **Metadata exactly as shipped**, per localization. Without this, a change in
   rank cannot be attributed to a change you made.
2. **Dated rank snapshots** — keyword, rank, traffic, difficulty. `—` means
   outside the top 100.

## Cadence

At submission, then **+7 days**, **+14 days**, then monthly. Plus an ad-hoc
snapshot immediately before any metadata change, so the "before" always exists.

A new version file only when metadata actually changes; a build with identical
metadata appends its snapshots to the existing file.

## Confounders are part of the record

Every snapshot section opens with anything that could explain movement other
than the metadata — a paid promo, a feature, a competitor's launch, a holiday.
A rank chart without its confounders invites a wrong conclusion, and the whole
point of this directory is attribution.

Use a marked-events table:

| Date | Event | Effect on data |
| --- | --- | --- |
| | | |
