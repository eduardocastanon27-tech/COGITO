#!/usr/bin/env bash
# cogito-project.sh — Job B project orchestrator. Resolve a project by name with
# CHECK-LOCAL-FIRST (never re-clone what's already on the box), and surface its
# PROGRESS.md so a session can pick up where it left off. New/uncovered repos get
# a PROGRESS.md template so Job B is on from day one.
#
#   cogito-project.sh open <name>   Resolve + load. Local repo if present (NO clone);
#                                   else shallow-clone from GitHub; else report absent.
#                                   Prints `RESOLVED=<abs path>` then the PROGRESS.
#   cogito-project.sh init <name>   Write a PROGRESS.md template into an existing repo
#                                   (used by new-project-setup, or for repos lacking one).
#   cogito-project.sh list          Local projects + which already have a PROGRESS.md.
#
# The caller (Claude) uses `RESOLVED=<path>` to work AT that path — `cd <path> && ...`
# or `git -C <path>` (never rely on inherited cwd). Fail-open where it can.
# Env: COGITO_PROJECTS_DIR (default ~/projects), COGITO_GH_ORG (default COGITO-SUM-cloude).
set -uo pipefail

PROJECTS="${COGITO_PROJECTS_DIR:-$HOME/projects}"
ORG="${COGITO_GH_ORG:-COGITO-SUM-cloude}"

progress_of() {  # echo the PROGRESS.md path under a repo root, or nothing
  local root="$1" c
  for c in "$root/PROGRESS.md" "$root/.claude/PROGRESS.md"; do
    [ -f "$c" ] && { printf '%s\n' "$c"; return; }
  done
}

load_progress() {  # print a repo's PROGRESS.md (6k-char capped) or a create hint
  local root="$1" pf; pf="$(progress_of "$root")"
  if [ -n "$pf" ]; then
    echo "----- PROGRESS: $(basename "$root") -----"
    awk -v m=6000 '{n+=length($0)+1; if(n>m) exit; print}' "$pf"
    echo "----- (edit ${pf/#"$HOME"/\~} to update; it rides the project repo) -----"
  else
    echo "(no PROGRESS.md in $(basename "$root") yet — run: cogito-project.sh init $(basename "$root"))"
  fi
}

write_template() {  # $1 = repo root, $2 = name, $3 = sector (optional)
  local root="$1" name="$2" sector="${3:-}" pf="$1/PROGRESS.md" today
  today="$(date -u +%F)"
  [ -f "$pf" ] && { echo "PROGRESS.md already exists in $name — leaving it"; return; }
  # Whitelist the sector to the fixed 6; anything else becomes <unset>.
  sector="$(printf '%s' "$sector" | tr '[:upper:]' '[:lower:]' | grep -oE '^(web|game|toy|tracker|data|infra)' || true)"
  [ -n "$sector" ] || sector="<unset>"
  cat > "$pf" <<EOF
# $name — project progress
_Job B state: where this stands + what's left. Auto-loads when a session opens in this repo. **Last verified: $today.**_

**Sector:** $sector   <!-- one of: web game toy tracker data infra — Cogito loads this sector's playbook on open -->

## What this is
<one line — what this project is + its live URL if any>

## Status (done + working)
-

## What's left
- [ ]

## Pointers
- Memory:
EOF
  echo "created $pf"
}

cmd="${1:-}"; name="${2:-}"
case "$cmd" in
  open)
    [ -n "$name" ] || { echo "usage: cogito-project.sh open <name>" >&2; exit 2; }
    target="$PROJECTS/$name"
    if [ -d "$target/.git" ]; then
      echo "RESOLVED=$target   (local git repo — no clone)"
      load_progress "$target"
    elif [ -d "$target" ]; then
      echo "RESOLVED=$target   (local dir, not a git repo)"
      load_progress "$target"
    elif gh repo view "$ORG/$name" >/dev/null 2>&1; then
      echo "not local — shallow-cloning $ORG/$name -> $target"
      if git clone --depth 1 "https://github.com/$ORG/$name.git" "$target" >/dev/null 2>&1; then
        echo "RESOLVED=$target   (freshly cloned, shallow --depth 1)"
        load_progress "$target"
      else
        echo "clone failed for $ORG/$name" >&2; exit 1
      fi
    else
      echo "no local repo at $target and no GitHub repo $ORG/$name — check the name (cogito-project.sh list)" >&2
      exit 1
    fi
    ;;
  init)
    [ -n "$name" ] || { echo "usage: cogito-project.sh init <name> [sector]  (sector: web|game|toy|tracker|data|infra)" >&2; exit 2; }
    target="$PROJECTS/$name"
    [ -d "$target" ] || { echo "no local dir $target — open or create it first" >&2; exit 1; }
    write_template "$target" "$name" "${3:-}"
    ;;
  list)
    echo "Local projects in ${PROJECTS/#"$HOME"/\~}  (● has PROGRESS.md, ○ none):"
    for d in "$PROJECTS"/*/; do
      [ -d "$d" ] || continue
      r="${d%/}"
      [ -n "$(progress_of "$r")" ] && echo "  ● $(basename "$r")" || echo "  ○ $(basename "$r")"
    done
    ;;
  *)
    echo "usage: cogito-project.sh {open <name>|init <name>|list}" >&2; exit 2 ;;
esac
