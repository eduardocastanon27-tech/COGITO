#!/usr/bin/env bash
# Cogito budget — approximate the per-session token cost of everything the
# SessionStart chain injects into context. "Measure before you trim": run it,
# don't install it (no hook loads this script, so it costs nothing per session).
# Tokens are rough (~chars/4); good enough to rank the levers.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LEDGER="$ROOT/skills/cogito-protocol/LESSONS.md"
PLAYBOOK="$ROOT/skills/cogito-protocol/PLAYBOOK.md"
MISSION="$ROOT/docs/ACTIVE-MISSION.md"
THRESHOLD="${COGITO_LOAD_THRESHOLD:-20}"
PREAMBLE_TOK=260   # the fixed protocol text the two hooks always print (approx)

tok() { local c; c=$(printf '%s' "${1:-}" | wc -m | tr -d ' '); echo $(( c / 4 )); }

n=$(grep -c '^- ' "$LEDGER" 2>/dev/null || echo 0)
if [ "${n:-0}" -le "$THRESHOLD" ]; then
  ledger_txt="$(grep '^- ' "$LEDGER" 2>/dev/null || true)"
  ledger_mode="FULL — all $n lessons loaded every session (<= $THRESHOLD threshold)"
else
  crit="$(grep -E '^- .*(\[I:(9|10)\]|\[#critical\])' "$LEDGER" 2>/dev/null | awk '{n+=length($0)+1; if(n>7000) exit; print}' || true)"
  idx="$(grep '^- ' "$LEDGER" 2>/dev/null | grep -oE '\[#[a-z-]+\]' | sort | uniq -c || true)"
  ledger_txt="$crit"$'\n'"$idx"
  cn=$(printf '%s' "$crit" | grep -c '^- ' || true)
  ledger_mode="index — $cn severe always-load (7k-char cap), other $((n-cn)) deferred to grep (> $THRESHOLD)"
fi
pb_txt=""
if [ -f "$PLAYBOOK" ] && grep -q '^- \[P' "$PLAYBOOK" 2>/dev/null; then
  pb_txt="$(grep '^- \[P' "$PLAYBOOK" | sed -n 's/.*\[helpful:\([0-9]*\)\].*/\1 &/p' | sort -rn | head -5 | cut -d' ' -f2- | awk '{n+=length($0)+1; if(n>3000) exit; print}' || true)"
fi
mission_txt="$(head -c 6000 "$MISSION" 2>/dev/null || true)"
recap_txt="$("$ROOT/scripts/cogito-review.sh" due --quiet 2>/dev/null || true)"

lt=$(tok "$ledger_txt"); pt=$(tok "$pb_txt"); mt=$(tok "$mission_txt"); rt=$(tok "$recap_txt")
total=$(( lt + pt + mt + rt + PREAMBLE_TOK ))

echo "Cogito — approx tokens injected into EVERY session (chars/4):"
echo
echo "REPO sessions (the full brain — project SessionStart hooks):"
printf '  %-26s ~%5s tok   %s\n' "lessons ledger"          "$lt"           "$ledger_mode"
printf '  %-26s ~%5s tok   %s\n' "strategy playbook"       "$pt"           "(top-5 by helpful, 3k-char cap)"
printf '  %-26s ~%5s tok   %s\n' "ACTIVE-MISSION.md"       "$mt"           "(6k-char cap + truncation warning)"
printf '  %-26s ~%5s tok   %s\n' "learning recap"          "$rt"           "(most-overdue cue)"
printf '  %-26s ~%5s tok   %s\n' "fixed protocol preamble" "$PREAMBLE_TOK" "(the two hooks boilerplate)"
echo   "  --------------------------------------------------------------"
printf '  %-26s ~%5s tok   <- rides every turn, every REPO session\n' "TOTAL" "$total"

echo
echo "GLOBAL sessions (any other directory — cogito-global-load.sh, lean mode):"
if [ -x "$ROOT/scripts/cogito-global-load.sh" ]; then
  g="$(cd /tmp && CLAUDE_PROJECT_DIR=/tmp COGITO_GLOBAL=1 bash "$ROOT/scripts/cogito-global-load.sh" 2>/dev/null || true)"
  gt=$(tok "$g")
  printf '  %-26s ~%5s tok   (CORE + criticals + top strategies; kill-switch: COGITO_GLOBAL=0)\n' "global loader" "$gt"
else
  echo "  (cogito-global-load.sh not present)"
fi
echo
echo "Levers, biggest first: consolidate the severe set (its 7k cap is the ceiling);"
echo "keep ACTIVE-MISSION a resume pointer; playbook stays top-5 only."
