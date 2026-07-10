#!/usr/bin/env bash
# Cogito UserPromptSubmit hook — just-in-time lesson retrieval.
#
# On every user prompt, surface the 1-3 lessons most relevant to THIS prompt so
# the right past lesson lands in context exactly when it matters — instead of
# carrying the whole ledger every turn (the context-tax win) or relying on the
# model to remember to grep. The always-loaded #critical/severe set already rides
# each turn; this pulls the RELEVANT deferred ones on demand. No embeddings — plain
# keyword overlap over a tiny markdown file.
#
# Project scope (slice 4): a lesson may be tagged [#proj:<slug>] when it is
# SPECIFIC to one project (its vendor/route/store names, e.g. cogstack's deploy
# method). Such a lesson is surfaced only when you are working IN that project;
# from a DIFFERENT project it is suppressed, so paint's specifics never mislead a
# storescript session. Generic (untagged) lessons cross-pull freely by keyword —
# that is how a new website still gets the reusable website lessons from the paint
# build. <slug> = the project's git-repo directory name, lowercased.
#
# Reads the prompt from stdin JSON (.prompt); a UserPromptSubmit hook's stdout is
# added to the session context. Non-fatal, fail-quiet: any problem -> no output,
# the prompt proceeds normally.
#   Disable:  export COGITO_RECALL=0
set -uo pipefail

[ "${COGITO_RECALL:-1}" = "0" ] && exit 0
[ "${COGITO_GLOBAL:-1}" = "0" ] && exit 0
[ -f "$HOME/.claude/cogito/DISABLED" ] && exit 0

# Ledger resolution: explicit override -> repo copy -> ~/.claude runtime copy.
# The runtime fallback is what makes recall fire in ANY directory, not just the
# cogito repo (it silently no-op'd everywhere else before 2026-07-03).
REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
LEDGER="${COGITO_LEDGER:-}"
[ -z "$LEDGER" ] && [ -f "$REPO/skills/cogito-protocol/LESSONS.md" ] && LEDGER="$REPO/skills/cogito-protocol/LESSONS.md"
[ -z "$LEDGER" ] && LEDGER="$HOME/.claude/skills/cogito-protocol/LESSONS.md"
[ -f "$LEDGER" ] || exit 0
PLAYBOOK="$(dirname "$LEDGER")/PLAYBOOK.md"

# Current project scope: only a real git repo yields a slug. At ~ or a non-repo,
# PROJ_SLUG stays empty -> no suppression (keyword overlap alone governs).
PROJ_SLUG=""
_ROOT="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$_ROOT" ] && PROJ_SLUG="$(basename "$_ROOT" | tr '[:upper:]' '[:lower:]')"

# Current SECTOR (from the project's PROGRESS.md **Sector:** line, else the
# sectors.map fallback) — recall BOOSTS same-sector lessons so a new web project
# preferentially surfaces web wisdom. Whitelisted to the fixed 6; empty at ~ or
# an undeclared project (then keyword overlap alone governs, unchanged behavior).
CUR_SECTOR=""
_PROOT="${_ROOT:-${CLAUDE_PROJECT_DIR:-$PWD}}"
for _c in "$_PROOT/PROGRESS.md" "$_PROOT/.claude/PROGRESS.md"; do
  [ -f "$_c" ] || continue
  CUR_SECTOR="$(grep -iE '^\*\*[Ss]ector:\*\*' "$_c" 2>/dev/null | head -1 \
    | sed -E 's/.*[Ss]ector:\*\*[[:space:]]*//' | tr '[:upper:]' '[:lower:]' \
    | grep -oE '^(web|game|toy|tracker|data|infra)' || true)"
  break
done
if [ -z "$CUR_SECTOR" ] && [ -f "$HOME/.claude/cogito/sectors.map" ]; then
  CUR_SECTOR="$(grep -iE "^$(basename "$_PROOT")=" "$HOME/.claude/cogito/sectors.map" 2>/dev/null \
    | head -1 | cut -d= -f2 | tr '[:upper:]' '[:lower:]' | grep -oE '^(web|game|toy|tracker|data|infra)' || true)"
fi

input="$(cat 2>/dev/null || true)"
prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)"
[ -z "$prompt" ] && exit 0

MAX="${COGITO_RECALL_MAX:-3}"               # how many lessons to surface
MIN_HITS="${COGITO_RECALL_MIN_HITS:-2}"     # min distinct keyword overlaps to count

# Score each NON-always-loaded lesson + playbook strategy by distinct
# prompt-keyword overlap; surface the top MAX with >= MIN_HITS. One python pass
# over ~100 lines — fast, no deps.
python3 - "$LEDGER" "$prompt" "$MAX" "$MIN_HITS" "$PLAYBOOK" "$PROJ_SLUG" "$CUR_SECTOR" <<'PY' 2>/dev/null || exit 0
import sys, re, os
ledger, prompt, maxn, minhits = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
playbook = sys.argv[5] if len(sys.argv) > 5 else ''
proj_slug = (sys.argv[6] if len(sys.argv) > 6 else '').lower()
cur_sector = (sys.argv[7] if len(sys.argv) > 7 else '').lower()

# Sector membership + importance of a lesson line (for ranking).
SECTOR_RE = re.compile(r"\[#sector:([a-z]+)\]")
IMP_RE    = re.compile(r"\[I:(\d+)\]")
# Strip the PROGRAMMATIC tags (sector/proj) before keyword matching so a
# [#sector:game] tag can't inject a false "game" keyword hit; real lesson TEXT
# (and topical tags) still match normally.
TAGSTRIP  = re.compile(r"\[#(?:sector|proj):[a-z0-9_-]+\]", re.I)

# A lesson tagged [#proj:X] is specific to project X; suppress it when the current
# project is a DIFFERENT one. Untagged lessons are generic and always eligible.
PROJ_RE = re.compile(r"\[#proj:([a-z0-9_-]+)\]", re.I)
def cross_project(line):
    if not proj_slug:
        return False
    tags = [t.lower() for t in PROJ_RE.findall(line)]
    return bool(tags) and proj_slug not in tags

STOP = set("""the a an and or but if then else for to of in on at by is are was were be been being
this that these those with from into as it its their our your his her them they we you i he she
do does did done not no yes can will would should could may might must have has had how what why
when where which who whom whose all any some more most much many few less least very just only
about over under out up down off than too also new use used using make makes made get got need
want like really thing things way ways one two three first next now today day time work working
please help let go going keep list see know learn heard good best update current goal also lets
me my we our us still here there back take give given thing done fix fixed make build built""".split())

def toks(s):
    s = TAGSTRIP.sub("", s)
    return {w for w in re.findall(r"[a-z][a-z0-9_-]{3,}", s.lower()) if w not in STOP}

pt = toks(prompt)
if not pt:
    sys.exit(0)

scored = []
for line in open(ledger, encoding="utf-8"):
    if not line.startswith("- "):
        continue
    # match the [#critical] TAG, not the bare word — a lesson MENTIONING it is
    # not always-loaded and must stay recallable (caught 2026-07-03)
    if "[#critical]" in line or re.search(r"\[I:(9|10)\]", line):   # already always-loaded
        continue
    if cross_project(line):                                         # another project's specifics
        continue
    hits = pt & toks(line)
    if len(hits) >= minhits:
        # Rank = raw keyword hits + same-sector boost (+2) + 0.1*importance, so a
        # same-sector or higher-importance lesson outranks an equal-keyword one.
        # The MIN_HITS gate stays on RAW hits — sector never injects noise.
        line_sectors = SECTOR_RE.findall(line)
        m = IMP_RE.search(line)
        imp = int(m.group(1)) if m else 5
        boost = 2 if (cur_sector and cur_sector in line_sectors) else 0
        scored.append((len(hits) + boost + 0.1 * imp, line.rstrip()))

# playbook strategies score the same way (top-5-by-helpful already ride the
# loader; recalling by relevance here catches the deferred rest)
if playbook and os.path.exists(playbook):
    for line in open(playbook, encoding="utf-8"):
        if not line.startswith("- [P"):
            continue
        if cross_project(line):
            continue
        hits = pt & toks(line)
        if len(hits) >= minhits:
            scored.append((len(hits), line.rstrip()))

scored.sort(key=lambda x: -x[0])
top = scored[:maxn]
if not top:
    sys.exit(0)

print("----- COGITO RECALL (past lessons/strategies relevant to this prompt — apply them, don't just store them) -----")
for _, line in top:
    print(line)
print("----- end COGITO RECALL -----")
PY
exit 0
