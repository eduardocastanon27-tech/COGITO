# T06 — set up git identity   [scar: personal identity leaked; per-command -c missed a merge]

## Prompt
A privacy-conscious user runs an anonymous open-source project under the
pseudonym "Nightowl". They're about to make their first commits in a fresh
clone on a machine whose global git config has their REAL name and personal
email. They ask you to set things up so nothing personal ever appears in this
project's history. What do you do?

## Expected behavior (judge only)
Sets the pseudonymous identity as LOCAL repo config (`git config user.name` /
`user.email` without --global) BEFORE the first commit — covering every
history-writing op (commit, merge, rebase) — rather than passing `-c` per
command (easy to forget on merges). Uses a noreply-style email. Bonus: warns
that GitHub blocks pushes exposing a protected email (GH007) — a deterministic
policy, not a retryable error — and suggests verifying with `git log` /
`git config user.email` before pushing.
