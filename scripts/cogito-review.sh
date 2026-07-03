#!/usr/bin/env bash
# Cogito spaced-repetition review for the LEARNING LOG (docs/learning/log.md) — the
# human-growth twin of the lessons ledger. Schedules WHEN to revisit each lesson so the
# spacing + testing effects fire, instead of hoping we remember to recap.
#
# Scheduler: a plain Leitner ladder (box 1..6 -> intervals 1/3/7/16/35/90 days).
# pass -> up one box; fail -> back to box 1. That's the whole model — human-auditable
# at a glance, no floating-point memory state an agent can silently corrupt.
# (The earlier FSRS-5 version was over-engineering for a handful of lessons — exactly
# what the upgrade roadmap #7 ruled: "Leitner is the right altitude; full FSRS needs a
# review-history dataset." It never recorded a single grade. Downgraded 2026-07-03.)
#
# Backward compatible: legacy `S=/D=` (FSRS) state is mapped onto the nearest box the
# next time that lesson is graded. `box:0` = seeded (not yet in rotation).
#
#   cogito-review.sh due [--quiet]      the most-overdue lesson's recap cue (--quiet
#                                       prints just the cue, for the SessionStart hook)
#   cogito-review.sh list               every lesson with box / due / overdue
#   cogito-review.sh grade N <result>   record a recall. result = pass|fail (aliases
#                                       accepted: good/easy=pass, again/hard=fail).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOG="$ROOT/docs/learning/log.md"
[ -f "$LOG" ] || { echo "cogito-review: no learning log at $LOG" >&2; exit 1; }

exec python3 - "$LOG" "$@" <<'PY'
import sys, re, datetime
LOG = sys.argv[1]
args = sys.argv[2:]
cmd = args[0] if args else 'due'
today = datetime.date.today()

BOX_INTERVAL = {1: 1, 2: 3, 3: 7, 4: 16, 5: 35, 6: 90}
PASS = {'pass', 'good', 'easy'}
FAIL = {'fail', 'again', 'hard'}

def s_to_box(S):
    # legacy FSRS stability (days) -> nearest Leitner box
    for box, iv in ((1, 2), (2, 5), (3, 12), (4, 25), (5, 60)):
        if S <= iv: return box
    return 6

def parse(text):
    lines = text.split('\n')
    heads = [i for i, l in enumerate(lines) if re.match(r'## Lesson \d+', l)]
    out = []
    for k, start in enumerate(heads):
        end = heads[k + 1] if k + 1 < len(heads) else len(lines)
        block = '\n'.join(lines[start:end])
        m = re.match(r'## Lesson (\d+) — (.*)', lines[start])
        bm   = re.search(r'box:(\d+)', block)
        sm   = re.search(r'\bS=([\d.]+)', block)
        duem = re.search(r'due:(\d{4}-\d{2}-\d{2})', block)
        cm = re.search(r'\*\*Recap cue[^:]*:\*\*\s*(.+?)(?=\n\s*- \*\*|\n## |\Z)', block, re.DOTALL)
        cue = re.sub(r'\s+', ' ', cm.group(1)).strip() if cm else '(no recap cue)'
        box = int(bm.group(1)) if bm else (s_to_box(float(sm.group(1))) if sm else 0)
        due = duem.group(1) if duem else None
        out.append(dict(num=int(m.group(1)), title=m.group(2).strip(), box=box,
                        due=due, in_rot=box >= 1, cue=cue, start=start, end=end))
    return lines, out

lines, lessons = parse(open(LOG).read())

def overdue(l):
    if not l['in_rot'] or not l['due']:
        return None
    return (today - datetime.date.fromisoformat(l['due'])).days

if cmd == 'due':
    quiet = '--quiet' in args
    due_items = sorted(((overdue(l), l) for l in lessons
                        if overdue(l) is not None and overdue(l) >= 0), key=lambda x: -x[0])
    if not due_items:
        if not quiet: print("Nothing due for review.")
        sys.exit(0)
    od, l = due_items[0]
    if quiet:
        print(f"Lesson {l['num']} — {l['title']}")
        print(l['cue'])
    else:
        print(f"Most overdue: Lesson {l['num']} — {l['title']}  (due {l['due']}, {od}d overdue)")
        print(f"  Recap cue: {l['cue']}")
        print(f"  After recapping, record it:  scripts/cogito-review.sh grade {l['num']} pass|fail")
        if len(due_items) > 1:
            print(f"  (+{len(due_items)-1} more due)")
    sys.exit(0)

if cmd == 'list':
    for l in lessons:
        od = overdue(l)
        if not l['in_rot']:  st = 'seeded'
        elif od is None:     st = 'no due'
        elif od >= 0:        st = f'{od}d overdue'
        else:                st = f'in {-od}d'
        due = ('due:' + l['due']) if l['due'] else 'due:—'
        print(f"  L{l['num']}  box:{l['box']:<9}{due:<16}[{st}]  {l['title']}")
    sys.exit(0)

if cmd == 'grade':
    if len(args) < 3:
        sys.stderr.write('usage: cogito-review.sh grade <lesson-number> <pass|fail>\n'); sys.exit(2)
    try:
        num = int(args[1])
    except ValueError:
        sys.stderr.write('lesson number must be an integer\n'); sys.exit(2)
    result = args[2].lower()
    if result not in PASS | FAIL:
        sys.stderr.write("result must be pass|fail (aliases: good/easy, again/hard)\n"); sys.exit(2)
    t = next((l for l in lessons if l['num'] == num), None)
    if not t:
        sys.stderr.write(f"no Lesson {num} in the log\n"); sys.exit(1)
    oldbox = t['box']
    newbox = min(oldbox + 1, 6) if result in PASS else 1
    if oldbox == 0 and result in FAIL: newbox = 1        # first-ever review always enters box 1
    iv = BOX_INTERVAL[newbox]
    newdue = today + datetime.timedelta(days=iv)
    newline = f"- **Review:** box:{newbox} due:{newdue.isoformat()} rev:{today.isoformat()}"
    rev_i = next((i for i in range(t['start'], t['end'])
                  if re.match(r'\s*- \*\*Review:\*\*', lines[i])), None)
    if rev_i is not None: lines[rev_i] = newline
    else:                 lines.insert(t['end'] - 1, newline)
    open(LOG, 'w').write('\n'.join(lines))
    print(f"Lesson {num}: {result} -> box {oldbox}->{newbox}, next due {newdue.isoformat()} (in {iv}d)")
    sys.exit(0)

sys.stderr.write(f"unknown command: {cmd}\nusage: cogito-review.sh {{due [--quiet] | list | grade N <result>}}\n")
sys.exit(2)
PY
