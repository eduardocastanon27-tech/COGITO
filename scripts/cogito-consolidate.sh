#!/usr/bin/env bash
# Cogito consolidation helper — the runnable half of the /consolidate procedure
# (skill: cogito-consolidate). It does NOT merge lessons (that is LLM judgment);
# it gives the deterministic checks that make a merge safe.
#
#   cogito-consolidate.sh report   cluster the ledger by tag + show whether the
#                                  consolidation trigger is reached. Run BEFORE.
#   cogito-consolidate.sh verify   conservation gate: prove the pass lost nothing
#                                  — every '- ' line removed from the active
#                                  ledger must reappear verbatim in the archive.
#                                  Run AFTER editing, before committing; exits
#                                  non-zero if any removed line is unaccounted for.
#
# The canonical files live in the repo; this always operates on the repo copy.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LEDGER="$ROOT/skills/cogito-protocol/LESSONS.md"
ARCHIVE="$ROOT/skills/cogito-protocol/LESSONS-ARCHIVE.md"
TRIGGER="${COGITO_CONSOLIDATE_TRIGGER:-60}"      # active-count threshold
PROBATION="${COGITO_CONSOLIDATE_PROBATION:-5}"   # most-recent N lessons exempt
BASE="${COGITO_CONSOLIDATE_BASE:-HEAD}"          # diff base for verify

die() { echo "cogito-consolidate: $*" >&2; exit 1; }

report() {
  [ -f "$LEDGER" ] || die "no ledger at $LEDGER"
  local n untagged
  n="$(grep -c '^- ' "$LEDGER" || true)"
  echo "Cogito consolidation — report"
  echo "  ledger        : $LEDGER"
  echo "  active lessons: $n   (trigger at >= $TRIGGER)"
  echo "  probation     : most recent $PROBATION lessons are exempt from merging"
  echo
  echo "Tag clusters (3+ in a tag = merge candidate):"
  grep '^- ' "$LEDGER" | grep -oE '\[#[a-z][a-z-]*\]' | sort | uniq -c | sort -rn | sed 's/^/    /' \
    || echo "    (no tags yet)"
  untagged="$(grep '^- ' "$LEDGER" | grep -cvE '\[#' || true)"
  echo "    untagged active lessons: $untagged  (tag these first — tags are the index)"
  echo
  echo "Severe lessons (I:9-10 or #critical — always load, never merge away):"
  if grep -qE '^- .*(\[I:(9|10)\]|#critical)' "$LEDGER"; then
    grep -nE '^- .*(\[I:(9|10)\]|#critical)' "$LEDGER" | sed 's/^/    /'
  else
    echo "    (none)"
  fi
  echo
  if [ "${n:-0}" -ge "$TRIGGER" ]; then
    echo "TRIGGER REACHED -> run a consolidation pass (skill: cogito-consolidate)."
  else
    echo "Below trigger ($n < $TRIGGER) -> no pass needed yet. Mechanism is ready;"
    echo "dry-run only if exercising it. Do not force-merge a small ledger."
  fi
}

verify() {
  [ -f "$LEDGER" ]  || die "no ledger at $LEDGER"
  [ -f "$ARCHIVE" ] || die "no archive at $ARCHIVE — seed it before consolidating"
  local removed added_active added_archive missing count_rm count_arch count_new

  # In a unified diff a removed lesson reads '-- text' and an added one '+- text'
  # (the diff marker plus the lesson's own '- '). Strip one leading marker so the
  # two sets can be compared verbatim. File headers ('--- a/', '+++ b/') and
  # context lines (' - text') do not match these patterns.
  removed="$(git -C "$ROOT" diff "$BASE" -- "$LEDGER"  | grep '^-- ' | sed 's/^-//' || true)"
  added_active="$(git -C "$ROOT" diff "$BASE" -- "$LEDGER"  | grep '^+- ' | sed 's/^+//' || true)"
  added_archive="$(git -C "$ROOT" diff "$BASE" -- "$ARCHIVE" | grep '^+- ' | sed 's/^+//' || true)"

  if [ -z "$removed" ] && [ -z "$added_active" ]; then
    echo "No consolidation changes in the active ledger (vs $BASE). Nothing to verify."
    return 0
  fi

  # Membership check via herestring, NOT a pipe: under `set -o pipefail`, grep -q
  # exits at first match and SIGPIPEs the printf feeding it (exit 141), so a
  # SUCCESSFUL match randomly read as failure — the gate false-FAILED with a
  # different missing-set on every run (caught 2026-07-03).
  missing=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    grep -qxF -- "$line" <<< "$added_archive" || missing+="$line"$'\n'
  done <<< "$removed"

  count_rm="$(printf '%s' "$removed"        | grep -c '^- ' || true)"
  count_arch="$(printf '%s' "$added_archive" | grep -c '^- ' || true)"
  count_new="$(printf '%s' "$added_active"   | grep -c '^- ' || true)"

  echo "Cogito consolidation — verify (base $BASE)"
  echo "  removed from active   : $count_rm"
  echo "  moved into archive    : $count_arch"
  echo "  new higher-tier rules : $count_new"
  echo

  if [ -n "${missing//[$'\n']/}" ]; then
    echo "FAIL — these lines left the active ledger but are NOT in the archive:"
    printf '%s' "$missing" | sed 's/^/    /'
    echo
    echo "A consolidation must MOVE raw lines into LESSONS-ARCHIVE.md, never drop them."
    exit 1
  fi
  echo "PASS — every removed lesson is preserved in the archive."
  echo "Now read 'git diff' for over-merge (a rule that swallowed a distinct cause), then commit."
}

case "${1:-}" in
  report) report ;;
  verify) verify ;;
  *) echo "usage: cogito-consolidate.sh {report|verify}" >&2; exit 2 ;;
esac
