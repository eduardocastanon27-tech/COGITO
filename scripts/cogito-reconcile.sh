#!/usr/bin/env bash
# cogito-reconcile — merge the global write-queues into canon. Runs at the START
# of a COGITO-repo session (called by cogito-session-start.sh); the converge Stop
# hook then carries the merged brain to main.
#
# Queues (written by cogito-learn.sh from any non-cogito directory):
#   ~/.claude/cogito-pending-lessons.md    scar lines   -> drained via cogito-drain.sh
#   ~/.claude/cogito-pending-playbook.md   new bullets  -> appended (dedupe by text,
#                                                          id reassigned to next free)
#   ~/.claude/cogito-pending-bumps.txt     P###:helpful -> counters bumped in canon
#
# Superset rule (the I:8 two-copy scar): everything merges by CONTENT dedupe —
# nothing is ever copied over, nothing dropped; processed queues are archived to
# *.done-<date>, never deleted. Fail-open: any error leaves queues in place.
set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || exit 0
PP="$ROOT/skills/cogito-protocol/PLAYBOOK.md"
Q_LESSONS="$HOME/.claude/cogito-pending-lessons.md"
Q_PLAYBOOK="$HOME/.claude/cogito-pending-playbook.md"
Q_BUMPS="$HOME/.claude/cogito-pending-bumps.txt"
STAMP="$(date +%F)"

archive_queue() { # $1 = queue file
  mv "$1" "$1.done-$STAMP" 2>/dev/null || true
}

# 1. Lessons: reuse the drain courier (dedupe vs ledger+archive). INSTALLED is
#    pointed at /dev/null because cogito-learn already mirrored these lines into
#    the runtime ledger — deduping against it would drop every queued lesson.
if [ -s "$Q_LESSONS" ]; then
  if COGITO_INSTALLED_LEDGER=/dev/null bash "$ROOT/scripts/cogito-drain.sh" drain "$Q_LESSONS" >/dev/null 2>&1 \
     && COGITO_INSTALLED_LEDGER=/dev/null bash "$ROOT/scripts/cogito-drain.sh" accept-all >/dev/null 2>&1; then
    n="$(grep -c '^- ' "$Q_LESSONS" 2>/dev/null || echo 0)"
    archive_queue "$Q_LESSONS"
    echo "cogito-reconcile: merged $n queued lesson(s) into canon (dedupe applied)."
  else
    echo "cogito-reconcile: WARNING lesson-queue drain failed — queue left in place ($Q_LESSONS)." >&2
  fi
fi

# 2. Playbook bullets: dedupe by TEXT (id+counters stripped), append with the
#    next free canon id.
if [ -s "$Q_PLAYBOOK" ] && [ -f "$PP" ]; then
  if python3 - "$PP" "$Q_PLAYBOOK" <<'PY'
import sys, re
pp, q = sys.argv[1], sys.argv[2]
strip = lambda s: re.sub(r'\[P[0-9]{3}\]|\[helpful:[0-9]+\]|\[harmful:[0-9]+\]', '', s).strip()
canon = open(pp, encoding='utf-8').read()
have = {strip(l) for l in canon.split('\n') if l.startswith('- [P')}
ids = [int(m) for m in re.findall(r'^- \[P([0-9]{3})\]', canon, re.M)]
nxt = max(ids or [0]) + 1
added = []
for l in open(q, encoding='utf-8'):
    l = l.rstrip('\n')
    if not l.startswith('- [P') or strip(l) in have:
        continue
    nl = re.sub(r'^- \[P[0-9]{3}\]', '- [P%03d]' % nxt, l, count=1)
    added.append(nl); have.add(strip(l)); nxt += 1
if added:
    with open(pp, 'a', encoding='utf-8') as f:
        f.write('\n'.join(added) + '\n')
print("merged %d queued strategy bullet(s)" % len(added))
PY
  then
    archive_queue "$Q_PLAYBOOK"
    echo "cogito-reconcile: playbook queue merged into canon."
  else
    echo "cogito-reconcile: WARNING playbook-queue merge failed — queue left in place." >&2
  fi
fi

# 3. Counter bumps: apply each P###:helpful|harmful to canon. Ids can drift
#    between runtime and canon (reconcile reassigns) — a bump whose id/text no
#    longer matches is skipped with a note, never fatal.
if [ -s "$Q_BUMPS" ] && [ -f "$PP" ]; then
  ok=0; skip=0
  while IFS= read -r spec; do
    [ -z "${spec// /}" ] && continue
    if python3 - "$PP" "$spec" <<'PY' >/dev/null 2>&1
import sys, re
f, spec = sys.argv[1], sys.argv[2]
pid, kind = spec.split(':', 1)
src = open(f, encoding='utf-8').read()
pat = re.compile(r'(^- \[' + re.escape(pid) + r'\].*\[' + kind + r':)(\d+)(\])', re.M)
new, c = pat.subn(lambda m: m.group(1) + str(int(m.group(2)) + 1) + m.group(3), src, count=1)
sys.exit(0 if c and (open(f, 'w', encoding='utf-8').write(new) or True) else 1)
PY
    then ok=$((ok+1)); else skip=$((skip+1)); fi
  done < "$Q_BUMPS"
  archive_queue "$Q_BUMPS"
  echo "cogito-reconcile: applied $ok counter bump(s) to canon ($skip skipped — id drift)."
fi

exit 0
