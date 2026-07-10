# Sector playbook: web
_Distilled top rules for website / web-app work. Loads at project open when PROGRESS.md declares `web`. Curated; refreshed by cogito-consolidate refresh-sectors._

- Use the `web-master` skill — it is the single design/build/verify authority. Static HTML + tokens.css + vanilla JS by default; Next.js only for auth/CMS/API.
- Read `node_modules/<framework>/dist/docs` for the INSTALLED API before writing framework code (this box's Next is modified: async params, uncached route handlers).
- "Live/working" = a logged-out stranger's load + rendered pixels + clean console — never the push, a green build, or an owner-session view.
- A deploy fingerprint must be a token introduced ONLY by this change and confirmed ABSENT from the old build; verify origin/main actually moved.
- Some Vercel projects have NO git auto-deploy (merging ships nothing) — verify the deploy mechanism + auth first; cogstack/paint each have their own path.
- Proof-integrity: every number/rating/quote must trace to a real source; cap invented trust claims. When there's no proof, the honest constraint IS the copy.
