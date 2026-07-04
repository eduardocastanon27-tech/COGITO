#!/usr/bin/env bash
# cogito-progress.sh — Job B write-back: keep a project's PROGRESS.md fresh AND
# durable. Appends a stamped entry and/or refreshes the "Last verified" date,
# then commits ONLY PROGRESS.md to the project repo LOCALLY. It NEVER pushes —
# pushing stays a deliberate, gated act (append-only lessons auto-merge; this
# does not). NOT edit-gated: Job B status is frequent and low-stakes, and gating
# it behind a human tap is exactly what lets "what's left" go silently stale.
#
# Usage:
#   cogito-progress.sh "one-line update"   # append to ## Log + bump stamp + commit
#   cogito-progress.sh --touch             # just bump the Last-verified stamp + commit
#   cogito-progress.sh --flush             # commit ONLY if PROGRESS.md is dirty (Stop hook)
#   (add  -C <repo>  to target a repo other than the current session's)
#
# Kill: COGITO_GLOBAL=0  or  touch ~/.claude/cogito/DISABLED. Fail-open always:
# a write-back problem must never break a session or touch anything but PROGRESS.md.
set -uo pipefail
[ "${COGITO_GLOBAL:-1}" = "0" ] && exit 0
[ -f "$HOME/.claude/cogito/DISABLED" ] && exit 0

repo="${CLAUDE_PROJECT_DIR:-$PWD}"
mode="log"; msg=""
while [ $# -gt 0 ]; do
  case "$1" in
    -C)      repo="${2:-$repo}"; shift 2 2>/dev/null || shift;;
    --touch) mode="touch"; shift;;
    --flush) mode="flush"; shift;;
    --*)     shift;;                        # ignore unknown flags (fail-open)
    *)       msg="$1"; mode="log"; shift;;
  esac
done

quiet() { [ "$mode" = "flush" ]; }         # the Stop-hook path stays silent

root="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)"
[ -n "$root" ] || { quiet || echo "cogito-progress: $repo is not a git repo — skipped"; exit 0; }

# Never manage Cogito's own repo — it uses ACTIVE-MISSION.md, not PROGRESS.md.
if git -C "$root" remote -v 2>/dev/null | grep -qiE 'COGITO-SUM-cloude/COGITO(\.git)?'; then
  quiet || echo "cogito-progress: inside COGITO repo — use ACTIVE-MISSION.md"; exit 0
fi

pf=""
for c in "$root/PROGRESS.md" "$root/.claude/PROGRESS.md"; do [ -f "$c" ] && { pf="$c"; break; }; done
[ -n "$pf" ] || { quiet || echo "cogito-progress: no PROGRESS.md in $(basename "$root")"; exit 0; }

today="$(date -u +%F)"

# 1. Append the update line under a '## Log' section (create it once if missing).
if [ "$mode" = "log" ] && [ -n "$msg" ]; then
  grep -q '^## Log' "$pf" 2>/dev/null || printf '\n## Log\n' >> "$pf"
  printf -- '- %s — %s\n' "$today" "$msg" >> "$pf"
fi

# 2. Refresh the 'Last verified:' stamp (log/touch only; flush never edits).
if { [ "$mode" = "log" ] || [ "$mode" = "touch" ]; } && grep -qi 'last verified:' "$pf" 2>/dev/null; then
  tmp="$(mktemp)" && awk -v d="$today" '
    { if ($0 ~ /[Ll]ast [Vv]erified:/) sub(/[Ll]ast [Vv]erified:[^*_<]*/, "Last verified: " d); print }' \
    "$pf" > "$tmp" 2>/dev/null && mv "$tmp" "$pf" 2>/dev/null || true
fi

# 3. Commit ONLY PROGRESS.md, locally, faceless identity, NEVER push. Skip if clean.
if [ -n "$(git -C "$root" status --porcelain -- "$pf" 2>/dev/null)" ]; then
  git -C "$root" add -- "$pf" 2>/dev/null || true
  if git -C "$root" -c user.name="Cogito" \
        -c user.email="291881939+COGITO-SUM-cloude@users.noreply.github.com" \
        commit -q -m "cogito: progress update ($today)" -- "$pf" 2>/dev/null; then
    quiet || echo "cogito-progress: committed $(basename "$pf") in $(basename "$root") (local only, not pushed)"
  fi
else
  quiet || echo "cogito-progress: $(basename "$pf") already up to date — nothing to commit"
fi
exit 0
