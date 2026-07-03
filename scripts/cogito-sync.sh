#!/usr/bin/env bash
# Cogito brain sync — make THIS session (in ANY repo) start KNOWING every lesson.
#
# Run as a SessionStart hook: it loads the LESSONS into ~/.claude AND
# prints the lessons to stdout. A SessionStart hook's stdout is injected into the
# session's context, so the session literally starts with the lessons in mind and
# can't repeat a past mistake — syncing to disk alone is not enough.
#
#   - Inside the central Cogito repo: loads from the CANONICAL ref (origin/main),
#     never the checked-out session branch — so every session reads the SAME brain
#     and they cannot silently diverge. Falls back to the working tree if offline.
#   - In any other repo: clones the PUBLIC Cogito repo (anonymous, no token).
# SECURITY (council 2026-06-16): syncs LESSONS.md ONLY — never auto-overwrites SKILL.md from
# the remote, which would let a remote tip silently reprogram the agent's own instructions.
set -euo pipefail

DST="$HOME/.claude/skills/cogito-protocol"
REPO_URL="https://github.com/COGITO-SUM-cloude/COGITO.git"
SUB="skills/cogito-protocol"
BRAIN_REF="${COGITO_BRAIN_REF:-origin/main}"   # the ONE canonical brain — NOT the checked-out branch
mkdir -p "$DST"

# Load the brain (LESSONS + SKILL) from the canonical ref into $DST. Writes via
# temp files and refuses to install an EMPTY ledger, so a partial/failed read can
# never blank the brain. Returns non-zero (-> caller falls back) on any problem.
load_canonical() {
  local root="$1" t_les t_pb
  git -C "$root" cat-file -e "$BRAIN_REF:$SUB/LESSONS.md" 2>/dev/null || return 1
  t_les="$(mktemp)"
  if git -C "$root" show "$BRAIN_REF:$SUB/LESSONS.md" > "$t_les" 2>/dev/null && [ -s "$t_les" ]; then
    mv "$t_les" "$DST/LESSONS.md"
  else
    rm -f "$t_les"; return 1
  fi
  # PLAYBOOK.md is data-class like LESSONS (strategies, not operating instructions) —
  # same canonical read, same refuse-empty guard. Best-effort: an old ref without it
  # must not fail the lesson load.
  t_pb="$(mktemp)"
  if git -C "$root" show "$BRAIN_REF:$SUB/PLAYBOOK.md" > "$t_pb" 2>/dev/null && [ -s "$t_pb" ]; then
    mv "$t_pb" "$DST/PLAYBOOK.md"
  else
    rm -f "$t_pb"
  fi
  # SKILL.md is intentionally NOT synced from the remote (supply-chain: auto-overwriting the
  # agent's own operating instructions from a remote tip = silent reprogramming). Keep the
  # protocol version-controlled locally; update it deliberately. (Council ruling 2026-06-16.)
  return 0
}

src=""
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$proj" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$root" ] && [ -f "$root/$SUB/LESSONS.md" ] \
   && git -C "$root" remote -v 2>/dev/null | grep -qiE 'COGITO-SUM-cloude/COGITO(\.git)?'; then
  # best-effort: refresh the canonical ref so we read the latest shared brain
  git -C "$root" fetch --quiet origin main 2>/dev/null || true
  if load_canonical "$root"; then
    src="canonical $BRAIN_REF"
  else
    # offline / fresh clone / ref missing -> working-tree fallback (the safety net)
    cp -f "$root/$SUB/SKILL.md"   "$DST/SKILL.md"   2>/dev/null || true
    cp -f "$root/$SUB/PLAYBOOK.md" "$DST/PLAYBOOK.md" 2>/dev/null || true
    cp -f "$root/$SUB/LESSONS.md" "$DST/LESSONS.md"
    src="local working tree (fallback; $BRAIN_REF unreachable)"
  fi
else
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  if git clone --depth 1 --quiet "$REPO_URL" "$tmp" 2>/dev/null && [ -f "$tmp/$SUB/LESSONS.md" ]; then
    cp -f "$tmp/$SUB/LESSONS.md" "$DST/LESSONS.md"   # LESSONS only — never auto-pull SKILL.md from the remote (supply-chain)
    cp -f "$tmp/$SUB/PLAYBOOK.md" "$DST/PLAYBOOK.md" 2>/dev/null || true   # data-class, like LESSONS
    src="public central repo"
  fi
fi

if [ ! -f "$DST/LESSONS.md" ]; then
  echo "cogito: WARNING could not load the brain (offline?); no lessons available this session" >&2
  exit 0
fi

LEDGER="$DST/LESSONS.md"
n="$(grep -c '^- ' "$LEDGER" 2>/dev/null || true)"; n="${n:-0}"

# Index-then-load (skill #3): full-load only while the ledger is genuinely small;
# past the threshold we switch to index + just-in-time retrieval. The default is
# deliberately LOW (20) because the full ledger rides EVERY turn — ~50 lessons is
# ~5k tokens/turn, which burns a metered plan's budget fast (measured via
# scripts/cogito-budget.sh). In index mode the always-load set (#critical / [I:9-10])
# still prints in full — so the must-know lessons are never deferred — and the rest
# are one `grep` away. Raise COGITO_LOAD_THRESHOLD to go back to full-load.
THRESHOLD="${COGITO_LOAD_THRESHOLD:-20}"
if [ "$n" -le "$THRESHOLD" ]; then
  # --- full-load (unchanged; the safety net) ---
  echo "cogito: brain loaded from $src — $n lessons now in context. Do NOT repeat these:"
  echo "----- COGITO LESSONS  (SYMPTOM -> ROOT CAUSE -> RULE) -----"
  grep '^- ' "$LEDGER"
  echo "----- end COGITO lessons -----"
else
  # --- index mode (just-in-time retrieval) ---
  echo "cogito: brain loaded from $src — $n lessons (index mode; grep for depth)."
  echo "----- ALWAYS-LOAD (critical / severe — these never defer) -----"
  # match the [#critical] TAG, not the bare word (a lesson merely MENTIONING
  # #critical must not always-load — caught 2026-07-03); cap the section so a
  # runaway severe set cannot blow the per-turn budget.
  grep -E '^- .*(\[I:(9|10)\]|\[#critical\])' "$LEDGER" \
    | awk '{n+=length($0)+1; if(n>7000){print "  [severe set over 7000-char budget — rest deferred; run a consolidation pass]"; exit} print}' \
    || echo "  (none flagged critical)"
  echo "----- COGITO LESSONS INDEX  (tag -> count; grep a tag in LESSONS.md for depth) -----"
  grep '^- ' "$LEDGER" | grep -oE '\[#[a-z][a-z-]*\]' | sort | uniq -c | sort -rn | sed 's/^/  /' \
    || echo "  (untagged — lessons exist but carry no tags yet)"
  echo "  $n lessons are not all printed (context-rot guard). To recall depth on a topic:"
  echo "    grep -i '<keyword>' ~/.claude/skills/cogito-protocol/LESSONS.md"
  echo "----- end COGITO INDEX -----"
fi

# --- strategy playbook (ACE): top strategies by proven usefulness ---
PB="$DST/PLAYBOOK.md"
if [ -f "$PB" ] && grep -q '^- \[P' "$PB" 2>/dev/null; then
  echo "----- COGITO PLAYBOOK (top strategies — APPLY these; report use via cogito-learn.sh --bump P###:helpful) -----"
  grep '^- \[P' "$PB" | sed -n 's/.*\[helpful:\([0-9]*\)\].*/\1 &/p' | sort -rn | head -5 | cut -d' ' -f2- \
    | awk '{n+=length($0)+1; if(n>3000) exit; print}'
  echo "----- end COGITO PLAYBOOK ($(grep -c '^- \[P' "$PB") strategies total; grep ~/.claude/skills/cogito-protocol/PLAYBOOK.md for more) -----"
fi
