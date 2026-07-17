# Cogito × Hermes-native learning — the merge (built 2026-07-10)

The goal: make the setup *better than the marketed Hermes* by giving each memory
store a clean lane instead of blurring everything into one bucket (or one cloud
service like Honcho, which was deliberately skipped for privacy + cost).

## Three lanes

| Lane | Owns | Where it lives | Fed by |
|---|---|---|---|
| **WHAT** (technical) | faceless engineering lessons, by sector | Cogito ledger `skills/cogito-protocol/LESSONS.md` + sector playbooks | `cogito-learn.sh` (auto-sector-tagged), the distiller → review queue |
| **WHO** (person) | who Eduardo is — situation, working style, state, focus | `~/.hermes/person-card.md` (on-box, injected into Hermes's brain by the proxy every turn; never shipped) | a human, from the distiller's `person-card-updates.md` proposals |
| **HOW** (procedure) | a proven strategy turned into an executable skill | a real `SKILL.md` | `cogito-consolidate.sh graduate` surfaces proven playbook bullets to author |

## The router (distiller)
`~/.hermes/scripts/cogito_distill.py` (weekly timer `hermes-cogito-distill.timer`,
**user-enabled**) reads recent journals + reflections, makes ONE pinned model call,
and PROPOSES to two review queues — nothing auto-enters canon or the person-card:
- technical → `~/.hermes/cogito-distill-review.md` (promote via `cogito-learn.sh`)
- person → `~/.hermes/person-card-updates.md` (fold into `person-card.md` by hand)

## Guardrails
- **Faceless boundary:** `cogito-learn.sh` warns if a technical lesson names Eduardo
  (a person fact belongs in the WHO lane) — the critical #comms rule, mechanized.
- **Human-gated:** the distiller proposes; a human promotes. No new privileged
  always-on `claude -p` loop is auto-enabled (the autonomy-consent boundary).
- **No divergence:** the person-model is ONE place (`person-card.md`); Honcho stays
  off so two person-stores can't drift (the brain-copies-diverge scar).
- **Lean:** person-card ~1KB injected every turn (attuned overseer); distiller is
  ~1 model call/week; nothing runs on the 2.78GB box that it can't afford.

## Why not the marketed all-in-one
Honcho would ship sensitive person-context to a third-party cloud on a second
metered brain to rebuild a model Eduardo already has locally. Specializing the
stores keeps WHO private + on-box, keeps WHAT faceless, and turns HOW into real
skills — the same learning loop, but private, cheap, and box-safe.
