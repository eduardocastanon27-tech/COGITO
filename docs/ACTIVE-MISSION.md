# ACTIVE MISSION — resume pointer
_Short on purpose: this file rides every session (budget ~750 tok; the loader hard-caps it at 6,000 chars). Detail lives in `docs/checkpoints/` — move it there, never let it grow here. Talk adult-to-adult: plain, short, no jargon._

When the user says "Cogito": greet in one line, confirm, continue. Don't re-interview.

## Mission
Upgrade Cogito into the box-wide brain: ACE strategy playbook, global hooks (every session incl. Hermes), a real eval proving the lift, $0 and file-native. Live work log: `docs/checkpoints/2026-07-03-cogito-upgrade.md`.

## Active threads
- **Cogito upgrade 2026-07 — SHIPPED + ARMED (2026-07-03).** Playbook + COGITO-CORE live; global hooks armed box-wide (incl. the Hermes brain — all 3 probes PASS; guard deny binds even under yolo); eval proves the lift (verification +0.62/+0.75). Kill-switch: `COGITO_GLOBAL=0`. Detail: `docs/checkpoints/2026-07-03-cogito-upgrade.md`.
- **Paint site (jlpaintingsc.com)** — lead pipeline verified end-to-end (email received; review link live; GBP verified, duplicate deleted). Owner owes: one CMS Resync before any Publish; GBP phone → (803) 806-2190 + category "Painter"; call-flow decision before posting listings. Detail: `docs/checkpoints/2026-07-03-paint-setup-day.md`.
- **CMS (idk-whatimdoing)** — live + working; AI assistant blocked on $5 credit (owner-side). NEVER delete its Vercel deploy: the paint site's estimate form POSTs to it (verified live dependency).
- **Teacher** — deployed private on Vercel project `cogito`; neural voice committed on a branch, NOT deployed; the paid-model/voice question is open. Detail: `docs/checkpoints/2026-06-15-teacher-deployed-brain-shared.md`.
- **Brain write-back** — ON (append-only lesson PRs auto-merge; anything that edits canon waits for the owner's one-tap). Private satellites drain locally via `scripts/cogito-drain.sh <path>`. Detail: `docs/checkpoints/2026-06-24-writeback-pipeline.md`.

## Resume here (next)
1. Watch the armed global brain in daily use (playbook counters + recall relevance); next consolidation pass when the severe set nears its 7k cap.
2. Owner items: $5 AI credit (unblocks CMS assistant + StoreScript), PAT revoke-or-rotate, paint GBP fixes above.

## Guardrails (always on)
- One brain = `main`. Converge pushes brain files ONLY. A direct/manual `main` push needs an EXPLICIT per-time yes — a generic "go"/"continue" is NOT main consent.
- Faceless: git identity = `Cogito <291881939+COGITO-SUM-cloude@users.noreply.github.com>` (NEVER the bare `cogito@users.noreply.github.com` — it miscredits an unrelated real account).
- Deploys stay private until the user says publish. Keys least-privilege, read in-process never argv.
- Verify by running/re-reading — never "probably". Before deleting/retiring ANY deployment, enumerate its inbound consumers first.
