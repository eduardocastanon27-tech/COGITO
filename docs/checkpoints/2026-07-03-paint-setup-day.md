# Cogito Checkpoint — 2026-07-03 — Paint setup day

## Mission
Finish jlpaintingsc.com's setup end-to-end: audit everything, verify the lead pipeline, remove fabricated review claims, prep get-found work.

## What changed (all outcome-verified)
- **Lead pipeline proven form→DB**: live test lead 200 → Atlas doc → deleted after. **No real lead was ever missed** (all 8 stored submissions = tests/spam).
- **Notification email root-caused**: CMS `RESEND_API_KEY` is INVALID (Resend 401 in runtime logs); `notifyEmail` was empty since launch — now `eduardocastanon27@gmail.com`. Fix = owner pastes a valid resend.com key into the CMS Vercel env.
- **Fabricated 5.0/320 review claims removed and LIVE** (paint `5aa3656`, deploy verified by live-HTML grep). Rating bar auto-returns when `googleReviewUrl` gets the real GBP link.
- **Guardrail corrected**: ACTIVE-MISSION's "delete CMS Vercel deploy / laptop-only" intent overwritten — that deploy is the paint site's only lead path (offline mode is gone from CMS code since `899e8c6`).
- `LISTINGS-content.md` (Nextdoor/Angi/Thumbtack paste-ready) in the paint repo.
- Ledger +3 scars (endpoint-consumers, notification-leg-is-the-DoD, ledger-sync-direction) — 134 lines, both copies identical.

## Corrections (highest-value memory)
- **Near-miss: blind `cp` home→repo ledger deleted 14 repo-only lessons** (the 07-02 rescue had landed repo-side only). Caught via diffstat (15 deletions for a 2-line add) BEFORE push; merged to superset, amended. Rule now in ledger.
- Classifier denied 2 prod writes (notifyEmail before explicit go; self-minted admin JWT for resync). Respected both; notifyEmail went through after the owner's explicit "go", resync handed to the owner's dashboard click.

## Afternoon round (all verified unless marked)
- **Email leg WORKS end-to-end**: owner set a valid RESEND_API_KEY + redeployed; test lead → notification received in his Gmail inbox (from onboarding@resend.dev, subject `New "contact" submission — paint`). Test doc deleted, baseline 8.
- **Google review link LIVE on the site** (`38fd239`): `globals.googleReviewUrl = https://g.page/r/CRfFJFf8Gf_7ECA/review`; rating bar = honest "Review us on Google" CTA (hardcoded 5.0 removed until real reviews exist). Live-HTML verified.
- **GBP: VERIFIED** (screenshot-confirmed). Duplicate second profile ("Verification required") DELETED by owner — Manager shows 1 business, 100% verified. **Google organic indexing confirmed** (jlpaintingsc.com appears in results). 29 profile views already.
- **GBP phone is WRONG**: shows (706) 910-2635 (Eduardo's personal); real job line = (803) 806-2190. Owner fixing — possibly via a Claude-for-Chrome test drive (his idea; extension suggested, container can't reach ChromeOS browser). Also: primary category → "Painter"; Complete Info from GBP-content.md.
- **Translator call-flow decision OPEN**: owner (Spanish-only) + Eduardo (English bridge). Option 1 $0: owner's native "Add call → merge" (cheat sheet in Spanish offered). Option 2 ~$3-5/mo: Twilio number ringing both into an auto-conference — if chosen, do BEFORE posting listings (number cements then).

## Open / next
- ~~RESEND_API_KEY~~ DONE+verified. ~~Resync #1~~ DONE — but **one MORE Resync click owed** (review-link content edit) before any CMS Publish.
- Owner now: GBP phone → (803) 806-2190 + category "Painter" + Complete Info; decide call-flow (Option 1/2); Claude-for-Chrome test.
- Owner, this week: text the review link to past customers (top lever); Search Console; post 3 listings AFTER the call-flow/number decision; photos + license # + logo from painter; confirm whether "500+ Projects" is real.
- Carried: teacher neural-voice deploy; PAT revoke-or-rotate; $5 AI credit call.
- Paint SESSION-STATE-2026-07-03.md committed in the paint repo (holds the full detail).
