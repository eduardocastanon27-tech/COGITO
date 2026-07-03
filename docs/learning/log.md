# Cogito — Learning Log

The durable record of what the user is learning, so progress is never lost to a
forgotten session. Each entry: the idea in plain words, its real name, one way to
use it, and a recap cue for next time. We revisit these on purpose — that is how
we beat forgetting.

We also **schedule** the reviews (spaced repetition, a plain **Leitner ladder** —
box 1..6 → revisit in 1/3/7/16/35/90 days): each lesson carries
`box:N due:YYYY-MM-DD rev:YYYY-MM-DD`. Pass → up one box; fail → back to box 1.
Human-auditable at a glance, no floating-point memory state. (The earlier FSRS-5
scheduler was over-engineering for a small log — roadmap #7's own ruling — and never
recorded a grade; downgraded 2026-07-03.) At session start the most-overdue lesson's
recap cue is surfaced automatically. `scripts/cogito-review.sh due` lists what's due;
`… grade N pass|fail` records a review. Legacy `S=/D=` lines still parse — they map
to the nearest box on the next grade. (`box:0` = seeded, not yet in rotation.)

**Field in focus:** Neuroscience (started 2026-06-13) — current focus: **nootropics & brain chemistry** (proven vs. hyped).
**How the user learns best:** by *deriving it with hints* — give a nudge + a question, let him reason it out (don't hand over the answer). Record **observations, not labels**.
**Lesson definitions** (the reusable "meaning" objects, learner-agnostic) live in `docs/learning/lessons/`; this log is the per-learner **progress** record.

---

## Lesson 1 — You remember what you work for
- **Plain version:** Struggling to recall or figure something out is what makes a
  memory stick. Being told something once, passively, barely leaves a mark.
- **Picture:** A memory is a trail through tall grass. *Re-reading* = looking at
  the trail. *Recalling it yourself* = walking it — and only walking deepens the
  path. The struggle is what carves the memory in.
- **Real name:** the **testing effect** / **retrieval practice** (part of a bigger
  idea called *desirable difficulty*).
- **Use it:** To learn anything, don't just re-read it — **close it and try to
  recall it.** The effort is the point. (This is why Cogito hints instead of
  telling: your effort is the chisel.)
- **Recap cue (ask next time):** "Trail in the grass — what makes the path deeper,
  looking at it or walking it?"
- **Status:** ✓ Derived by the user (2026-06-13) — chose "B, the struggle one" and
  reasoned it out. Earned, not just told.
- **Review:** box:2 due:2026-06-18

---

## Lesson 2 — Why a tired brain can't learn *(seeded, for when fresh)*
- **Where it came from:** the user's own observation — *"I was extremely tired and
  my brain was slowing down."* A real insight, spotted in themselves.
- **Question to explore next:** if struggle carves memory, why does a *tired* brain
  carve so poorly — and what is sleep actually *for*?
- **Where we're headed (don't reveal — let them derive):** a tired brain encodes
  weakly, and sleep is when the day's faint trails get reinforced. So rest isn't
  lazy — it's literally part of learning.
- **Review:** box:0 (seeded — enters rotation once taught/derived)

---

## Lesson 3 — Knowing a rule isn't the same as following it
- **Where it came from:** today, real and unflattering. I had the exact rule loaded
  ("don't use a self-matching `pkill`") and broke it anyway — then applied it correctly
  the second time, once it was cued right at the moment of acting.
- **Plain version:** a stored rule is just an *input* to the decision, not an enforcer —
  nothing makes it fire. In the moment, the *output* (the decision) can skip it: either it
  never surfaced, or something else looked better. First time here, it never surfaced;
  the second time, the failure forced a review that pulled the rule back up.
- **The upgrade (so a failure isn't required first):** pre-bind the rule to its trigger —
  "WHEN I'm about to stop a server → THEN kill by PID." A cue glued to the moment fires
  *before* the slip instead of waiting for trial-and-error to surface it.
- **Real names:** availability vs. accessibility (Bjork) — stored ≠ reachable when needed;
  the knowing–doing gap; implementation intentions (if–then planning).
- **Use it:** for any rule you keep breaking, write it as "when X → I do Y," tied to the
  visible trigger, not as a fact filed away.
- **Recap cue (ask next time):** "Fire extinguisher in the basement vs. bolted by the
  stove — what makes a known rule actually fire when it's needed?"
- **Status:** ✓ Derived by the user (2026-06-14). Their words: a rule "is just an input …
  the true decision is in its output," with "no actual enforcer"; the second time worked
  because the failure made it "review its knowledge and [find] there was a rule for it."
  Reached the availability/accessibility idea on their own.
- **Review:** box:1 due:2026-06-15

---

## Lesson 4 — Caffeine doesn't add energy, it hides the tiredness
- **Plain version:** Tiredness is a chemical (**adenosine**) piling up the longer you're
  awake — the more it stacks, the foggier you feel; that pile *is* the signal. Caffeine
  doesn't add energy or remove the chemical — it just plugs the "parking spots" so the
  signal can't land. The adenosine keeps building underneath; when the caffeine wears off
  it all docks at once — the **crash**. Only **sleep** actually clears it.
- **Picture:** adenosine = sludge filling parking spots, each filled spot dims the room.
  Caffeine = a fake car in the spots so the sludge can't dock — but it keeps piling in the
  corner; caffeine leaves, it floods every spot at once and the room goes dark fast. Sleep
  = a wave that clears all the spots.
- **Real name:** **adenosine** (and its receptors — the "parking spots"); caffeine is a
  *blocker* of those receptors, not a booster.
- **Use it:** judging "brain boosters" — caffeine borrows alertness from later and repays
  it as a crash; the strongest lever (sleep) is free. That's the proven-vs-hyped lens.
- **Recap cue (ask next time):** "Caffeine and the parking spots — is it adding energy or
  just blocking the signal, and what's the only thing that clears the buildup?"
- **Status:** ✓ Derived by the user (2026-06-15) — reasoned out, unprompted, that caffeine
  blocks the tiredness *signal* and that the backed-up "brain sludge" floods in as the
  crash once it wears off (the bonus insight). Supplied to complete it: the name
  (adenosine) and that **sleep** is what clears it — confirm those at first review.
- **Review:** box:1 due:2026-06-16
