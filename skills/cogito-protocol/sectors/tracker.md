# Sector playbook: tracker
_Distilled top rules for health / experiment tracker work. Loads at project open when PROGRESS.md declares `tracker`. Thin seed — grows as tracker scars are captured._

- Hard-science rigor: face the real science including its limits, no unlabeled woo, honest sample sizes, correlation≠causation, and trust the owner's own n=1 data over the literature.
- Use the `cogstack` skill for CogStack itself (Alpine.js single-file PWA, Vercel, Capacitor).
- CogStack's Vercel project has NO git auto-deploy — every prod deploy is an explicit `vercel deploy --prod` run; verify with a logged-out curl + content grep.
