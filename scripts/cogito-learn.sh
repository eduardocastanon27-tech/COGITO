#!/usr/bin/env bash
# cogito-learn — record a lesson OR a strategy into the Cogito brain so every
# future session (any repo) inherits it. Usage:
#   cogito-learn.sh "[#tag] [I:n] SYMPTOM -> ROOT CAUSE -> RULE"     scar (ledger)
#   cogito-learn.sh --playbook "[#tag] imperative strategy"          win (playbook)
#   cogito-learn.sh --bump P003:helpful      a loaded bullet helped (or :harmful)
#
#   - In the central Cogito repo -> write the repo brain files (converge publishes).
#   - Elsewhere (ANY other directory) -> write the ~/.claude runtime copies (live
#     for every global session immediately) AND queue for the next COGITO-repo
#     session, whose reconcile step merges queues into canon (dedupe = superset).
#
# SECURITY (council 2026-06-16): the old token -> direct-API-write path is REMOVED.
# No satellite holds a canonical-write token — that is the blocked exfil shape.
set -uo pipefail

OWNER=COGITO-SUM-cloude; REPO=COGITO
LP="skills/cogito-protocol/LESSONS.md"
PP="skills/cogito-protocol/PLAYBOOK.md"
RT="$HOME/.claude/skills/cogito-protocol"
Q_LESSONS="$HOME/.claude/cogito-pending-lessons.md"
Q_PLAYBOOK="$HOME/.claude/cogito-pending-playbook.md"
Q_BUMPS="$HOME/.claude/cogito-pending-bumps.txt"

usage() {
  echo 'usage: cogito-learn.sh "SYMPTOM -> ROOT CAUSE -> RULE" | --playbook "strategy" | --bump P###:helpful|harmful' >&2
  exit 2
}

MODE=lesson
case "${1:-}" in
  --playbook) MODE=playbook; shift ;;
  --bump)     MODE=bump; shift ;;
esac
ARG="${*:-}"
[ -n "${ARG// /}" ] || usage

# Auto-enrich a lesson with the CURRENT project's sector tag, so a scar captured
# while working a web (or game/toy/...) project compounds for that KIND of work
# with zero extra effort. This ENRICHES a model-initiated write; it is NOT a new
# auto-write trigger. Skipped if the lesson already carries a #sector, if the
# project declares no sector, or for --playbook/--bump. Whitelisted to the fixed
# 6, so a garbage declaration adds nothing. herestring (not a pipe) for the -q
# check — grep -q at a pipeline tail SIGPIPEs its feeder under pipefail.
if [ "$MODE" = lesson ] && ! grep -qF '[#sector:' <<<"$ARG"; then
  _sroot="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
  _sec=""
  for _c in "$_sroot/PROGRESS.md" "$_sroot/.claude/PROGRESS.md"; do
    [ -f "$_c" ] || continue
    _sec="$(grep -iE '^\*\*[Ss]ector:\*\*' "$_c" 2>/dev/null | head -1 \
      | sed -E 's/.*[Ss]ector:\*\*[[:space:]]*//' | tr '[:upper:]' '[:lower:]' \
      | grep -oE '^(web|game|toy|tracker|data|infra)' || true)"
    break
  done
  if [ -z "$_sec" ] && [ -f "$HOME/.claude/cogito/sectors.map" ]; then
    _sec="$(grep -iE "^$(basename "$_sroot")=" "$HOME/.claude/cogito/sectors.map" 2>/dev/null \
      | head -1 | cut -d= -f2 | tr '[:upper:]' '[:lower:]' \
      | grep -oE '^(web|game|toy|tracker|data|infra)' || true)"
  fi
  [ -n "$_sec" ] && ARG="[#sector:$_sec] $ARG"
fi

# Person/technical lane guard (Cogito<->native merge): the ledger is FACELESS +
# technical (the critical #comms rule). A lesson that names Eduardo is likely a
# PERSON fact that belongs in the WHO lane, not here — warn and point at the
# person-card, but still record (fail-open, never lose a lesson). herestring, not
# a pipe, for grep -q under pipefail.
if [ "$MODE" = lesson ] && grep -qiF 'eduardo' <<<"$ARG"; then
  echo "cogito-learn: NOTE — this names Eduardo. The ledger is faceless + technical; a PERSON fact belongs in ~/.hermes/person-card.md (the WHO lane). Recording anyway." >&2
fi

# Next free [P###] id in a playbook file (10# guards the octal trap: P012 -> 12).
next_pid() {
  local max
  max="$(grep -oE '^- \[P[0-9]{3}\]' "$1" 2>/dev/null | grep -oE '[0-9]{3}' | sort -rn | head -1 || true)"
  printf 'P%03d' "$(( 10#${max:-0} + 1 ))"
}

# Build a playbook bullet from free text: honor a leading [#tag], default #process.
make_bullet() { # $1 = playbook file (for the id), $2 = text
  local text="$2" tag="[#process]"
  if printf '%s' "$text" | grep -qE '^\[#[a-z][a-z-]*\]'; then
    tag="$(printf '%s' "$text" | grep -oE '^\[#[a-z][a-z-]*\]')"
    text="$(printf '%s' "$text" | sed -E 's/^\[#[a-z][a-z-]*\][[:space:]]*//')"
  fi
  printf -- '- [%s]%s[helpful:0][harmful:0] %s {via:learn %s}' "$(next_pid "$1")" "$tag" "$text" "$(date +%F)"
}

# In-place counter bump: P###:helpful|harmful in $1.
bump_counter() { # $1 = playbook file, $2 = spec
  python3 - "$1" "$2" <<'PY'
import sys, re
f, spec = sys.argv[1], sys.argv[2]
try:
    pid, kind = spec.split(':', 1)
except ValueError:
    sys.stderr.write("bump spec must be P###:helpful|harmful\n"); sys.exit(2)
if kind not in ("helpful", "harmful") or not re.fullmatch(r'P[0-9]{3}', pid):
    sys.stderr.write("bump spec must be P###:helpful|harmful\n"); sys.exit(2)
src = open(f, encoding='utf-8').read()
pat = re.compile(r'(^- \[' + re.escape(pid) + r'\].*\[' + kind + r':)(\d+)(\])', re.M)
new, c = pat.subn(lambda m: m.group(1) + str(int(m.group(2)) + 1) + m.group(3), src, count=1)
if not c:
    sys.stderr.write("no bullet %s in %s\n" % (pid, f)); sys.exit(1)
open(f, 'w', encoding='utf-8').write(new)
print("bumped %s %s" % (pid, kind))
PY
}

# Mode 1 — inside the central repo: write the repo brain (converge publishes).
root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$root" ] && [ -f "$root/$LP" ] && git -C "$root" remote -v 2>/dev/null | grep -qiE "$OWNER/$REPO(\.git)?"; then
  case "$MODE" in
    lesson)
      printf -- '- %s\n' "$ARG" >> "$root/$LP"
      echo "cogito-learn: appended to $root/$LP — converge carries it to main." ;;
    playbook)
      make_bullet "$root/$PP" "$ARG" >> "$root/$PP"; echo >> "$root/$PP"
      echo "cogito-learn: strategy appended to $root/$PP." ;;
    bump)
      bump_counter "$root/$PP" "$ARG" ;;
  esac
  exit 0
fi

# Mode 2 (stored-token direct write) REMOVED for security — see header.

# Mode 3 — anywhere else: runtime copy (live now) + queue (canon next cogito session).
mkdir -p "$RT" "$(dirname "$Q_LESSONS")" 2>/dev/null || true
case "$MODE" in
  lesson)
    [ -f "$RT/LESSONS.md" ] && printf -- '- %s\n' "$ARG" >> "$RT/LESSONS.md"
    printf -- '- %s\n' "$ARG" >> "$Q_LESSONS"
    echo "cogito-learn: live in the runtime ledger + queued for canon ($Q_LESSONS)." ;;
  playbook)
    if [ -f "$RT/PLAYBOOK.md" ]; then
      b="$(make_bullet "$RT/PLAYBOOK.md" "$ARG")"
      printf '%s\n' "$b" >> "$RT/PLAYBOOK.md"
    else
      b="$(make_bullet "$Q_PLAYBOOK" "$ARG")"
    fi
    printf '%s\n' "$b" >> "$Q_PLAYBOOK"
    echo "cogito-learn: strategy live in the runtime playbook + queued for canon ($Q_PLAYBOOK)." ;;
  bump)
    [ -f "$RT/PLAYBOOK.md" ] && bump_counter "$RT/PLAYBOOK.md" "$ARG" 2>/dev/null || true
    printf '%s\n' "$ARG" >> "$Q_BUMPS"
    echo "cogito-learn: bump applied to the runtime playbook + queued for canon ($Q_BUMPS)." ;;
esac
exit 0
