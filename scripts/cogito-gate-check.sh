#!/usr/bin/env bash
# cogito-gate-check — the brain's hub-side merge gate (decision logic only).
#
# Reads a unified PR diff on stdin and decides whether it is a PROVABLY-SAFE lesson
# append that may AUTO-MERGE, or must HOLD for the owner's one-tap. Pure and locally
# testable; the GitHub Action (.github/workflows/brain-merge.yml) is the thin wrapper
# that feeds it `gh pr diff` and merges on MERGE.
#
# Council Step B rule — "append is cheap + automatic; contradicting canon is expensive
# + gated." AUTO-MERGE only when ALL hold:
#   - the ONLY changed files are the ledger (skills/cogito-protocol/LESSONS.md)
#     and/or the playbook (skills/cogito-protocol/PLAYBOOK.md)
#   - it ADDS lines and REMOVES none (append-only; a correction/supersede/counter
#     bump removes or edits a line -> the diff shows a deletion -> HOLD; local
#     counter bumps ride converge instead, which is the intended path)
#   - every added non-blank ledger line is a lesson (^- ... -> ... -> ...) with no
#     'supersedes:'; every added playbook line is a strategy bullet
#     (^- [P###][#tag...][helpful:N][harmful:N] ...)
#   - at least one line is added, and no more than the size cap
# Anything else -> "HOLD: <reason>" (the PR is left open for the owner to merge by hand).
#
# Output: a single line beginning with MERGE or HOLD. Exit is always 0 (the wrapper
# branches on the word; a crashed checker must never be read as "safe to merge").
set -uo pipefail
LEDGER="${COGITO_LEDGER_PATH:-skills/cogito-protocol/LESSONS.md}"
PLAYBOOK="${COGITO_PLAYBOOK_PATH:-skills/cogito-protocol/PLAYBOOK.md}"
MAX_ADDED="${COGITO_GATE_MAX_ADDED:-25}"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cat > "$WORK/gate.py" <<'PY'
import sys, re
ledger, playbook, maxn = sys.argv[1], sys.argv[2], int(sys.argv[3])
files = set(); added = {}; removed = 0; cur = None
for ln in sys.stdin.read().splitlines():
    if ln.startswith('+++ b/'):
        p = ln[6:].strip()
        if p != '/dev/null': files.add(p); cur = p
    elif ln.startswith('--- a/'):
        p = ln[6:].strip()
        if p != '/dev/null': files.add(p)
    elif ln.startswith('+++ ') or ln.startswith('--- ') or ln.startswith('@@') or ln.startswith('diff '):
        continue
    elif ln.startswith('+'):
        added.setdefault(cur, []).append(ln[1:])
    elif ln.startswith('-'):
        removed += 1

def out(s):
    print(s); sys.exit(0)

if not files:
    out("HOLD: no changed files found in the diff")
if not files <= {ledger, playbook}:
    out("HOLD: changes files other than the ledger/playbook (" + ", ".join(sorted(files - {ledger, playbook})) + ")")
if removed > 0:
    out("HOLD: removes or edits %d existing line(s) — corrections/retirements/counter bumps need your review" % removed)
n_lessons = n_bullets = 0
for a in added.get(ledger, []):
    if not a.strip(): continue
    if 'supersedes:' in a:
        out("HOLD: a line carries 'supersedes:' — overturning canon needs your one-tap")
    if not re.match(r'^- .*->.*->', a):
        out("HOLD: added a non-lesson line to the ledger: " + a.strip()[:70])
    n_lessons += 1
for a in added.get(playbook, []):
    if not a.strip(): continue
    if not re.match(r'^- \[P[0-9]{3}\](\[#[a-z][a-z-]*\])+\[helpful:[0-9]+\]\[harmful:[0-9]+\] ', a):
        out("HOLD: added a malformed playbook bullet: " + a.strip()[:70])
    n_bullets += 1
if n_lessons + n_bullets == 0:
    out("HOLD: no lesson/strategy lines added")
if n_lessons + n_bullets > maxn:
    out("HOLD: adds %d lines (cap is %d) — review a batch this large" % (n_lessons + n_bullets, maxn))
out("MERGE: %d lesson(s) + %d strategy bullet(s) appended — append-only, brain-files-only, format-valid" % (n_lessons, n_bullets))
PY

decide() { python3 "$WORK/gate.py" "$LEDGER" "$PLAYBOOK" "$MAX_ADDED"; }

# ---- selftest: the gate contract as runnable assertions ---------------------------
selftest() {
  local fails=0 L="skills/cogito-protocol/LESSONS.md"
  check() { # check <expect MERGE|HOLD> <diff> <label>
    local want="$1" diff="$2" label="$3" got
    got="$(printf '%s\n' "$diff" | decide)"
    case "$got" in
      "$want"*) printf '  ok   [%s] %s\n' "$want" "$label" ;;
      *) printf '  FAIL want=%s got={%s} : %s\n' "$want" "$got" "$label"; fails=$((fails+1)) ;;
    esac
  }
  echo "cogito-gate-check selftest"

  check MERGE "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,3 +90,4 @@
 - [#x] old a -> b -> c
+- [#new] sym one -> cause one -> rule one" "one appended lesson"

  check MERGE "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,1 +90,3 @@
+- [#a] s1 -> c1 -> r1
+- [#b] s2 -> c2 -> r2" "two appended lessons"

  check HOLD "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,2 +90,2 @@
-- [#old] s -> c -> old rule
+- [#old] s -> c -> new rule" "edits an existing line (a correction)"

  check HOLD "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,2 +90,1 @@
-- [#x] s -> c -> r" "removes a line (a retirement)"

  check HOLD "diff --git a/skills/cogito-protocol/SKILL.md b/skills/cogito-protocol/SKILL.md
--- a/skills/cogito-protocol/SKILL.md
+++ b/skills/cogito-protocol/SKILL.md
@@ -1,1 +1,2 @@
+evil new instruction" "touches SKILL.md (supply-chain)"

  check HOLD "diff --git a/.github/workflows/brain-merge.yml b/.github/workflows/brain-merge.yml
--- a/.github/workflows/brain-merge.yml
+++ b/.github/workflows/brain-merge.yml
@@ -1,1 +1,2 @@
+- [#x] s -> c -> r" "edits the gate workflow itself"

  check HOLD "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,1 +90,2 @@
+- [#new] s -> c -> r
diff --git a/README.md b/README.md
--- a/README.md
+++ b/README.md
@@ -1,1 +1,2 @@
+a second file changed too" "two files: ledger + a second"

  check HOLD "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,1 +90,2 @@
+rm -rf / ; not a lesson" "added a non-lesson line"

  check HOLD "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,1 +90,2 @@
+- [#x] s -> c -> r supersedes:#abc123" "carries supersedes:"

  check HOLD "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,1 +90,1 @@
+   " "only blank added, no lesson"

  local P="skills/cogito-protocol/PLAYBOOK.md"
  check MERGE "diff --git a/$P b/$P
--- a/$P
+++ b/$P
@@ -30,1 +30,2 @@
+- [P013][#verify][helpful:0][harmful:0] new strategy that worked {via:test}" "one appended playbook bullet"

  check MERGE "diff --git a/$L b/$L
--- a/$L
+++ b/$L
@@ -90,1 +90,2 @@
+- [#a] s -> c -> r
diff --git a/$P b/$P
--- a/$P
+++ b/$P
@@ -30,1 +30,2 @@
+- [P014][#process][helpful:0][harmful:0] another strategy {via:test}" "ledger + playbook appends together"

  check HOLD "diff --git a/$P b/$P
--- a/$P
+++ b/$P
@@ -30,2 +30,2 @@
-- [P001][#verify][helpful:0][harmful:0] strategy {via:seed}
+- [P001][#verify][helpful:1][harmful:0] strategy {via:seed}" "playbook counter bump (edit) from a PR"

  check HOLD "diff --git a/$P b/$P
--- a/$P
+++ b/$P
@@ -30,1 +30,2 @@
+- [P15][#verify] missing counters" "malformed playbook bullet"

  echo
  [ "$fails" -eq 0 ] && echo "selftest: ALL PASS" || { echo "selftest: $fails FAILED"; return 1; }
}

case "${1:-}" in
  --selftest) selftest ;;
  *) decide ;;
esac
