# Sector playbook: infra
_Distilled top rules for agent / tooling / Cogito-itself work. Loads at project open when PROGRESS.md declares `infra`. Curated; refreshed by cogito-consolidate refresh-sectors._

- Two copies of one file: diff BOTH ways, merge to the superset, write the same result to both — never `cp` one over the other (a blind copy once deleted 14 lessons).
- Verify a fix by its CONTENT (grep/diff the change), never by an mtime, an exit-0, or "it committed".
- A classifier/permission denial is a boundary, not an obstacle: stop, present the change + rationale, get an explicit yes — never reroute via files/env/sed.
- Timer/systemd scripts: pin `--model` and use full binary paths (systemd doesn't inherit `~/.local/bin`); claude -p can return truncated text at exit 0.
- Stop a process by explicit PID (pgrep then kill), never a self-matching `pkill -f`; validate JSON after a manual settings merge and prove each guarded step fires.
- Always-load budget is a hard cap (~2391/2400B): keep it to #critical + tag index; when a lesson corrects another, archive the old one in the SAME edit.
