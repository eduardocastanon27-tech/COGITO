# Cogito upgrade — ACE playbook, global brain, Hermes, eval (2026-07-03)
_Living work log for the upgrade mission. Full plan + audit + research: the session plan file (curried-drifting-bachman); summary below is self-sufficient._

## Mission
Critique Cogito hard → research best $0 fixes → apply → wire into Hermes → prove with an eval that the brain lifts a weaker model (Opus 4.8 / Haiku). Constraints: $0, file-native, 2.7GiB RAM box, prompt-cache-safe, faceless.

## What the audit found (2026-07-03, three parallel scouts + web research)
- Cogito fires ONLY inside its own repo; global `~/.claude/settings.json` had no hooks. The Hermes brain (WhatsApp → proxy :8788 → `claude -p --model claude-opus-4-8 --dangerously-skip-permissions`, cwd `/home/mesmer`) got zero Cogito AND zero command guards.
- Only §5d (guard) is mechanically enforced; verification/review/capture rules are prose — the first thing weaker models drop.
- Ledger = scars only; no strategy playbook (ACE, arXiv 2510.04618: playbook + helpful/harmful counters lifted a smaller open model to GPT-4.1-agent level).
- ACTIVE-MISSION.md was 10.8KB (~2.7k tok/turn), stale, wrong faceless email, referenced a nonexistent checkpoint. 72/110 lessons unscored → decay inert. FSRS-5 built against roadmap #7's own ruling, never used. Plugin ships 2/4 hooks. No eval of benefit anywhere.
- Global SKILL.md was 5 lines ahead of canon with no write path home (clobber-on-next-session hazard).

## Phase status
- [x] **Phase 0** — baseline saved (4,816 tok/session; guard + gate selftests ALL PASS); at-risk global SKILL.md lines + `references/ecommerce-solo-2026.md` rescued into canon (branch `upgrade/ace-global-2026-07`); `~/.claude/settings.json` backed up.
- [x] **Phase 1a** — SKILL.md superset merge; `install_guarded()` clobber guard in session-start (verified live: warned + backed up + refused overwrite on real divergence).
- [x] **Phase 1b** — ACTIVE-MISSION.md rewritten ≤3k chars (old content verbatim in `2026-07-03-mission-file-compaction.md`); loader caps it at 6,000 chars (truncation notice verified firing).
- [ ] **Phase 1c** — plugin hooks parity + doc truth (INDEX.md, consolidate SKILL).
- [ ] **Phase 1d** — batch-score 72 unscored lessons (consent: diff → yes → commit).
- [ ] **Phase 1e** — FSRS→Leitner downgrade of cogito-review.sh (consent).
- [ ] **Phase 1f** — consolidation pass (110 lessons ≥ 60 trigger; after 1d).
- [ ] **Phase 2** — PLAYBOOK.md + PLAYBOOK-ARCHIVE.md + COGITO-CORE.md + SKILL §4b wins + converge/gate/sync/recall/consolidate integration.
- [ ] **Phase 3** — ONE batched owner-approved push to main.
- [ ] **Phase 4** — global install: `~/.claude/cogito/bin/`, settings.json hooks (SessionStart matcher `startup|clear|compact` — NEVER `resume`), global loader (kill-switches, no network, ≤5k chars), recall fix, learn Mode-3 + reconcile.
- [ ] **Phase 5** — Hermes: offline proxy round-trip proof; yolo deny-under-bypass probe (record result honestly); instinct.py → ledger routing (consent); cockpit line.
- [ ] **Phase 6** — eval: 8 scar-derived tasks, haiku+opus × bare/brain (both arms COGITO_GLOBAL=0), anchored rubric, blind judge; commit scorecard as measured.
- [ ] **Phase 7** — budget verification (repo ≤3k tok, global ≤1.2k), 10-point checklist, checkpoint + finish-line review.

## Key decisions
- Global scripts live in `~/.claude/cogito/bin/` (installer-copied, VERSION-stamped; deliberate updates only — supply-chain posture).
- Kill-switches: `COGITO_GLOBAL=0` env or `~/.claude/cogito/DISABLED` file — instant global rollback, also the eval's control-arm isolation.
- Batch-score + counter edits ride converge (local path); the PR gate keeps HOLDing edits — correct by design.
- Playbook delta discipline (ACE): append new bullets, bump counters in place, never rewrite wholesale.
