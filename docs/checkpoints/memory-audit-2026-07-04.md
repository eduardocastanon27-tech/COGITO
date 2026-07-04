# Checkpoint — Cogito memory audit (stale-status sweep)

**Date:** 2026-07-04
**Session topic:** Triggered by "cogito" → question about global-injection arm state → full memory-note status audit.

## Decisions / findings (verified)
- **Cogito global injection is ARMED** (Jul 3 ~15:50, authorized in-session `369a43d8`), NOT "built not armed." All 3 hooks live in `~/.claude/settings.json` (SessionStart→cogito-global-load, PreToolUse(Bash)→cogito-guard, UserPromptSubmit→cogito-recall). Verified via `grep -o 'cogito-[a-z-]*\.sh' ~/.claude/settings.json`. Ran it — neither Eduardo at a terminal nor Hermes; the upgrade session did, at Eduardo's explicit "go."
- **Memory sweep: 2 stale notes of ~15 checkable; both fixed.**
  1. `cogito-upgrade-2026-07` — said "not armed"; was armed. Fixed body + MEMORY.md index + added a VERIFY-FIRST guard with the exact check command.
  2. `roblox-studio-crostini-setup` — said "Studio remains installed, shim/config left in place"; whole stack (grapejuice, studio prefix, ramshim .so, config) is **removed**. Downgraded note to a rebuild-recipe; fixed body + index.
- **13 notes verified current + stamped** `Verified 2026-07-04` with the specific evidence checked.

## Current state (what exists, where)
- **Memory store** `~/.claude/projects/-home-mesmer/memory/` — 31 notes; 14 now carry dated verification stamps; 2 index lines in MEMORY.md corrected.
- **Live services** all HTTP 200 (logged-out): BIHO `idk-whatimdoing.vercel.app`, CogStack `cogstack-edu.vercel.app`, StoreScript `storescript.vercel.app`, Paint `jlpaintingsc.com`. Ports 3000 (WA bridge) + 8788 (claude proxy) LISTENING; gateway pid 328.
- **COGITO repo** (`~/projects/COGITO`, branch **main**): `LESSONS.md` modified (uncommitted) with 2 new scars; `~/.claude/cogito-pending-{lessons,playbook}.md` queued for next reconcile (1 new playbook strategy). This checkpoint file: written, **uncommitted**.

## Lessons captured (in ledger via cogito-learn.sh)
- `[#memory][#verify] [I:6]` Never state a system's arm/live/deploy status from a memory note alone → grep the actual config/port/hook first.
- `[#verify][#process] [I:6]` A file's mtime dates its LAST write, not the change you care about → diff a backup or read the transcript to date a specific change.
- `[playbook]` Memory-note stale-status audit: grep status-bearing lines across all notes → batch-verify with logged-out curls + disk/port checks → fix only failures.

## Corrections from Eduardo (highest value)
- "you thought it was armed already, what happened?" — caught my stale greeting; drove the whole audit. I was wrong twice (parroted the note, then misread the 08:32 mtime as the arming) before a grounded check settled it. The pushback is what turned up two real record errors.

## Open / next actions
- **COMMIT HELD** (needs explicit go + branch choice): this checkpoint, the uncommitted `LESSONS.md`, and the pending queues. COGITO is on main; cogito automation auto-merges pushed `claude/*` branches — nothing pushed.
- StoreScript `<title>` still boilerplate "Create Next App" — 1-line polish when in that repo.
- 3 claims unverifiable from here (flagged, not passed): BIHO Vercel env (RESEND/CRON), StoreScript API-500/credits state, "Netlify has no cogito site."
- Not verified this pass: `biho-cms-pr-token-limit` (testing triggers a real auto-merge), `income-experiment` (umbrella, no single status).
