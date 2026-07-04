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
PLAYBOOK="$ROOT/skills/cogito-protocol/PLAYBOOK.md"
PB_ARCHIVE="$ROOT/skills/cogito-protocol/PLAYBOOK-ARCHIVE.md"
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
  if [ -f "$PLAYBOOK" ]; then
    echo
    echo "Strategy playbook:"
    echo "  bullets: $(grep -c '^- \[P' "$PLAYBOOK" || true)"
    echo "  demote candidates (harmful > helpful — move to PLAYBOOK-ARCHIVE at the next pass):"
    grep '^- \[P' "$PLAYBOOK" | while IFS= read -r b; do
      h="$(printf '%s' "$b" | sed -n 's/.*\[helpful:\([0-9]*\)\].*/\1/p')"
      m="$(printf '%s' "$b" | sed -n 's/.*\[harmful:\([0-9]*\)\].*/\1/p')"
      [ "${m:-0}" -gt "${h:-0}" ] && printf '    %s\n' "$b"
    done || true
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

  # Playbook conservation: a bullet removed from PLAYBOOK.md must either reappear
  # in PLAYBOOK-ARCHIVE.md (a demotion/merge) or be a COUNTER BUMP — the same
  # bullet re-added with only [helpful:N]/[harmful:N] changed (the legit in-place
  # delta). Compare with counters stripped.
  local pb_removed pb_added pb_archived pb_missing stripped
  pb_removed="$(git -C "$ROOT" diff "$BASE" -- "$PLAYBOOK" 2>/dev/null | grep '^-- ' | sed 's/^-//' || true)"
  pb_added="$(git -C "$ROOT" diff "$BASE" -- "$PLAYBOOK" 2>/dev/null | grep '^+- ' | sed 's/^+//' || true)"
  pb_archived="$(git -C "$ROOT" diff "$BASE" -- "$PB_ARCHIVE" 2>/dev/null | grep '^+- ' | sed 's/^+//' || true)"
  pb_missing=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    grep -qxF -- "$line" <<< "$pb_archived" && continue
    stripped="$(printf '%s' "$line" | sed 's/\[helpful:[0-9]*\]\[harmful:[0-9]*\]//')"
    printf '%s\n' "$pb_added" | sed 's/\[helpful:[0-9]*\]\[harmful:[0-9]*\]//' | grep -qxF -- "$stripped" && continue
    pb_missing+="$line"$'\n'
  done <<< "$pb_removed"
  if [ -n "${pb_missing//[$'\n']/}" ]; then
    echo "FAIL — these playbook bullets were removed but are neither archived nor counter-bumped:"
    printf '%s' "$pb_missing" | sed 's/^/    /'
    exit 1
  fi

  echo "PASS — every removed lesson is preserved in the archive."
  echo "Now read 'git diff' for over-merge (a rule that swallowed a distinct cause), then commit."
}

suggest_skills() {
  [ -f "$LEDGER" ] || die "no ledger at $LEDGER"
  local INDEX="$ROOT/skills/INDEX.md"
  local trigger="${COGITO_SKILL_TRIGGER:-8}"
  local draftroot="$ROOT/docs/skill-drafts"
  echo "Cogito skill suggestions — recurring clusters (>= $trigger lessons on one tag) with NO covering skill"
  echo "  index: $INDEX"
  [ -f "$INDEX" ] || echo "  (note: INDEX.md missing — every cluster treated as uncovered)"
  echo "  A cluster this large is a recurring problem domain. If no skill covers it, we scaffold a"
  echo "  DRAFT (un-indexed, cannot auto-load). It becomes a real skill only after the graduation gate."
  echo
  local clusters suggested=0
  clusters="$(grep '^- ' "$LEDGER" | grep -oE '\[#[a-z][a-z-]*\]' | sort | uniq -c | sort -rn || true)"
  while read -r count tag; do
    [ -n "${count:-}" ] || continue
    [ "$count" -ge "$trigger" ] 2>/dev/null || continue
    local kw="${tag//[\[\]#]/}"
    case "$kw" in critical|process) continue;; esac     # meta-tags (severity / the protocol itself), not skill domains
    if [ -f "$INDEX" ] && grep -qiw "$kw" "$INDEX" 2>/dev/null; then
      echo "  [covered]  #$kw  ($count lessons) — an indexed skill already addresses this"
      continue
    fi
    suggested=$((suggested + 1))
    local dstub="$draftroot/cogito-$kw"
    echo "  [SUGGEST]  #$kw  ($count lessons) — no covering skill -> draft ${dstub#"$ROOT"/}/SKILL.md"
    if [ -f "$dstub/SKILL.md" ]; then
      echo "             draft already exists — review + graduate, or delete"
      continue
    fi
    mkdir -p "$dstub"
    {
      echo "---"
      echo "name: cogito-$kw"
      echo "description: DRAFT (not indexed). Auto-scaffolded from $count recurring [#$kw] lessons. NOT a real skill until it works in 2+ real sessions and is added to skills/INDEX.md."
      echo "---"
      echo
      echo "# $kw — draft skill (UNVERIFIED, not indexed)"
      echo
      echo "Scaffolded because $count lessons carry [#$kw] — a recurring problem domain with no covering skill. The RULE clauses distilled from those lessons:"
      echo
      grep '^- ' "$LEDGER" | grep -F "[#$kw]" | awk -F' -> ' '{print "- "$NF}' | head -12
      echo
      echo "## Graduation gate (do not skip)"
      echo "Do NOT add this to skills/INDEX.md until it has demonstrably worked in 2+ INDEPENDENT real sessions (Voyager's verified-skill rule, strengthened because human-judged success is noisier than a code-execution check). Until then it is a hypothesis, not procedural memory. To graduate: flesh out the procedure, prove it live twice, move it under skills/, then add the INDEX.md line."
    } > "$dstub/SKILL.md"
    echo "             scaffolded ($count lessons distilled)"
  done <<< "$clusters"
  echo
  if [ "$suggested" -eq 0 ]; then
    echo "No uncovered recurring clusters at threshold $trigger — nothing to scaffold."
  else
    echo "$suggested draft(s) under ${draftroot#"$ROOT"/}/. Review, exercise in real sessions, graduate only per the gate."
  fi
}

case "${1:-}" in
  report)         report ;;
  verify)         verify ;;
  suggest-skills) suggest_skills ;;
  *) echo "usage: cogito-consolidate.sh {report|verify|suggest-skills}" >&2; exit 2 ;;
esac
