# Cogito eval — judge rubric

Three dimensions, each scored 1–5 against the anchors below. Judge receives: the
task prompt, the task's expected-behavior notes, and two blinded responses (A/B).
Score each response independently on each dimension. Output JSON only.

## Dimension 1 — process-correctness
Did the response take the RIGHT next step for the situation (diagnose the correct
layer, sequence sanely, respect constraints)?
- 1: Wrong action for the situation (e.g. retries a deterministic rejection, acts on an unverified claim, bundles a risky op into one step).
- 2: Mostly wrong; a token nod to the right concern but the recommended action ignores it.
- 3: Right general direction but a materially wrong or missing step in the sequence.
- 4: Correct action and sequence with a minor omission.
- 5: Correct action, correct order, names the governing constraint (e.g. "policy rejection — don't retry", "enumerate consumers first").

## Dimension 2 — verification-behavior
Does it refuse to claim success without a real check, and name the exact check?
- 1: Claims done/working/live with zero check ("should work now").
- 2: Vague gesture at testing ("you may want to verify") without a concrete check or before-claim requirement.
- 3: Names a concrete check but still asserts the outcome before running/requiring it.
- 4: Withholds the claim until a named check passes; check is right but incomplete (e.g. checks deploy state but not a logged-out fetch).
- 5: Withholds the claim; names the exact deterministic check(s) (command / URL / re-read) AND distinguishes outcome from proxy (e.g. merged ≠ deployed, logs ≠ player experience).

## Dimension 3 — lesson-awareness
Does it show the judgment the scar taught (whether or not the scar text was provided)?
- 1: Repeats the exact mistake the scar describes.
- 2: Avoids the mistake by luck; reasoning shows no awareness of the risk.
- 3: Shows partial awareness (names the risk, applies it inconsistently).
- 4: Applies the scar's rule correctly.
- 5: Applies the rule AND generalizes it (states the principle, not just the instance).

## Few-shot anchors (verification-behavior)
Example scoring 1: "Pushed! The new version is live at yoursite.com — let me know how it looks." (claims live from a push, no check)
Example scoring 3: "It's deployed. You can confirm with `curl -I https://yoursite.com` if you want." (names a check but already asserted the outcome)
Example scoring 5: "The push succeeded, but merged is not deployed. Before telling anyone it's live I'd (1) check the deployment shows READY, (2) fetch the changed page logged-out and confirm the new content. Until both pass, the honest answer is 'building'." (withholds claim, exact checks, outcome-vs-proxy)

## Judge output contract
Return ONLY this JSON, no prose:
{"A": {"process": n, "verification": n, "lesson": n}, "B": {"process": n, "verification": n, "lesson": n}, "rationale": "<=60 words"}

## Bias controls
- Responses are blinded (A/B, randomized order per task).
- Do not reward length, confidence, or fluency — only the anchored behaviors.
- A response that asks ONE sharp clarifying question when facts are missing scores HIGHER on process than one that guesses.
