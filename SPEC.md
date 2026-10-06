# SPEC — Oink

> Written by `/new-app` from the intake interview. This is the contract the
> `/build` loop implements and `/test-drive` verifies. A feature is done when
> its acceptance criteria pass — not when it feels done.

## One line

What the app is, for whom, in one sentence.

## Audience & tone

Who opens it, how often, in what mood. Drives copy, defaults, and how loud
onboarding may be.

## Screens

| Screen | Purpose | Entry |
| --- | --- | --- |
| Home | The one thing the app does | launch |

## Features

### F1 — <name>

What it does, in two sentences.

**Acceptance criteria**
- [ ] Observable behaviour 1 (something a test or a simulator drive can check)
- [ ] Observable behaviour 2
- [ ] Works in every locale in `app.yaml` (RTL included when `ar` is present)

## Non-goals

What this version deliberately does not do. Protects the build loop from scope drift.

## Data & permissions

What is stored (local / remote), and every OS permission with its one-line
justification — these become the `Info.plist` usage strings and the App Privacy
answers.

## Monetization

none | ads | iap | both — and, if any, what is gated behind it.

## Store

- Category:
- Age rating notes (violence, gambling, user-generated content — usually all "none"):
- Keyword seeds (5–10 words a user would type):
- Privacy policy: hosted at `landing/privacy.html` via GitHub Pages
