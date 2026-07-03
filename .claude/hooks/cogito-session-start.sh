#!/usr/bin/env bash
# Cogito SessionStart hook.
# Bootstraps the protocol skill from the CANONICAL ref (origin/main — the durable
# source of truth, NOT the checked-out session branch), guarantees the lessons
# ledger exists, then injects the operating context. Idempotent, fast, non-interactive.
# Runs in every session (remote or local) so Cogito is always live.
set -euo pipefail

REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILL_DST="$CLAUDE_HOME/skills/cogito-protocol"
LEDGER="$SKILL_DST/LESSONS.md"
BRAIN_REF="${COGITO_BRAIN_REF:-origin/main}"   # the ONE canonical brain — NEVER the checked-out branch

mkdir -p "$SKILL_DST"

# Attribute commits made in THIS repo to the owner's GitHub account. GitHub links a
# commit to an account by its no-reply email; the old faceless
# "cogito@users.noreply.github.com" happened to match an UNRELATED real account
# (whoever owns the username "cogito"), so every commit was miscredited to a stranger.
# Web containers are ephemeral, so set it each session. Scoped to the Cogito repo by
# its remote, so other projects in other sessions are never touched.
if git -C "$REPO" remote -v 2>/dev/null | grep -qiE 'COGITO-SUM-cloude/COGITO(\.git)?'; then
  git -C "$REPO" config user.name  "Cogito" 2>/dev/null || true
  git -C "$REPO" config user.email "291881939+COGITO-SUM-cloude@users.noreply.github.com" 2>/dev/null || true
fi

# Load the brain from a single fixed point (origin/main), not the branch this
# container happened to check out — otherwise each session reads a different
# branch's memory and they silently diverge (the cross-session consistency bug).
# Fetch is best-effort; canon_read falls back to the working tree offline so a
# fetch failure never blanks the brain (the safety net). Always returns 0.
git -C "$REPO" fetch --quiet origin main 2>/dev/null || true
canon_read() { git -C "$REPO" show "$BRAIN_REF:$1" 2>/dev/null || cat "$REPO/$1" 2>/dev/null || true; }

# Re-install protocol files every session from the canonical ref (the container may
# revert skill edits, but origin/main is durable) — EXCEPT when the installed copy
# has local-only lines canonical lacks: then back up + warn instead of overwriting
# (the I:8 two-copy scar: never blind-copy between brain copies; merge to the
# superset first). Fail-open: a check error leaves both copies alone.
install_guarded() {  # $1 = repo-relative source path, $2 = destination file
  local content stray
  content="$(canon_read "$1")"
  [ -n "$content" ] || return 0
  if [ -f "$2" ]; then
    stray="$(printf '%s\n' "$content" | grep -vxF -f /dev/stdin "$2" 2>/dev/null | grep -c . || true)"
  else
    stray=0
  fi
  if [ "${stray:-0}" -gt 0 ]; then
    cp -f "$2" "$2.diverged-$(date +%F)" 2>/dev/null || true
    echo "cogito: WARNING — $(basename "$2") has ${stray} local line(s) not in canonical; NOT overwritten. Superset-merge needed (the I:8 two-copy scar). Backup: $2.diverged-$(date +%F)"
  else
    printf '%s\n' "$content" > "$2"
  fi
}
install_guarded skills/cogito-protocol/SKILL.md       "$SKILL_DST/SKILL.md"
install_guarded skills/cogito-protocol/COGITO-CORE.md "$SKILL_DST/COGITO-CORE.md"
mkdir -p "$SKILL_DST/references" 2>/dev/null || true
install_guarded skills/cogito-protocol/references/ecommerce-solo-2026.md "$SKILL_DST/references/ecommerce-solo-2026.md"
if [ ! -f "$LEDGER" ]; then
  lessons_md="$(canon_read skills/cogito-protocol/LESSONS.md)"
  if [ -n "$lessons_md" ]; then
    printf '%s\n' "$lessons_md" > "$LEDGER"
  else
    printf '# Cogito — Lessons Ledger\n\nSYMPTOM -> ROOT CAUSE -> RULE\n\n## Lessons\n' > "$LEDGER"
  fi
fi

# Merge any global write-queues into canon (lessons/strategies captured by
# cogito-learn.sh in OTHER directories since the last cogito session). Fail-open;
# converge carries the merged brain to main at Stop.
RECONCILE="$REPO/scripts/cogito-reconcile.sh"
if [ -x "$RECONCILE" ]; then "$RECONCILE" 2>/dev/null || true; fi

# Inject operating context (SessionStart stdout is added to the session).
cat <<'CTX'
Cogito protocol is active for this session.
Apply the cogito-protocol skill proportionally — near-silent on trivial tasks,
the full ritual on substantial or multi-session work. Run the session loop:
greet ("Cogito is live — what's our mission today?"), interview to a one-page
spec, red-team the goal, build in verifiable increments, capture lessons the
moment they happen (SYMPTOM -> ROOT CAUSE -> RULE), and close with a checkpoint
+ finish-line review, then ask whether the mission is accomplished.
Durable lessons ledger: ~/.claude/skills/cogito-protocol/LESSONS.md
CTX

# Surface the active mission from the canonical ref for instant cross-session
# resume — the SAME mission for every session, not whatever this branch holds.
mission="$(canon_read docs/ACTIVE-MISSION.md)"
if [ -n "$mission" ]; then
  printf '\n----- ACTIVE MISSION (resume this) -----\n'
  printf '%s\n' "$mission" | head -c 6000
  if [ "${#mission}" -gt 6000 ]; then
    printf '\n[TRUNCATED at 6000 chars — ACTIVE-MISSION.md is over budget; compact it into checkpoints (protocol §3)]\n'
  fi
  printf '\n----- end ACTIVE MISSION -----\n'
fi

# Surface the most-overdue learning recap (spaced repetition — skill #7). NEVER
# fatal: the learning log is the human-growth twin of the lessons ledger, but a
# missing/malformed log or script must never disturb the lesson-load path. The
# command substitution swallows errors and the if-guard keeps set -e happy.
REVIEW="$REPO/scripts/cogito-review.sh"
if [ -x "$REVIEW" ]; then
  recap="$("$REVIEW" due --quiet 2>/dev/null || true)"
  if [ -n "$recap" ]; then
    printf '\n----- LEARNING RECAP (spaced repetition — most overdue) -----\n'
    printf '%s\n' "$recap"
    printf 'Open with this recap cue; after they answer: scripts/cogito-review.sh grade <N> pass|fail\n'
    printf -- '----- end LEARNING RECAP -----\n'
  fi
fi
