---
name: cogito-council
description: Multi-perspective deliberation ("the council") — fan a hard, high-stakes question out to parallel Claude panelists with deliberately distinct lenses, have a judge compare answers (consensus, contradictions, gaps, blind spots), then synthesize. Costs several agent calls — not for everyday questions. Triggers — "/council", "convene the council", "get multiple opinions", "deliberate on this", "fusion this".
---

# Cogito Council (free, Claude-only multi-model deliberation)

OpenRouter's **Fusion** ensembles *different companies'* models (Claude + GPT +
Gemini) plus a judge. We can't do cross-provider for free — but the *structure*
(panel → judge → synthesize) carries most of the gain, and we can run it today
with Claude sub-agents at zero extra cost. This is the **free council**: the same
shape as Fusion, so when money or a stronger free model arrives, it swaps in
without changing how you work (§Upgrade path).

This is not new machinery — it is the pattern this repo already runs (parallel
research agents; the `cogito-reviewer` decorrelating a check), named and made
repeatable.

## When to convene it
- High-stakes or ambiguous questions where one answer isn't enough: research,
  expert critique, "compare and contrast", architecture/design calls — anything
  where the cost of being wrong outweighs a few extra agent calls.
- **Not** for everyday/tactical questions — a council spends several sub-agent
  calls. One good direct answer beats a needless council.

## The procedure
1. **Sharpen the question.** State it in one or two checkable sentences plus what
   a good answer must cover. A vague prompt produces a noisy panel.
2. **Convene the panel — independent + diverse.** Spawn 3–5 panelists **in a
   single message** so they run in parallel — each a `general-purpose` agent given
   a DISTINCT lens, told to answer **independently** and not assume other agents
   exist. All share one base model, so diversity comes from the lenses, not the
   weights:
   - rotate lenses like **pragmatist / skeptic / first-principles / domain-expert
     / contrarian**, or roles natural to the question;
   - vary **effort** (a couple deep, one fast) and framing;
   - **ground the research/domain lens in the live web:** when the question turns on
     current facts (prices, versions, what's true *now*, who said what), the
     research/domain-expert panelist MUST use its built-in web search/fetch tools and
     cite sources — a `general-purpose` agent already has them, and it's free (no
     OpenRouter paid web plugin). An un-searched "expert" answer on a time-sensitive
     question is a guess; make that lens earn its name. Stale-fact risk is itself a
     blind spot the panelist should name when it couldn't verify.
   - require each to ground its claims (a check, a source, a real constraint) and
     to name its own confidence and blind spots;
   - **always add the non-Claude voice:** pipe the sharpened question through
     `scripts/cogito-openrouter.sh` and include its reply as one panelist — a free
     non-Claude model, the decorrelated juror that cures "one voice in triplicate".
     It exits cleanly with no key set, so it is always safe to call. For a
     machine-mergeable panel, call it with
     `--schema skills/cogito-council/panelist.schema.json` so its reply is JSON in the
     shared panelist shape (§Structured output). **Capture which
     model actually answered** (the script prints `answered by <model>` on stderr):
     free models get silently rate-limited and swapped down the fallback chain, and
     the council must never mistake the fallback for the intended voice.
3. **Judge — don't average.** Hand all panel answers to the **cogito-judge**
   subagent (or, until it has loaded, a `general-purpose` proxy carrying the judge
   role). It returns the Fusion-style comparison as a **JSON verdict** (the schema in
   `.claude/agents/cogito-judge.md`): **consensus** (treat as higher-confidence),
   **contradictions**, **coverage gaps**, **unique insights**, **blind spots none
   caught**, and a `recommended_synthesis` — machine-readable so step 4 folds it in
   without re-parsing prose.
4. **Synthesize + verify.** Write the final answer from the judge's analysis: lead
   with consensus, surface the live contradictions honestly, fold in the best
   unique insight, address the blind spots. Verify any grounded claim (§5b) before
   presenting it as fact. **Note which non-Claude model actually answered** (or that
   the voice was unavailable), so a silent fallback is never mistaken for the
   intended voice.

## Distinctness is the whole game (the Claude-only caveat)
One model answering five times helps only if the five are genuinely independent
and differently aimed. Enforce it: don't let panelists see each other, give each a
real lens, ask each for its dissent and its uncertainty. A council that converges
because everyone framed the question the same way is theatre — the value is in the
disagreement the judge can then weigh.

**Decorrelate the judge too.** The judge shares the panel's base model, so it can
inherit the same blind spots. When you can, run the judge on a DIFFERENT model than
the panel — a different Claude model now (pass `model:` when spawning `cogito-judge`),
a non-Claude model once a key exists. A decorrelated judge is the cheapest way to
catch the "one voice in triplicate" the panel cannot see in itself.

## Structured output (machine-mergeable panel)
A council loses value when the judge has to re-parse five differently-shaped prose
blobs. Give the whole panel ONE shape so the judge weighs fields, not formatting:

- **Panelists → the panelist schema** (`skills/cogito-council/panelist.schema.json`):
  `lens, answer, key_claims, grounding[], confidence, blind_spots[]`. Tell each
  Claude panelist to return exactly that JSON object; the non-Claude voice returns it
  natively when called with `--schema skills/cogito-council/panelist.schema.json`
  (OpenRouter `response_format: json_schema`). Free models that can't do structured
  output simply error and the script falls down the chain — so the panel degrades, it
  never breaks.
- **Judge → the judge schema** (in `.claude/agents/cogito-judge.md`):
  `consensus[], contradictions[], coverage_gaps[], unique_insights[], blind_spots[],
  recommended_synthesis, confidence, decorrelation_note`. The judge reads the
  panelists' structured fields directly (e.g. compares their `grounding`), and step 4
  reads `recommended_synthesis` without parsing prose.

The shapes are deliberately Fusion's: when you upgrade to a real cross-provider panel
later, the same two schemas carry over unchanged.

## Upgrade path (→ real OpenRouter Fusion, later)
When a paid OpenRouter key — or a strong free non-Claude model — is available,
replace one or more panelists with a call to `openrouter/fusion` (or a specific
GPT/Gemini model); the judge and synthesis steps are unchanged.

**Now wired (free tier):** `scripts/cogito-openrouter.sh` calls a free non-Claude
model, reading the key from the `$OPENROUTER_API_KEY` environment secret — never
argv, never a file. Its default is a **fallback chain** that prefers Hermes 3
(`nousresearch/hermes-3-llama-3.1-405b:free`, the user's pick) and falls through to
other free models when that is rate-limited — so the script reports `answered by
<model>` on stderr and the synthesis must surface it (the intended voice can be
silently swapped for a fallback). This is **now part of the standard procedure**
(step 2): its answer goes to `cogito-judge` alongside the Claude panelists as the
decorrelated voice that cures "one voice in triplicate". With no key set it exits
cleanly and the council stays Claude-only — so it is always safe to call. Phase 3 (run a
panel of local models on your own machine) needs stronger hardware but the
procedure is identical. The council is built so *how you use it* never changes as
the panel behind it gets stronger.
