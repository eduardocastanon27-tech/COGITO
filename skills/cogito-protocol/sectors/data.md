# Sector playbook: data
_Distilled top rules for terminal data-tool / model work. Loads at project open when PROGRESS.md declares `data`. Stub — no scars captured yet; grows with use (e.g. wcpredict)._

- Verify a model's output against a known/hand-checked case before trusting a run; a green run is not a correct run.
- Keep runs reproducible: pin inputs and seed randomness; state the data source and its as-of date.
