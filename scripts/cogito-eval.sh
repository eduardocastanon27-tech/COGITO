#!/usr/bin/env bash
# cogito-eval — measure whether the Cogito brain LIFTS a model on scar-derived
# tasks. The honesty instrument for the whole system: a zero or negative delta
# is a FINDING about the brain, to be committed as measured, never hidden.
#
#   scripts/cogito-eval.sh [run]        full suite (all tasks × models × arms)
#   scripts/cogito-eval.sh smoke        T01 only, one model — end-to-end shakedown
#
# Design:
#   subjects  = $COGITO_EVAL_MODELS (default: claude-haiku-4-5-20251001 claude-opus-4-8)
#   arms      = bare (no injection) vs brain (--append-system-prompt = COGITO-CORE
#               + critical lessons + top-5 playbook strategies)
#   isolation = BOTH arms run with COGITO_GLOBAL=0 so the global loader cannot
#               contaminate the control arm
#   judge     = the session's default `claude -p` model (stronger), scoring both
#               responses per docs/eval/rubric.md under randomized blind A/B labels
#   output    = docs/eval/results-<date>.md (+ raw transcripts under docs/eval/runs/)
# Sequential, one call at a time — this box has ~750MiB free RAM.
set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || pwd)"
SP="$ROOT/skills/cogito-protocol"
TASKS_DIR="$ROOT/docs/eval/tasks"
RUBRIC="$ROOT/docs/eval/rubric.md"
STAMP="$(date +%F)"
RUNS="$ROOT/docs/eval/runs/$STAMP"
RESULTS="$ROOT/docs/eval/results-$STAMP.md"
MODELS="${COGITO_EVAL_MODELS:-claude-haiku-4-5-20251001 claude-opus-4-8}"
TIMEOUT="${COGITO_EVAL_TIMEOUT:-240}"

command -v claude >/dev/null 2>&1 || { echo "cogito-eval: claude CLI not found" >&2; exit 1; }
[ -f "$RUBRIC" ] || { echo "cogito-eval: no rubric at $RUBRIC" >&2; exit 1; }
mkdir -p "$RUNS"

# The brain payload injected in the "brain" arm.
BRAIN="$(
  cat "$SP/COGITO-CORE.md" 2>/dev/null
  echo
  echo "Critical lessons from past work (never repeat these):"
  grep -E '^- .*(\[I:(9|10)\]|\[#critical\])' "$SP/LESSONS.md" 2>/dev/null | head -8
  echo
  echo "Proven strategies (apply where relevant):"
  grep '^- \[P' "$SP/PLAYBOOK.md" 2>/dev/null | head -5
)"

section() { # $1=file $2=header -> body until next '## '
  awk -v h="$2" '$0 ~ "^## "h {f=1; next} /^## / {f=0} f' "$1"
}

ask() { # $1=model $2=arm $3=prompt -> stdout response
  local args=(-p --model "$1")
  [ "$2" = "brain" ] && args+=(--append-system-prompt "$BRAIN")
  COGITO_GLOBAL=0 timeout "$TIMEOUT" claude "${args[@]}" "$3" 2>/dev/null
}

judge() { # $1=task-file $2=respA-file $3=respB-file -> judge JSON on stdout
  local prompt expected jp
  prompt="$(section "$1" "Prompt")"
  expected="$(section "$1" "Expected behavior \\(judge only\\)")"
  jp="You are a strict evaluation judge. Score two blinded assistant responses against this rubric:

$(cat "$RUBRIC")

## Task given to both assistants
$prompt

## Expected behavior (reference for you only)
$expected

## Response A
$(cat "$2")

## Response B
$(cat "$3")

Score now. Output ONLY the JSON object from the rubric's output contract."
  COGITO_GLOBAL=0 timeout "$TIMEOUT" claude -p "$jp" 2>/dev/null
}

parse_scores() { # stdin = judge output; $1 = label(A|B) -> "process verification lesson" or ""
  python3 -c '
import sys, json, re
raw = sys.stdin.read()
m = re.search(r"\{.*\}", raw, re.S)
if not m: sys.exit(1)
try: d = json.loads(m.group(0))
except Exception: sys.exit(1)
lab = sys.argv[1]
s = d.get(lab, {})
try: print(s["process"], s["verification"], s["lesson"])
except Exception: sys.exit(1)' "$1"
}

run_suite() {
  local tasks="$1"
  {
    echo "# Cogito eval — $STAMP"
    echo
    echo "**A zero or negative delta is a finding about the brain, not a bug in the eval — reported as measured.**"
    echo
    echo "Arms: bare vs brain (COGITO-CORE + criticals + top strategies via --append-system-prompt); both arms COGITO_GLOBAL=0. Judge: default claude -p, blinded randomized A/B. Rubric: docs/eval/rubric.md."
    echo
  } > "$RESULTS"

  local model task tname arm afile bfile jout swap
  for model in $MODELS; do
    echo "## Subject: $model" >> "$RESULTS"
    echo "" >> "$RESULTS"
    echo "| task | dim | bare | brain | Δ |" >> "$RESULTS"
    echo "|---|---|---|---|---|" >> "$RESULTS"
    # per-model accumulators
    local sum_bare_p=0 sum_bare_v=0 sum_bare_l=0 sum_brain_p=0 sum_brain_v=0 sum_brain_l=0 n=0
    for task in $tasks; do
      tname="$(basename "$task" .md)"
      echo "cogito-eval: $model / $tname ..." >&2
      local prompt; prompt="$(section "$task" "Prompt")"
      [ -n "$prompt" ] || { echo "  skip (no prompt)" >&2; continue; }
      ask "$model" bare  "$prompt" > "$RUNS/$tname.$model.bare.txt"  || true
      ask "$model" brain "$prompt" > "$RUNS/$tname.$model.brain.txt" || true
      if [ ! -s "$RUNS/$tname.$model.bare.txt" ] || [ ! -s "$RUNS/$tname.$model.brain.txt" ]; then
        echo "| $tname | — | (subject call failed) | | |" >> "$RESULTS"; continue
      fi
      # blind: even task-hash -> A=bare, odd -> A=brain
      swap=$(( $(printf '%s' "$tname$model" | cksum | cut -d' ' -f1) % 2 ))
      if [ "$swap" -eq 0 ]; then afile="$RUNS/$tname.$model.bare.txt"; bfile="$RUNS/$tname.$model.brain.txt"
      else                       afile="$RUNS/$tname.$model.brain.txt"; bfile="$RUNS/$tname.$model.bare.txt"; fi
      jout="$(judge "$task" "$afile" "$bfile")"; printf '%s\n' "$jout" > "$RUNS/$tname.$model.judge.txt"
      local sA sB s_bare s_brain
      sA="$(printf '%s' "$jout" | parse_scores A || true)"
      sB="$(printf '%s' "$jout" | parse_scores B || true)"
      if [ -z "$sA" ] || [ -z "$sB" ]; then
        echo "| $tname | — | (judge parse failed) | | |" >> "$RESULTS"; continue
      fi
      if [ "$swap" -eq 0 ]; then s_bare="$sA"; s_brain="$sB"; else s_bare="$sB"; s_brain="$sA"; fi
      read -r bp bv bl <<< "$s_bare"; read -r rp rv rl <<< "$s_brain"
      echo "| $tname | process | $bp | $rp | $((rp-bp)) |" >> "$RESULTS"
      echo "| $tname | verification | $bv | $rv | $((rv-bv)) |" >> "$RESULTS"
      echo "| $tname | lesson | $bl | $rl | $((rl-bl)) |" >> "$RESULTS"
      sum_bare_p=$((sum_bare_p+bp)); sum_bare_v=$((sum_bare_v+bv)); sum_bare_l=$((sum_bare_l+bl))
      sum_brain_p=$((sum_brain_p+rp)); sum_brain_v=$((sum_brain_v+rv)); sum_brain_l=$((sum_brain_l+rl))
      n=$((n+1))
    done
    if [ "$n" -gt 0 ]; then
      {
        echo "| **mean** | process | $(python3 -c "print(f'{$sum_bare_p/$n:.2f}')") | $(python3 -c "print(f'{$sum_brain_p/$n:.2f}')") | $(python3 -c "print(f'{($sum_brain_p-$sum_bare_p)/$n:+.2f}')") |"
        echo "| **mean** | verification | $(python3 -c "print(f'{$sum_bare_v/$n:.2f}')") | $(python3 -c "print(f'{$sum_brain_v/$n:.2f}')") | $(python3 -c "print(f'{($sum_brain_v-$sum_bare_v)/$n:+.2f}')") |"
        echo "| **mean** | lesson | $(python3 -c "print(f'{$sum_bare_l/$n:.2f}')") | $(python3 -c "print(f'{$sum_brain_l/$n:.2f}')") | $(python3 -c "print(f'{($sum_brain_l-$sum_bare_l)/$n:+.2f}')") |"
        echo ""
      } >> "$RESULTS"
    fi
  done
  echo "cogito-eval: done -> $RESULTS" >&2
}

case "${1:-run}" in
  smoke)
    MODELS="$(printf '%s' "$MODELS" | awk '{print $1}')"
    run_suite "$TASKS_DIR/T01-deploy-claim.md" ;;
  run)
    run_suite "$(ls "$TASKS_DIR"/T*.md)" ;;
  *) echo "usage: cogito-eval.sh [run|smoke]" >&2; exit 2 ;;
esac
