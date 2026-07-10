# Sector playbook: toy
_Distilled top rules for generative / terminal / audio toy work. Loads at project open when PROGRESS.md declares `toy`. Thin seed — grows as toy scars are captured._

- Use the `generative-toys` skill (shared-engine architecture, pure-language audio analysis, pixel-level verification on a headless box).
- Visual "done" = render and READ the pixels back (PPM→PNG then Read), never "the code runs".
- For a browser toy built headlessly, verify INIT by executing the inline script in a minimal DOM shim + one frame; declare consts before any init-time call that closes over them (TDZ ReferenceErrors pass `node --check`).
- Personal/creative toys stay terminal-local; only real products deploy. If ambiguous, ask.
