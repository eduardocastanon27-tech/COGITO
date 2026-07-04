---
name: cogito-shell
description: DRAFT (not indexed). Auto-scaffolded from 12 recurring [#shell] lessons. NOT a real skill until it works in 2+ real sessions and is added to skills/INDEX.md.
---

# shell — draft skill (UNVERIFIED, not indexed)

Scaffolded because 12 lessons carry [#shell] — a recurring problem domain with no covering skill. The RULE clauses distilled from those lessons:

- always prefix Bash with an absolute `cd /home/user/<repo> &&` (or use absolute paths / git -C); never rely on inherited cwd.
- end grep option parsing with `--` for data that may begin with "-", and always test a gate's PASS and FAIL paths before trusting it.
- a command-guard must remove quoted SPANS (not chars) so in-string mentions vanish, and its selftest must include a commit/echo that mentions the very commands it blocks.
- wait for a freshly-started local server with `curl --retry N --retry-connrefused --retry-delay 1` (curl absorbs the startup race with no sleep), and stop it by explicit `kill "$PID"` captured from `&` — never a self-matching `pkill -f`.
- commit or stash the work-in-progress BEFORE any reset --hard / destructive self-test, so the test cannot eat the change it is meant to verify.
- never derive a script repo-root by hardcoded ../.. depth; use git -C "$(dirname "$0")" rev-parse --show-toplevel, and test hooks with the env var BOTH set and unset.
- never pkill -f a pattern that can match the kill command itself; stop by explicit PID (pgrep then kill "$PID") or a port check, and consult the relevant lesson before destructive/process ops. Now also enforced by scripts/cogito-guard.sh.
- a shell fallback ending in `&& pwd` must never be chained after `||` on one line; set the primary, then `[ -n "$x" ] || x="$(fallback)"`.
- never put grep -q at the receiving end of a pipeline under pipefail — feed it via herestring/file (grep -qxF -- "$line" <<< "$data"); and a gate whose failure set CHANGES between identical runs is reporting its own bug, not yours. {via:session 2026-07-03 cogito upgrade}
- chmod +x every new script the moment it is created, and when a fail-open guard protects an optional step, verify the step actually FIRES once (the budget tool caught it: 'not present' for a file that existed)
- when purging a whole scaffold dir, follow git rm with rm -rf <dir> (or git clean) and re-grep the working tree, since git rm only removes TRACKED files.
- never use gawk-only awk (IGNORECASE/gensub/asort) in cogito scripts; use explicit [Ll] char classes, and verify a text transform by READING THE FILE BACK, never by exit-0 or 'it committed'.

## Graduation gate (do not skip)
Do NOT add this to skills/INDEX.md until it has demonstrably worked in 2+ INDEPENDENT real sessions (Voyager's verified-skill rule, strengthened because human-judged success is noisier than a code-execution check). Until then it is a hypothesis, not procedural memory. To graduate: flesh out the procedure, prove it live twice, move it under skills/, then add the INDEX.md line.
