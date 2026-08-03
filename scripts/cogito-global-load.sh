#!/usr/bin/env bash
# Cogito GLOBAL loader — SessionStart hook for EVERY session on this machine
# (wired in ~/.claude/settings.json by install.sh --global, matcher
# "startup|clear|compact" — NEVER "resume": the Hermes proxy resumes per
# WhatsApp turn and re-injection would churn context + break the prompt cache).
#
# Lean by contract:
#   - reads ONLY the ~/.claude runtime copies (freshness comes from COGITO-repo
#     sessions syncing canon); NEVER touches the network (print-mode hooks have a
#     30s timeout and this box has ~750MiB free RAM)
#   - defers inside the COGITO repo (the project hooks own loading there)
#   - every section is line-boundary capped; total ≈ 5.5k chars ≈ 1.4k tokens
#   - fail-open everywhere: a broken brain file must never break a session
# Kill switches (instant, no uninstall): COGITO_GLOBAL=0  or  touch ~/.claude/cogito/DISABLED
set -uo pipefail

[ "${COGITO_GLOBAL:-1}" = "0" ] && exit 0
[ -f "$HOME/.claude/cogito/DISABLED" ] && exit 0

# Inside the COGITO repo the project SessionStart hooks load the full brain —
# defer so nothing double-loads.
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
if git -C "$proj" remote -v 2>/dev/null | grep -qiE 'COGITO-SUM-cloude/COGITO(\.git)?'; then
  exit 0
fi

D="$HOME/.claude/skills/cogito-protocol"
L="$D/LESSONS.md"
P="$D/PLAYBOOK.md"

# Fire log — proof the hook fired (checked manually / by audits; nothing polls it).
mkdir -p "$HOME/.claude/cogito" 2>/dev/null || true
{
  printf '%s cwd=%s\n' "$(date -u +%FT%TZ)" "$PWD" >> "$HOME/.claude/cogito/last-fire.log"
  tail -n 50 "$HOME/.claude/cogito/last-fire.log" > "$HOME/.claude/cogito/.lf.tmp" \
    && mv "$HOME/.claude/cogito/.lf.tmp" "$HOME/.claude/cogito/last-fire.log"
} 2>/dev/null || true

# Cap helper: cut on LINE boundaries at ~N chars (head -c mid-line confuses).
line_cap() { awk -v m="$1" '{n+=length($0)+1; if(n>m) exit; print}'; }

# Budget for the always-loaded lesson set. Raised 2400 -> 3200 on 2026-08-03:
# the council-approved [#always] set is 2173B, and the old 2400 left no room for
# the demoted-topics pointer or for a 9th lesson ever being promoted. Keep this
# TIGHT — every byte here rides every turn of every session.
CRIT_CAP=3200

# 1. The operating directives — the weak-model payload.
if [ -f "$D/COGITO-CORE.md" ]; then
  head -c 2400 "$D/COGITO-CORE.md" 2>/dev/null || true
  echo
  core_sz=$(wc -c < "$D/COGITO-CORE.md" 2>/dev/null || echo 0)
  [ "$core_sz" -gt 2400 ] && echo "(!! COGITO-CORE.md ${core_sz}B > 2400B cap — tail truncated mid-rule; trim the file)"
fi

# 2. Critical lessons, most severe first ([#critical] TAG match, not the bare
#    word — a lesson merely mentioning it must not always-load).
if [ -f "$L" ]; then
  echo "----- COGITO: critical lessons (never repeat these) -----"
  # Always-load is an EXPLICIT flag ([#always]), decoupled from the [I:] severity
  # digit. Selecting on [I:9-10] conflated "severe" with "must ride every turn":
  # 12 of 14 lessons sat at I:9-10, so the cap was decided by sort's arbitrary
  # full-line tiebreak — on 2026-08-03 that loaded 4 of 14, spending 42% of the
  # budget on a web-only CSS lesson while every boundary rule was cut.
  # Fallback to the old selector if no lesson is flagged yet, so an un-migrated
  # ledger degrades to the previous behaviour rather than loading nothing.
  crit="$(grep -E '^- .*\[#always\]' "$L" 2>/dev/null || true)"
  if [ -z "$crit" ]; then
    crit="$(grep -E '^- .*(\[I:(9|10)\]|\[#critical\])' "$L" 2>/dev/null \
      | sed -n 's/.*\[I:\([0-9]*\)\].*/\1 &/p' | sort -rn | cut -d' ' -f2- || true)"
  fi
  printf '%s\n' "$crit" | line_cap "$CRIT_CAP" || true
  # Contract: ALL flagged lessons load. Warn on overflow instead of truncating silently.
  crit_total=$(printf '%s' "$crit" | wc -c)
  crit_shown=$(printf '%s\n' "$crit" | line_cap "$CRIT_CAP" | wc -c)
  if [ "$crit_total" -gt "$crit_shown" ]; then
    echo "(!! always-set ${crit_total}B exceeds ${crit_shown}B cap — some NOT loaded; run cogito-consolidate or demote one)"
  fi
  # Demoted-but-severe lessons are grep-retrievable only. A pointer is what makes
  # "demoted" mean retrievable instead of deleted (council 2026-08-03).
  demoted="$(grep -cE '^- .*(\[#critical\]|\[I:(9|10)\])' "$L" 2>/dev/null | grep -v '^0$' || true)"
  [ -n "$demoted" ] && echo "  (+ severe but situational — grep $L: systemd/child-process death, checker-poisoning, tailwind-v4 cascade, autobuild self-signal, timeout-invariant, brain-copy sync)"
  echo "----- COGITO tag index (grep a [#tag] in $L for depth) -----"
  grep '^- ' "$L" 2>/dev/null | grep -oE '\[#[a-z][a-z-]*\]' | sort | uniq -c | sort -rn \
    | head -12 | sed 's/^/  /' || true
fi

# 3. Top strategies (ACE playbook) by proven usefulness.
if [ -f "$P" ] && grep -q '^- \[P' "$P" 2>/dev/null; then
  echo "----- COGITO: top strategies (APPLY these; report use: cogito-learn.sh --bump P###:helpful) -----"
  grep '^- \[P' "$P" 2>/dev/null | sed -n 's/.*\[helpful:\([0-9]*\)\].*/\1 &/p' \
    | sort -rn | head -3 | cut -d' ' -f2- | line_cap 900 || true
fi

echo "Cogito global brain loaded (lean mode). Write-back from ANY session:"
echo "  ~/.claude/cogito/bin/cogito-learn.sh \"[#tag] [I:n] SYMPTOM -> ROOT CAUSE -> RULE\"   (--playbook / --bump P###:helpful)"

# 4. Project progress (Job B) — the per-project "where are we / what's left"
#    state. Loaded ONLY when the current repo carries a PROGRESS.md, so it is
#    lazy by construction: no file => silent, no portfolio dump, no guessing
#    which project (the cwd IS the answer). Distinct from the lessons brain
#    above; lives in the project's OWN repo, never in Cogito's. Repo-root
#    resolved via git so it works from any subdirectory; falls back to cwd.
root="$(git -C "$proj" rev-parse --show-toplevel 2>/dev/null)"
[ -n "$root" ] || root="$proj"
progress=""
for cand in "$root/PROGRESS.md" "$root/.claude/PROGRESS.md"; do
  [ -f "$cand" ] && { progress="$cand"; break; }
done
if [ -n "$progress" ]; then
  echo
  echo "----- COGITO project state: $(basename "$root") (source: ${progress#"$HOME"/}) -----"
  line_cap 6000 < "$progress" 2>/dev/null || true
  echo "----- (this is the project's own PROGRESS.md — edit it to update; it rides the project repo) -----"
fi

# 4b. Sector playbook — the "pull the domain knowledge on open" step. Resolve the
#     project's SECTOR from its PROGRESS.md **Sector:** line if it has one, ELSE
#     from the ~/.claude/cogito/sectors.map registry (keyed on the repo dir name) —
#     so it fires even for a project with no PROGRESS.md. Load that sector's curated
#     top rules so work of this KIND starts on the shoulders of every prior project.
#     Whitelisted to the fixed 6 (a garbage value can never point at an arbitrary
#     file); silent when nothing matches; sits BELOW the always-on critical/core
#     blocks so it can never disturb them. $root is resolved above regardless of
#     PROGRESS.md; at ~ / a non-project dir the basename won't be in the map -> lean.
sector=""
[ -n "$progress" ] && sector="$(grep -iE '^\*\*[Ss]ector:\*\*' "$progress" 2>/dev/null | head -1 \
  | sed -E 's/.*[Ss]ector:\*\*[[:space:]]*//' | tr '[:upper:]' '[:lower:]' \
  | grep -oE '^(web|game|toy|tracker|data|infra)' || true)"
if [ -z "$sector" ] && [ -f "$HOME/.claude/cogito/sectors.map" ]; then
  sector="$(grep -iE "^$(basename "$root")=" "$HOME/.claude/cogito/sectors.map" 2>/dev/null \
    | head -1 | cut -d= -f2 | tr '[:upper:]' '[:lower:]' \
    | grep -oE '^(web|game|toy|tracker|data|infra)' || true)"
fi
spf="$D/sectors/$sector.md"
if [ -n "$sector" ] && [ -f "$spf" ]; then
  echo
  echo "----- COGITO sector playbook: $sector (apply these to THIS kind of work) -----"
  line_cap 1200 < "$spf" 2>/dev/null || true
fi

# (Removed 2026-07-07 audit: hermes-brain.txt pre-render — grep found zero
#  consumers; re-add only when proxy-side injection is actually wired.)

# 5. (Removed 2026-07-24: spaced-repetition recap no longer injected into
#    dev/Hermes sessions — learner spaced-rep is now owned by the Hermes tutor
#    (cogito-teacher/cogito-review.sh still drives it on the learner path).)

exit 0
