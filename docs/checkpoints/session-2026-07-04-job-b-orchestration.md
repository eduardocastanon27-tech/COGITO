# Checkpoint — Cogito Job B + orchestration + Hermes verify

**Date:** 2026-07-04
**Arc:** from "is the cogito upgrade actually armed?" → shipped a two-tier project-memory system, a check-local-first project orchestrator, version-controlled the new-project skill, and verified Hermes writes lessons back into the shared brain.

## Decisions made (verified)
- **Global cogito injection was already ARMED** (Jul-3 ~15:50, in-session) — the "not armed" note was stale. Fixed at source + added a verify-first guard.
- **Two memory jobs split:** Job A = Cogito = lessons/metacognition (global); Job B = project progress per-project (`PROGRESS.md` in each repo).
- **Job B storage = distributed detail + thin central index** (council decision): per-project `PROGRESS.md` (loaded on `cd`, git-durable) + `ACTIVE-MISSION.md` as a one-line-per-project glance. Not Hermes-as-store; no embeddings (RAM); recall stays lexical.
- **Local FS is persistent** for daily terminal use — the "ephemeral container" fear applies to web/cloud sessions, not the Chromebook. So local files are durable; git adds backup, not daily survival.
- **Check-local-first:** open a project from the local copy (no clone); shallow-clone only if it's not on the box; never re-clone what's already here.

## Current state (all on `origin/main` `dccb54f` unless noted)
- **Job B, 5 slices:** (1) SessionStart loads repo-local `PROGRESS.md`; (2) Stop hook `cogito-progress.sh` auto-commits it locally (stamped, not gated, never pushes); (3) thin `ACTIVE-MISSION` index; (4) `[#proj:<slug>]` project-scoped recall; (5) `cogito-consolidate.sh suggest-skills` scaffolds un-indexed draft skills.
- **Orchestration:** `cogito-project.sh` (open/init/list, check-local-first) + `cogito-protocol` SKILL "Opening & creating projects" section.
- **`new-project-setup`** now version-controlled in the repo + step 3.5 creates `PROGRESS.md` (Job B day-one).
- **Pilots:** `paint/PROGRESS.md` (committed local) and `IDKWhatimdoing/PROGRESS.md` (created) both auto-load; 6 of 8 projects still lack a `PROGRESS.md`.
- **Memory hygiene:** 2 stale notes fixed at source (cogito-armed, roblox-removed) + 14 notes stamped `Verified 2026-07-04`; ledger drift merged to a conservation-verified 102-lesson superset (now on main).
- **Hermes write-back: VERIFIED** — a real Hermes turn ran `cogito-learn.sh` and a `[#hermes]` lesson landed in the runtime ledger + pending queue (independently confirmed). Hermes also *declined* a non-worthy lesson (has judgment).

## Open / next actions
- **Hermes autonomous capture unobserved:** test 2 was directed (proves the pipe); the unseen bit is Hermes recording a genuine gotcha *unprompted* on a real WhatsApp task. Watch for it.
- **Graduate `docs/skill-drafts/cogito-shell/`** only after it works in 2+ real sessions.
- **Create `PROGRESS.md` for the other satellites** (cogstack, storescript, wcpredict, …) lazily as touched — `cogito-project.sh init <name>`.
- Brain files (LESSONS/PLAYBOOK) + the `[#hermes]` lesson ride reconcile → canon at the next COGITO session (queue has them).
- This checkpoint is uncommitted on `main`'s working tree (no main touch without an explicit go).

## Corrections from Eduardo (highest-value)
- **"you thought it was armed already, what happened?"** — caught my stale greeting; drove the whole memory audit that found 2 stale notes.
- **"land on a branch then continue"** — kept `main` clean across the whole build; branch-per-slice became the pattern.
- **Terminal-only + "can't Claude just read it without cloning?"** — reframed storage (local is durable) and killed the clone-anxiety (repos are already on disk).

## Lessons banked this session
- `[#memory][#verify]` never state a system's armed/live status from a memory note — grep the real config first.
- `[#verify][#process]` a file's mtime dates its LAST write, not the change you care about — diff a backup/transcript.
- `[#shell][#verify]` `IGNORECASE` is gawk-only; this box is mawk — use `[Ll]` classes; verify text transforms by reading the file back.
- `[#git][#deploy]` cogito-guard gates ALL main pushes by design; on an explicit main-specific yes, use `COGITO_ALLOW_MAIN_PUSH=1` (its sanctioned override, not tunneling).
- `[#hermes][#verify]` Hermes write-back confirmed working from its own turn (2026-07-04).
- Playbook: council → verifiable slices on a feature branch; and the grep-status-lines → batch-verify memory-audit sweep.
