#!/usr/bin/env bash
# Cogito Stop hook — save the brain durably at the end of a turn.
#
# Why: a session's NEW lessons / mission edits can sit uncommitted and be lost
# when the ephemeral container is reclaimed (the highest-frequency recorded pain:
# forked ledgers/branches, stale resume). This captures them the moment a turn
# ends so they survive — committed and pushed to the CURRENT BRANCH.
#
# Auto-pushes the brain to main (FF-only) at session end — the user EXPLICITLY
# enabled this on 2026-06-15 ("turn auto push on"). It performs a clean
# fast-forward only: never force, never clobber; a diverged/raced main is left
# untouched and reported. Revert to branch-only with COGITO_CONVERGE_TO_MAIN=0,
# or turn the hook off entirely with COGITO_AUTO_CONVERGE=0.
#
# Deliberately narrow and safe:
#   - BRAIN FILES ONLY (never sweeps code or other working changes)
#   - commits + pushes to the current branch (durable); main is opt-in + FF-only
#   - faceless identity; non-fatal (a Stop hook must never break the session)
#   - kill switch:  export COGITO_AUTO_CONVERGE=0
#   - branch-only:  export COGITO_CONVERGE_TO_MAIN=0   (main auto-push is ON by default; FF-only)
#   - safe testing: export COGITO_CONVERGE_DRYRUN=1    (report only; no commit/push)
set -uo pipefail   # NOT -e: never hard-fail the session

[ "${COGITO_AUTO_CONVERGE:-1}" = "0" ] && exit 0

REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$REPO" 2>/dev/null || exit 0
command -v git >/dev/null 2>&1 || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

MAIN_BRANCH="${COGITO_MAIN_BRANCH:-main}"
DRYRUN="${COGITO_CONVERGE_DRYRUN:-0}"
TO_MAIN="${COGITO_CONVERGE_TO_MAIN:-1}"   # ON: user opted in 2026-06-15 ("turn auto push on"); FF-only. =0 -> branch-only.
BRAIN_PATHS=(
  "skills/cogito-protocol/LESSONS.md"
  "skills/cogito-protocol/LESSONS-ARCHIVE.md"
  "skills/cogito-protocol/PLAYBOOK.md"
  "skills/cogito-protocol/PLAYBOOK-ARCHIVE.md"
  "docs/ACTIVE-MISSION.md"
)

# what changed? (modified / staged / untracked — porcelain catches all states)
changed=()
for p in "${BRAIN_PATHS[@]}"; do
  [ -e "$p" ] || continue
  [ -n "$(git status --porcelain -- "$p" 2>/dev/null)" ] && changed+=("$p")
done
[ "${#changed[@]}" -eq 0 ] && exit 0   # nothing to save — silent

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"

# Fetch main up front (used by the dry-run report and the brain-only converge below).
if [ "$TO_MAIN" = "1" ]; then git fetch -q origin "$MAIN_BRANCH" 2>/dev/null || true; fi

if [ "$DRYRUN" = "1" ]; then
  printf 'cogito[dryrun]: would commit %d brain file(s) on %s: %s\n' \
    "${#changed[@]}" "$branch" "$(printf '%s ' "${changed[@]}")"
  printf 'cogito[dryrun]: converge BRAIN-ONLY to main -> enabled=%s\n' "$TO_MAIN"
  exit 0
fi

# commit ONLY the brain paths — never other work in the tree. Author = the repo
# owner's GitHub no-reply (291881939+COGITO-SUM-cloude) so contributions credit the
# owner. (The old "cogito@users.noreply.github.com" wasn't faceless — it matched an
# UNRELATED real account that owns the username "cogito".)
GIT_AUTHOR_NAME="Cogito"    GIT_AUTHOR_EMAIL="291881939+COGITO-SUM-cloude@users.noreply.github.com" \
GIT_COMMITTER_NAME="Cogito" GIT_COMMITTER_EMAIL="291881939+COGITO-SUM-cloude@users.noreply.github.com" \
  git commit -q --no-verify --only -m "cogito: auto-save brain [stop-hook]" -- "${changed[@]}" 2>/dev/null \
  || exit 0   # nothing actually committed -> bail quietly

git push -q origin "HEAD:$branch" 2>/dev/null || true   # durable on the branch

synced="branch '$branch' (durable; say \"update main\" to make it canonical)"

# Converge to main — BRAIN FILES ONLY, never the whole branch HEAD. Pushing HEAD to
# main once let a withheld non-brain commit parked on the branch ride along (see the
# [#git][#memory] lesson). So instead of `git push HEAD:main`, synthesise a commit =
# origin/main's tree with ONLY the brain paths replaced by their just-committed
# blobs, parented on origin/main (a true fast-forward), and push that. Built in a
# throwaway index so the real working tree / HEAD are never touched; non-force so a
# raced main fails safe; faceless author.
if [ "$TO_MAIN" = "1" ]; then
  base="$(git rev-parse -q --verify "origin/$MAIN_BRANCH" 2>/dev/null || true)"
  if [ -n "$base" ]; then
    tmpidx="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/cogito-converge.$$")"
    ok="yes"
    GIT_INDEX_FILE="$tmpidx" git read-tree "$base" 2>/dev/null || ok="no"
    # Walk EVERY brain path (not just this turn's commits): take HEAD's version of any
    # that differs from main. Works for appends (LESSONS) AND edits (ACTIVE-MISSION) —
    # an earlier append-only guard wrongly stranded edited files — and also flushes a
    # brain file already committed on the branch but not yet on main. We overwrite from
    # HEAD because a session loads the brain from main then edits/appends, so HEAD is
    # the up-to-date superset; a main that moved since the fetch is rejected by the
    # non-force push below, not clobbered.
    for p in "${BRAIN_PATHS[@]}"; do
      [ "$ok" = "yes" ] || break
      blob="$(git rev-parse -q --verify "HEAD:$p" 2>/dev/null || true)"
      [ -n "$blob" ] || continue                                                    # not in HEAD — skip
      [ "$blob" = "$(git rev-parse -q --verify "$base:$p" 2>/dev/null || true)" ] && continue  # same as main — skip
      mode="$(git ls-tree HEAD -- "$p" 2>/dev/null | awk '{print $1; exit}')"
      [ -n "$mode" ] || mode=100644
      GIT_INDEX_FILE="$tmpidx" git update-index --add --cacheinfo "$mode,$blob,$p" 2>/dev/null || ok="no"
    done
    newtree="$(GIT_INDEX_FILE="$tmpidx" git write-tree 2>/dev/null || true)"
    basetree="$(git rev-parse -q --verify "$base^{tree}" 2>/dev/null || true)"
    rm -f "$tmpidx" 2>/dev/null || true
    if [ "$ok" = "yes" ] && [ -n "$newtree" ] && [ "$newtree" != "$basetree" ]; then
      newcommit="$(GIT_AUTHOR_NAME="Cogito" GIT_AUTHOR_EMAIL="291881939+COGITO-SUM-cloude@users.noreply.github.com" \
                   GIT_COMMITTER_NAME="Cogito" GIT_COMMITTER_EMAIL="291881939+COGITO-SUM-cloude@users.noreply.github.com" \
                   git commit-tree "$newtree" -p "$base" \
                   -m "cogito: converge brain to main [stop-hook]" 2>/dev/null || true)"
      [ -n "$newcommit" ] \
        && git push -q origin "$newcommit:$MAIN_BRANCH" 2>/dev/null \
        && synced="$MAIN_BRANCH (brain-only, opt-in)"
    fi
  fi
fi

printf 'cogito: brain saved -> %s (%d file[s])\n' "$synced" "${#changed[@]}"
exit 0
