# ACTIVE MISSION — resume pointer
_Short on purpose: this file rides every COGITO-repo session (budget ~750 tok; loader hard-caps 6,000 chars). It is the **portfolio glance**. Per-project detail lives in each repo's own `PROGRESS.md` (auto-loads when you `cd` into that project); deeper history in `docs/checkpoints/`. Never let this file grow — thin it, point outward. Plain, short, adult-to-adult._

When the user says "Cogito": greet in one line, confirm, continue. Don't re-interview.

## Mission
Box-wide file-native brain: lessons/metacognition that stop repeated mistakes (SHIPPED + armed) + per-project progress memory so any session resumes where we left off. $0, terminal-only.

## Cogito core (this repo's own threads — detail stays here)
- **Cogito upgrade 2026-07 — SHIPPED + ARMED (2026-07-03).** Playbook + COGITO-CORE live; global hooks armed box-wide (incl. Hermes brain; guard binds under yolo); eval proves the lift (+0.62/+0.75). Kill: `COGITO_GLOBAL=0`. Detail: `docs/checkpoints/2026-07-03-cogito-upgrade.md`.
- **Job B — project-progress memory — IN PROGRESS (2026-07-04).** Two-tier: lessons global, progress per-project (`PROGRESS.md` in each repo, loaded on `cd`, written back + auto-committed by a Stop hook). Slices 1–2 done on branch `cogito/job-b-progress` (lazy load + write-back, verified). Next: slice 3 (this index) → 4 (domain-relevant lesson pull) → 5 (skill scaffolding). Design detail: `docs/checkpoints/memory-audit-2026-07-04.md` + council in-session.
- **Brain write-back — ON.** Append-only lesson PRs auto-merge; anything editing canon waits for the owner's one-tap. Private satellites drain via `scripts/cogito-drain.sh <path>`. Detail: `docs/checkpoints/2026-06-24-writeback-pipeline.md`.

## Project index (satellites — one line each; detail in each repo's PROGRESS.md)
- **paint** (jlpaintingsc.com) — live; lead pipeline verified. Owner items → `~/projects/paint/PROGRESS.md`.
- **biho-cms** (idk-whatimdoing) — live; **never delete its Vercel deploy** (paint's lead form POSTs to it). Detail → `~/projects/IDKWhatimdoing/PROGRESS.md`.
- **cogstack** (cogstack-edu.vercel.app) — live nootropics tracker. `PROGRESS.md` when next worked.
- **storescript** (storescript.vercel.app) — live; API blocked on $5 Anthropic credit. `PROGRESS.md` when next worked.
- **wcpredict** — Elo+Poisson WC model; `python3 predict.py`. `PROGRESS.md` when next worked.
- **teacher** — deployed private (Vercel `cogito`); neural voice on a branch, NOT deployed; paid-model/voice question open. Detail: `docs/checkpoints/2026-06-15-teacher-deployed-brain-shared.md`.

## Resume here (next)
1. Job B: build slice 4 (generic vs project-specific lesson tags for domain-relevant pull) then slice 5 (skill scaffolding). Then land branch `cogito/job-b-progress` to `main` (owner go).
2. Owner items: $5 AI credit (unblocks CMS assistant + StoreScript), PAT revoke-or-rotate, paint GBP fixes (phone (803) 806-2190 + category "Painter", call-flow).
3. Watch the armed global brain in daily use; next consolidation pass when the severe set nears its 7k cap.

## Guardrails (always on)
- One brain = `main`. Converge pushes brain files ONLY. A direct/manual `main` push needs an EXPLICIT per-time yes — a generic "go"/"continue" is NOT main consent.
- Job B `PROGRESS.md` writes commit LOCALLY to the project repo, faceless, NEVER pushed — pushing stays a deliberate act.
- Faceless: git identity = `Cogito <291881939+COGITO-SUM-cloude@users.noreply.github.com>` (NEVER the bare `cogito@users.noreply.github.com`).
- Deploys stay private until the user says publish. Keys least-privilege, read in-process never argv.
- Verify by running/re-reading — never "probably". Before deleting/retiring ANY deployment, enumerate its inbound consumers first.
