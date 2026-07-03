# Cogito — Strategy Playbook (what WORKS)

The other half of the brain. The lessons ledger remembers what FAILED (scars);
this file remembers what WORKED (strategies) — with counters proving it keeps
working. Research basis: ACE (arXiv 2510.04618) — a smaller model with an evolved
strategy playbook matched a GPT-4.1-based production agent; the lift came from
accumulating strategies, not just avoiding mistakes.

**Delta discipline (never break it):**
- NEW strategy that visibly worked → APPEND one bullet with a fresh `[P###]` id
  and zeroed counters. Never rewrite the file wholesale (context collapse).
- A loaded bullet HELPED this session → increment its `[helpful:N]` in place.
- A loaded bullet MISLED you → increment its `[harmful:N]` in place.
- Curation (dedup/merge/demote) happens ONLY at consolidation time
  (skill: cogito-consolidate); a demoted bullet MOVES to PLAYBOOK-ARCHIVE.md
  (harmful > helpful = demote candidate), never deleted.

**Format:** `- [P###][#tag][helpful:N][harmful:N] imperative strategy {via:origin}`

## Verification & done-claims
- [P001][#verify][helpful:1][harmful:0] Pick the deterministic done-check BEFORE starting (a command, an HTTP status, a re-read from disk, a test) and paste its output with the claim — "done" without pasted evidence is not done. {via:seed 2026-07-03, distilled from ledger #verify rules}
- [P002][#verify][helpful:0][harmful:0] For web work: prove by logged-out rendered pixels + the asset's own HTTP status + a clean console — never a green build or an owner-session view. {via:seed 2026-07-03}
- [P003][#verify][helpful:1][harmful:0] When a gate/scanner/agent claim drives an irreversible action, re-verify that specific claim with a grounded check first (cmp, diff -rq, curl, pgrep -af, unzip -l) — subagent adjectives are hypotheses. {via:seed 2026-07-03}
## Git & deploy
- [P004][#git][helpful:0][harmful:0] Before merging or rescuing an old branch, diff its FILES against the target (md5 per file + git diff target..branch) — file-level diff is the only content-truth; commit ancestry lies after squash-merges. {via:seed 2026-07-03}
- [P005][#deploy][helpful:0][harmful:0] Before retiring/deleting any deployment or endpoint, enumerate its inbound consumers first (grep sibling repos for its URL/env refs, check API routes) — a public endpoint is a production dependency. {via:seed 2026-07-03}
- [P006][#git][helpful:0][harmful:0] Set the faceless identity as LOCAL git config before the first history-writing op in any cogito-family repo — it covers commit, merge, and rebase at once. {via:seed 2026-07-03}
## Memory & sessions
- [P007][#memory][helpful:1][harmful:0] Two live copies of one file: diff BOTH directions, merge to the superset, write the same merged result to both — never cp one over the other. {via:seed 2026-07-03}
- [P008][#memory][helpful:0][harmful:0] Big input or long task: chunk it and keep a compact running index; re-expand only the chunk the current step needs (working memory = buffer × compression × retrieval). {via:seed 2026-07-03}
## Process
- [P009][#process][helpful:0][harmful:0] State the key assumption + confidence before non-trivial work; below ~80%, ask ONE clarifying question instead of guessing. {via:seed 2026-07-03}
- [P010][#process][helpful:0][harmful:0] Three failed honest tries → stop and surface the blocker with HELP REQUESTED: <action> BECAUSE: <reason> — a precise ask is a success state, not a failure. {via:seed 2026-07-03}
- [P011][#process][helpful:0][harmful:0] Diagnose the LAYER before the logic: transport (egress/proxy/policy) impersonates app errors; a deterministic rejection is never retried, a policy gap is named to the user. {via:seed 2026-07-03}
- [P012][#shell][helpful:1][harmful:0] Stop a process by explicit PID (pgrep pattern, then kill "$PID") or a port check — and feed grep -q via herestring/file, never as the receiving end of a pipeline under pipefail. {via:seed 2026-07-03}
