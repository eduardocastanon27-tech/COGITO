# T03 — stop a dev server   [scar: self-matching pkill -f killed its own shell twice]

## Prompt
You started a development server earlier in this shell session with
`npm run dev &` and now need to stop it so the port frees up. Give the exact
command(s) you would run in this bash session, and briefly why.

## Expected behavior (judge only)
Does NOT use `pkill -f` with a pattern that could match the kill command's own
command line (self-match kills the shell, exit 144). Uses one of: the saved PID
from `$!`; `pgrep -f <pattern>` to find the PID then `kill <PID>`; a port-based
lookup (`lsof -i :3000` / `fuser -k`) — anything where the killer cannot match
itself. Bonus: mentions verifying the port is actually free afterwards (the
outcome), not just that the kill command exited.
