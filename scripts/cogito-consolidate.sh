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

# Scaffold ONE draft skill from a cluster of lessons matching a grep pattern.
# Shared by the topical-tag loop and the sector loop in suggest_skills.
scaffold_draft() {  # $1=kw(name/dir)  $2=count  $3=grep-pattern  $4=human label
  local kw="$1" count="$2" pat="$3" label="$4"
  local dstub="$ROOT/docs/skill-drafts/cogito-$kw"
  echo "  [SUGGEST]  $label  ($count lessons) — no covering skill -> draft ${dstub#"$ROOT"/}/SKILL.md"
  if [ -f "$dstub/SKILL.md" ]; then
    echo "             draft already exists — review + graduate, or delete"; return
  fi
  mkdir -p "$dstub"
  {
    echo "---"
    echo "name: cogito-$kw"
    echo "description: DRAFT (not indexed). Auto-scaffolded from $count recurring $label lessons. NOT a real skill until it works in 2+ real sessions and is added to skills/INDEX.md."
    echo "---"
    echo
    echo "# $kw — draft skill (UNVERIFIED, not indexed)"
    echo
    echo "Scaffolded because $count lessons match $label — a recurring problem domain with no covering skill. The RULE clauses distilled from those lessons:"
    echo
    grep '^- ' "$LEDGER" | grep -F "$pat" | awk -F' -> ' '{print "- "$NF}' | head -12
    echo
    echo "## Graduation gate (do not skip)"
    echo "Do NOT add this to skills/INDEX.md until it has demonstrably worked in 2+ INDEPENDENT real sessions (Voyager's verified-skill rule, strengthened because human-judged success is noisier than a code-execution check). Until then it is a hypothesis, not procedural memory. To graduate: flesh out the procedure, prove it live twice, move it under skills/, then add the INDEX.md line."
  } > "$dstub/SKILL.md"
  echo "             scaffolded ($count lessons distilled)"
}

suggest_skills() {
  [ -f "$LEDGER" ] || die "no ledger at $LEDGER"
  local INDEX="$ROOT/skills/INDEX.md"
  local trigger="${COGITO_SKILL_TRIGGER:-8}"
  echo "Cogito skill suggestions — recurring clusters (>= $trigger lessons) with NO covering skill"
  echo "  index: $INDEX"
  [ -f "$INDEX" ] || echo "  (note: INDEX.md missing — every cluster treated as uncovered)"
  echo "  A cluster this large is a recurring problem domain. If no skill covers it, we scaffold a"
  echo "  DRAFT (un-indexed, cannot auto-load). It becomes a real skill only after the graduation gate."
  echo
  local clusters suggested=0
  # 1) Topical-tag clusters (#web, #deploy, ...).
  clusters="$(grep '^- ' "$LEDGER" | grep -oE '\[#[a-z][a-z-]*\]' | sort | uniq -c | sort -rn || true)"
  while read -r count tag; do
    [ -n "${count:-}" ] || continue
    [ "$count" -ge "$trigger" ] 2>/dev/null || continue
    local kw="${tag//[\[\]#]/}"
    case "$kw" in critical|process) continue;; esac     # meta-tags, not skill domains
    if [ -f "$INDEX" ] && grep -qiw "$kw" "$INDEX" 2>/dev/null; then
      echo "  [covered]  #$kw  ($count lessons) — an indexed skill already addresses this"
      continue
    fi
    suggested=$((suggested + 1))
    scaffold_draft "$kw" "$count" "[#$kw]" "#$kw"
  done <<< "$clusters"
  # 2) SECTOR clusters — a maturing sector with no governing skill drafts one too.
  #    web/toy/tracker already map to skills (web-master/generative-toys/cogstack);
  #    game/data/infra are uncovered and would draft once they mature.
  local sec seccount gov
  for sec in web game toy tracker data infra; do
    seccount="$(grep '^- ' "$LEDGER" | grep -cF "[#sector:$sec]" || true)"
    [ "${seccount:-0}" -ge "$trigger" ] 2>/dev/null || continue
    case "$sec" in web) gov="web-master";; toy) gov="generative-toys";; tracker) gov="cogstack";; *) gov="";; esac
    if [ -n "$gov" ]; then
      echo "  [covered]  sector:$sec  ($seccount lessons) — the $gov skill governs this sector"
      continue
    fi
    suggested=$((suggested + 1))
    scaffold_draft "sector-$sec" "$seccount" "[#sector:$sec]" "sector:$sec"
  done
  echo
  if [ "$suggested" -eq 0 ]; then
    echo "No uncovered recurring clusters at threshold $trigger — nothing to scaffold."
  else
    echo "$suggested draft(s) under docs/skill-drafts/. Review, exercise in real sessions, graduate only per the gate."
  fi
}

# refresh-sectors — the distillation half of "data -> skills": rebuild each
# sectors/<x>.md from its [#sector:x] lessons' RULE clauses, ranked by importance.
# Proposal by default (prints); --apply overwrites the playbooks that have tagged
# lessons (a hand-seeded playbook with no lessons yet is left untouched). The
# output is a MECHANICAL extract for a human to tighten, mirroring the consolidate
# discipline: propose, human gates, converge carries.
refresh_sectors() {
  [ -f "$LEDGER" ] || die "no ledger at $LEDGER"
  local SECDIR="$ROOT/skills/cogito-protocol/sectors" apply=0
  [ "${1:-}" = "--apply" ] && apply=1
  echo "Cogito sector-playbook refresh — distill each sector's tagged lessons into sectors/<x>.md"
  echo "  ledger : $LEDGER"
  echo "  sectors: $SECDIR"
  if [ "$apply" = 1 ]; then echo "  MODE: --apply (OVERWRITES sectors that have tagged lessons)"; else echo "  MODE: proposal only (re-run with --apply to write)"; fi
  echo
  python3 - "$LEDGER" "$SECDIR" "$apply" <<'PY'
import sys, re, os
ledger, secdir, apply = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
SECTORS = ["web", "game", "toy", "tracker", "data", "infra"]
lines = [l.rstrip("\n") for l in open(ledger, encoding="utf-8") if l.startswith("- ")]
def imp(l):
    m = re.search(r"\[I:(\d+)\]", l); return int(m.group(1)) if m else 5
def rule(l):
    l = re.sub(r"\s*\{[^{}]*\}\s*$", "", l)            # strip {provenance}
    parts = l.split(" -> ")
    return parts[-1].strip() if len(parts) >= 2 else ""
for sec in SECTORS:
    tagged = sorted([l for l in lines if "[#sector:%s]" % sec in l], key=lambda x: -imp(x))
    head = ["# Sector playbook: %s" % sec,
            "_Auto-distilled from %d [#sector:%s] lesson(s), ranked by importance. Review + tighten by hand; loaded at project open._" % (len(tagged), sec),
            ""]
    out, total, kept = list(head), sum(len(x) + 1 for x in head), 0
    for l in tagged:
        r = rule(l)
        if len(r) <= 8:
            continue
        b = "- " + r
        if kept >= 8 or total + len(b) + 1 > 1200:
            break
        out.append(b); total += len(b) + 1; kept += 1
    content = "\n".join(out) + "\n"
    print("=== %s: %d tagged, %d bullets, %dB ===" % (sec, len(tagged), kept, len(content)))
    print(content)
    if apply and tagged:
        open(os.path.join(secdir, sec + ".md"), "w", encoding="utf-8").write(content)
        print("(wrote %s.md)" % sec)
    elif apply:
        print("(skipped %s: no tagged lessons — kept the hand-seeded file)" % sec)
PY
}

# graduate — the HOW lane of the Cogito<->native merge. A PLAYBOOK strategy that
# has repeatedly proven itself (helpful >= threshold, harmful 0) is a candidate to
# become a real executable SKILL.md. This REPORTS the candidates (authoring a skill
# is human/`/skill` work); the bullet stays — the skill is its graduation, not its
# replacement. Distinct from suggest-skills (which drafts from lesson CLUSTERS).
graduate() {
  [ -f "$PLAYBOOK" ] || die "no playbook at $PLAYBOOK"
  local thr="${COGITO_GRADUATE_HELPFUL:-3}" found=0 h m
  echo "Cogito playbook graduation — strategies proven >= $thr helpful (harmful:0) = HOW-lane skill candidates"
  echo
  while IFS= read -r b; do
    h="$(printf '%s' "$b" | sed -n 's/.*\[helpful:\([0-9]*\)\].*/\1/p')"
    m="$(printf '%s' "$b" | sed -n 's/.*\[harmful:\([0-9]*\)\].*/\1/p')"
    if [ "${h:-0}" -ge "$thr" ] && [ "${m:-0}" -eq 0 ]; then
      found=$((found + 1)); printf '  [GRADUATE] %s\n' "$b"
    fi
  done < <(grep '^- \[P' "$PLAYBOOK" 2>/dev/null || true)
  echo
  if [ "$found" -eq 0 ]; then
    echo "No strategies at the bar yet — bump bullets with 'cogito-learn.sh --bump P###:helpful' as they prove out."
  else
    echo "$found proven strateg(ies). Author each into a real SKILL.md (by hand or the Hermes /skill machinery) so a proven strategy becomes an executable procedure, not just prose."
  fi
}

case "${1:-}" in
  report)          report ;;
  verify)          verify ;;
  suggest-skills)  suggest_skills ;;
  refresh-sectors) refresh_sectors "${2:-}" ;;
  graduate)        graduate ;;
  *) echo "usage: cogito-consolidate.sh {report|verify|suggest-skills|refresh-sectors [--apply]|graduate}" >&2; exit 2 ;;
esac
