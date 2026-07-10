# Cogito — Playbook Archive (demoted / merged strategy bullets)

Bullets a consolidation pass demoted (harmful > helpful) or merged into a
stronger strategy. Moved here verbatim, never deleted — same conservation rule
as LESSONS-ARCHIVE.md. The loaders read only PLAYBOOK.md.

## Archived bullets

### 2026-07-07 — moved to the lessons ledger (project/dated one-offs)
> P014 absorbed into LESSONS.md ledger rule '[#deploy][#proj:cogstack] cogstack prod deploys'; P015 absorbed into LESSONS.md ledger rule '[#memory][#verify] Status notes and mtimes go stale'. Raw bullets verbatim:

- [P014][#process][helpful:2][harmful:0] Vercel deploy from cogstack: no global CLI needed — auth persists in ~/.local/share/com.vercel.cli/auth.json, so 'npx -y vercel@latest deploy --prod --yes' from the linked repo deploys and aliases production; verify with logged-out curl + content grep. {via:learn 2026-07-03}
- [P015][#process][helpful:0][harmful:0] Audit memory notes for stale status in one pass: grep all notes for status-bearing lines (https?://, live/armed/running/removed/deploy/port/\.py/~/projects), then batch-verify — logged-out curl for HTTP code+title on each URL, and existence/port/removal checks on disk — reconcile each claim, fix only the ones that fail. 2026-07-04: 30 notes, only 1 stale (the cogito arm-status), all live URLs 200. {via:learn 2026-07-04}

### 2026-07-07 — tightened in place (ids live on in PLAYBOOK.md; originals verbatim)
> P016/P017/P020 exceeded the ~400-char bullet budget (loader top-3 section is capped at 900 chars). Same strategy, fewer bytes.

- [P016][#process][helpful:0][harmful:0] Proactive WhatsApp push to Eduardo = mirror the existing hermes-*-reminder pattern: a script importing send.py (POSTs to the local bridge 127.0.0.1:3000/send) + a systemd USER service/timer pair (Type=oneshot, OnCalendar=<date>, Persistent=true), enable --now, verify with 'systemctl --user list-timers'. Scheduling is systemd timers, NOT cron (crond isn't running). Verify the script with a --dry flag so you don't spam a live test. {via:learn 2026-07-04}
- [P017][#process][helpful:0][harmful:0] Web 'eyes' + audit on the 2.78GB Chromebook = local, no heavy install: see_site.sh screenshots any URL via the pre-installed /usr/bin/chromium (--headless=new --disable-dev-shm-usage --virtual-time-budget, desktop+mobile window-size), then Read the PNG to actually see it; site_audit.py (stdlib-only) fetches raw HTML for modernness/security/staleness signals. They are COMPLEMENTARY — auditor misses visual/layout breakage (e.g. Broad River scored 90 on markup but overflowed on mobile), so always cross-check pixels. Wire a keyed MCP (Firecrawl) without printing the secret: claude mcp add <name> -- bash -lc 'set -a; . $HOME/.hermes/.env.keys; exec npx -y <server>', then verify the KEY works with a direct curl (HTTP 200), not just 'Connected'. {via:learn 2026-07-04}
- [P020][#process][helpful:0][harmful:0] When dispatching a long Claude Code (claude -p) job from a Hermes/WhatsApp turn, launch it fully detached: setsid nohup /full/path/claude -p ... > /tmp/log 2>&1 & — a plain harness background child gets KILLED when the per-turn session cycles between messages (observed: first job left 'no completion record'); detached survives to completion and you poll the logfile next turn. Gauge progress via project file mtimes/greps, NOT the log — claude -p buffers and the logfile stays 0 bytes until the final report dumps at the end. {via:learn 2026-07-06}

### 2026-07-07 — canon/installed id collision at superset merge
> Both copies appended independently: canon's P013/P014 collided with installed P013/P014. Canon strategies re-appended as P024/P025 (P025 tightened). Canon raw bullets verbatim:

- [P013][#verify][helpful:0][harmful:0] when evaluating scaffolding/context lifts, expect modern models to ceiling the FAMOUS failure modes natively — discrimination lives in project-, machine-, and owner-specific scenarios no training data carries {via:learn 2026-07-03}
- [P014][#process][helpful:0][harmful:0] For a substantial multi-requirement build: convene the council for the design (diverse lenses + verify the load-bearing grounded claims), then build in verifiable SLICES each committed to a FEATURE branch (never main), proving each slice by a real outcome before the next. 2026-07-04: 5-slice Job B project-memory system landed on cogito/job-b-progress, main untouched throughout; the incremental verify caught a mawk/gawk bug and a ledger drift mid-build that a big-bang commit would have buried. {via:learn 2026-07-04}
