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
- [x] **Phase 1c** — plugin hooks parity (4/4 shipped) + doc truth fixed (INDEX.md, consolidate SKILL, threshold claims).
- [x] **Phase 1d** — all 72 unscored lessons scored [I:1-10]; conservation-verified (110 lines, zero content changes); owner-approved.
- [x] **Phase 1e** — FSRS-5 → Leitner ladder (same CLI, 172→135 lines, sandbox-verified grade round-trip; learning-log header updated).
- [x] **Phase 1f** — consolidation: 33 raw → 13 higher-tier rules, 110→91 active, verify gate PASS 5/5. **Bonus fix: the gate itself had a nondeterministic false-FAIL** (grep -q SIGPIPE under pipefail → herestring); scar captured.
- [x] **Phase 2** — PLAYBOOK.md (12 seed strategies, ACE format) + PLAYBOOK-ARCHIVE + COGITO-CORE.md (10 directives, 2.2k chars) + SKILL §4b wins extension + full mechanical integration (converge BRAIN_PATHS, gate playbook-append auto-merge with 14/14 selftests, sync playbook print + [#critical] tag-match fix, recall playbook grep + ~/.claude fallback + kill-switches, consolidate playbook stats + bump-aware conservation).
- [x] **Phase 3** — pushed to main with Eduardo's explicit yes (8217398..57a6c37, 8 commits, 35 files).
- [x] **Phase 4** — ARMED same day on Eduardo's "arm it globally": `install.sh --global` wired 3 hook groups in `~/.claude/settings.json` (SessionStart matcher `startup|clear|compact`, PreToolUse:Bash guard, UserPromptSubmit recall; backup `settings.json.bak-2026-07-03`; idempotency re-run = 0 new groups; JSON validated). The recall hook fired IN the upgrade session itself minutes after arming (dog food, live).
- [x] **Phase 5** — instinct.py → ledger routing INSTALLED (fail-open, compile-verified; proves itself at the next real graduation); cockpit line added. **All three live-fire probes PASS (post-arming, zero WhatsApp messages):** (1) fresh headless `claude -p` quotes CORE directive 2 verbatim + fire-log entry; (2) **guard deny BINDS under `--dangerously-skip-permissions`** — the undocumented question answered empirically; the WhatsApp yolo brain's zero-guardrails hole is CLOSED; (3) real proxy round-trip (curl :8788) — the Hermes brain quotes directive 5, fire-log `cwd=/home/mesmer`, proxy journal `turn ok`.
- [x] **Phase 6** — harness built + smoke-verified, full suite complete → `docs/eval/results-2026-07-03.md`. **Result: the brain lifts BOTH models, concentrated in verification-behavior (Haiku +0.62, Opus 4.8 +0.75 mean; +3 single-task jumps on the box-specific scars T02/T03). Brain-Opus reaches 5.00/4.75/4.88 — at the rubric ceiling.** Four negative cells reported as measured (small style tax on already-easy tasks). Famous scars ceiling natively on modern models; the ledger's unique value = non-famous, project/box/owner-specific knowledge.
- [x] **Phase 7** — budgets verified: repo sessions ~3,009 tok (was 4,816, −38%, playbook included); global loader ~1,260 tok. Budget tool caught a real bug (new scripts lacked +x; the [ -x ]-guarded reconcile would have silently never run) — fixed + scar captured. First real playbook counter bumps applied (P001/P003/P007/P012 helpful:1).

## Key decisions
- Global scripts live in `~/.claude/cogito/bin/` (installer-copied, VERSION-stamped; deliberate updates only — supply-chain posture).
- Kill-switches: `COGITO_GLOBAL=0` env or `~/.claude/cogito/DISABLED` file — instant global rollback, also the eval's control-arm isolation.
- Batch-score + counter edits ride converge (local path); the PR gate keeps HOLDing edits — correct by design.
- Playbook delta discipline (ACE): append new bullets, bump counters in place, never rewrite wholesale.
