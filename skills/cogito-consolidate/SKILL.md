---
name: cogito-consolidate
description: Ledger maintenance for Cogito's lessons — keep the always-loaded set lean without losing anything, two ways. (1) CONSOLIDATE — cluster by tag, merge/supersede redundant lessons into fewer higher-tier rules. (2) DECAY — archive cold, explicitly-low-importance lessons (refresh-on-use keeps useful ones alive). Both MOVE raw lines into LESSONS-ARCHIVE.md with provenance (never delete) and end with the same conservation gate. Use when the active ledger (skills/cogito-protocol/LESSONS.md) passes ~60 lessons, after a severe (I:9-10 / #critical) lesson lands, or when the user says "/consolidate", "decay/prune/tidy/compress the ledger", "archive old lessons". The companion to cogito-protocol §4b. Conservative by design — when in doubt, keep.
---

# Cogito — Ledger Maintenance: Consolidate (`/consolidate`) + Decay

The lessons ledger loads at every session start — in full while small, and in
index mode above the threshold (`COGITO_LOAD_THRESHOLD`, default 20: the
`#critical`/`[I:≥9]` set + a tag index, the rest deferred to grep). Even in
index mode a bloated ledger dilutes the signal — "context rot". A
consolidation pass keeps the always-loaded set small **without losing detail**:
it compiles clusters of related raw lessons into a few higher-tier rules and
parks the raw lines in an archive the loader does not read.

This is mem0's ADD / UPDATE / MERGE / NOOP and Soar's chunking applied to a
plain-text causal ledger, with the survey's safety rule on top: **archive, don't
delete; keep a probation buffer; the git diff is the validation layer.**
(Rationale + sources: `docs/projects/06-cogito-upgrade-roadmap.md`, item #4/#5.)

## When it runs (trigger)
- The active ledger passes ~60 `- ` lessons (the helper prints the count), **or**
- a severe lesson lands (importance `[I:9]`/`[I:10]` or `#critical`), **or**
- the user asks for it.

Below the trigger, do **not** force a pass — merging a small ledger destroys
specificity for no benefit. Exercising it as a dry run is fine; a real merge is
not.

## The procedure

1. **Pre-flight — see the shape.** Run `scripts/cogito-consolidate.sh report`.
   It prints the active count vs. the trigger, the tag clusters (a cluster of 3+
   is a merge candidate), how many lessons are untagged (tag those first — tags
   are the retrieval index), and the severe lessons that must never be merged
   away.

2. **Respect probation.** The most recent ~5 lessons are exempt. A fresh lesson
   has not yet proven it recurs; compressing it into a rule too early bakes in
   noise. Merge only mature, repeated lessons.

3. **Decide per cluster (mem0 taxonomy).**
   - **NOOP** — distinct, still load-worthy, or on probation → leave it. This is
     the default. When two lessons look similar but encode *different* causes,
     keep both.
   - **MERGE / chunk** — 3+ lessons that are the same recurring fix → write ONE
     higher-tier rule that names the pattern and cites how many raw lines it
     compiles (provenance).
   - **SUPERSEDE** — a newer/sharper lesson strictly contains an older one → keep
     the sharper rule, archive the old.
   Keep every rule in the `SYMPTOM -> ROOT CAUSE -> RULE` shape and tag it. Never
   merge away a `#critical` / `[I:9-10]` lesson.

4. **Move, never delete.** For every raw line a merge removes from `LESSONS.md`,
   cut it **verbatim** into `LESSONS-ARCHIVE.md` under a dated block headed by the
   active rule that now supersedes it. (Verbatim matters: the gate in step 5
   matches the moved line against the removed line exactly.)

5. **Prove nothing was lost (the gate).** Run
   `scripts/cogito-consolidate.sh verify`. It checks that every `- ` line removed
   from the active ledger reappears verbatim in the archive, and exits non-zero
   if any line is unaccounted for. Do not commit until it passes. (This is the
   §5b runnable verification gate applied to memory surgery.)

6. **Review the diff, then commit.** `git diff` is the real validation layer for
   over-merge: read it as a stranger would and confirm no causal detail was
   flattened. Commit faceless (`Cogito <291881939+COGITO-SUM-cloude@users.noreply.github.com>`) with a
   message naming what merged into what and the before/after count.

## Decay — archive cold, low-value lessons (helper: `scripts/cogito-decay.sh`)

Consolidation removes *redundancy*; decay removes *staleness*. Same archive, same
gate — only the trigger differs. A lesson decays when it stops earning its place
in the always-loaded set.

The rule (ACT-R activation ≈ recency × importance, with refresh-on-recall): a
lesson is an archive candidate only when **all** hold —
- it is **explicitly low-importance** (`[I:N]`, N ≤ 3). *Unscored lessons are
  kept* — never assume a lesson is low-value just because no one scored it; the
  safety floor is that unscored lines never decay by default.
- it is **cold**: its recency — the latest `[seen:]`/`[d:]` stamp in the line,
  else the line's git-blame date — is older than ~90 days.
- it is **off probation** (not in the most-recent ~5) and **not** `#critical` /
  `[I:≥9]` (those never decay).

**Refresh-on-use.** When you actually apply a lesson, stamp it:
`scripts/cogito-decay.sh touch "<a few words of the lesson>"` writes
`[seen:TODAY]` and resets its coldness. Use keeps a lesson alive; only the
genuinely unused-and-minor ones fall away.

**Procedure.** Run `scripts/cogito-decay.sh report` to list candidates with their
age and importance. For each you agree has decayed, MOVE it verbatim into
`LESSONS-ARCHIVE.md` under a `decayed: cold + low-value` block, then run
`scripts/cogito-consolidate.sh verify` (the same conservation gate) and review the
diff before committing. Nothing is deleted; git keeps the history.

## The one bias to remember
Over-pruning is the failure mode, not under-pruning — for both consolidation and
decay. A ledger that is slightly too long costs a little context; a rule that
silently swallowed a distinct cause, or an archived lesson that was still earning
its place, costs a repeated scar. **When in doubt, keep (NOOP).**
