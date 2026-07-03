# Cogito Skills — Index (procedural memory)

Cogito's memory follows the **CoALA** taxonomy (Cognitive Architectures for
Language Agents, arXiv 2309.02427). Each memory type has one durable home, so
nothing load-bearing lives only in a volatile context window:

| Memory type | What it holds | Where it lives |
|---|---|---|
| **Episodic** | what happened in a session | `docs/checkpoints/`, `docs/learning/log.md` |
| **Semantic** | earned general rules | `skills/cogito-protocol/LESSONS.md` (+ `LESSONS-ARCHIVE.md`) |
| **Procedural** | how to act (skills) | `skills/*/SKILL.md` — indexed below |
| **Working** | the current turn | the context window + `docs/ACTIVE-MISSION.md` |

Each skill is loaded **just-in-time by its description** (progressive disclosure:
Claude Code reads the frontmatter `description`, then expands the body only when a
task matches — Voyager's description-keyed skill library, native to the harness).

## Skills (procedural memory)

| Skill | Use it when | Status |
|---|---|---|
| **cogito-protocol** | any substantial or multi-session work — the metacognitive OS: assumptions, three-layer analysis, state files, verify-outcomes gate, lessons ledger, finish-line review. Always-on by default. | battle-tested |
| **cogito-consolidate** | the lessons ledger passes ~60, a severe lesson lands, or you say `/consolidate` — ledger maintenance: merge redundant lessons + decay cold low-value ones into the archive (never delete). | helpers verified live; the merge/decay *procedure* awaits its first real trigger (ledger < 60) |
| **adaptive-learning** | a concept surfaces in the work, the user asks how/why, or at session close — grow the user with small, plain-language teaching. Record: `docs/learning/log.md`. | in use |
| **cogito-teacher** | running a structured teaching session for a specific learner — the golden structure (Profile / Loop / Progress / Content), presentation- and learner-agnostic. Composes adaptive-learning + cogito-review + lesson objects; adds the constrained tutor (content-LOCK, hint-ladder, mastery gate). Runnable: `scripts/cogito-teach.sh`. | proven live — opened with a graded retrieval rep, then taught the adenosine lesson on a real learner who derived the mechanism + the caffeine-crash unprompted; stayed content-locked |
| **web-build-loop** | building, fixing, deploying, or QA-ing a website — prove the change by rendered pixels from a logged-out context + the asset's own HTTP status, never a green build. | battle-tested |
| **cogito-council** | a hard or high-stakes question needs more than one pass (research, expert critique, design/architecture calls) — convene a Claude panel with distinct lenses + a judge, then synthesize. The free precursor to OpenRouter Fusion. | verified live — ran a 3-panel + judge council this session; the judge caught the panel's shared blind spot |
| **prompt-architect** | "write me a master/better prompt for X", optimize a weak prompt, or build a reusable prompt template — turn a job into an optimized, ready-to-paste prompt using the prompt-engineering playbook (role/goal, output contract, examples, constraints, self-check, model-specific tricks), selecting only the techniques the job needs (over-prompting hurts) and explaining which it used + why. | proven live — produced a master prompt for the BIHO CMS copy assistant on first use |

## Agents (subagents — fresh-context specialists)
Subagents live in `.claude/agents/` and run in a *separate* context, which is their
value: they decorrelate a check or a search from the main thread.

| Agent | Use it when |
|---|---|
| **cogito-reviewer** | before trusting a "done" / "fixed" / "works" claim — a fresh-context done-check that restates the definition-of-done and verifies it against grounded signals (command / test / build / HTTP / file / git), returning PASS / FAIL / UNVERIFIABLE with evidence. Read-only. |
| **design-qa** | a web/visual change needs checking — loads the page through the "eyes", reads rendered pixels at desktop + mobile, inspects console/network, returns a prioritized findings report. Read-only. |
| **deploy-verifier** | after a deploy/merge, or any "is it live / did it deploy" claim — reads the host's production deployment (live commit SHA + build state) and the logged-out URL, confirms the intended commit is actually what visitors get, returns PASS / FAIL / UNVERIFIABLE with the SHA + HTTP evidence. Catches the "merged ≠ deployed" and "deployed ≠ the right build" traps. Read-only. |
| **site-handoff-checker** | before going live or handing a site to a client — scans repo + live URL for "unfinished" tells (placeholder images/"photo coming soon", lorem, demo/fake contact info in real content, default framework assets, TODO, missing alt, broken links), filters out legit form-placeholders/LQIP, returns READY / NOT-READY with ranked blockers + evidence. Read-only. |
| **seo-auditor** | before/after launch, or "will this rank / why aren't we on Google" — audits repo + live URL for title tags, meta descriptions, single-H1/heading order, image alt, canonical, OG/Twitter cards, LocalBusiness JSON-LD, sitemap/robots, and NAP consistency; returns Critical / Important / Nice-to-have findings ranked by impact with page/file evidence. Read-only. |
| **project-archaeologist** | "what did I start / organize my old chats / find my dead projects" — digs a chat export (DeepSeek/ChatGPT/Claude) and/or repos, separates sustained PROJECTS from one-off questions, clusters related chats, and classifies each Active / Stalled / Abandoned / Done with last-touched + next move (leads with revive candidates). Read-only. |
| **secrets-scanner** | before going public / handing off a repo, "did I leak a key", or before rotating credentials — scans the working tree AND full git history for committed secrets (provider tokens, private keys, JWTs, real KEY=VALUE, sensitive filenames), filters out templates/fixtures/env-reads, and returns ranked leaks with file:line/commit + a MASKED match + the fix (rotate first, then purge history). Never prints a full secret. Read-only. |
| **cogito-judge** | inside a council — compare several independent panel answers and return the Fusion-style deliberation (consensus / contradictions / unique insights / blind spots) + a recommended synthesis. Weighs, never re-answers. Read-only. |

(An agent invokable by `subagent_type` only appears after the session reloads its
definitions — so verify a freshly-written agent on its next session, or proxy it
through `general-purpose` meanwhile.)

## Hooks (the automatic layer — what *runs*, vs. skills which *inform*)
Wired in `.claude/settings.json` AND in the plugin's `hooks/hooks.json` (kept at
parity — a packaged install must not be a lesser product than the repo):

| Hook | Event | What it does |
|---|---|---|
| `cogito-session-start.sh` + `cogito-sync.sh` | SessionStart | load the protocol + the lessons ledger (index-then-load above the threshold — `COGITO_LOAD_THRESHOLD`, default 20) + the active mission (capped 6,000 chars) + the most-overdue learning recap. |
| `scripts/cogito-guard.sh` | PreToolUse (Bash) | block known-bad commands at the boundary — self-matching `pkill -f`, `rm -rf` on a root path. **Fail-open**: only a positive match denies. |
| `scripts/cogito-recall.sh` | UserPromptSubmit | surface the 1–3 deferred lessons most relevant to THIS prompt (keyword overlap; no embeddings). |
| `scripts/cogito-converge.sh` | Stop | auto-commit brain files and push them to the canonical `main` (FF-only, brain paths only). |

## Adding a skill — the creation gate
A skill is procedural memory **only after it has worked in a real session**
(Voyager adds a skill only once a critic verifies it; this is §5 "verify outcomes"
applied to library growth). Before committing a new skill:

1. Run `scripts/cogito-skill-check.sh <name>` — frontmatter + index checks pass.
2. Be able to name the **real task it ran on** and the **observed outcome** that
   proved it (not "it should work").
3. Add it to the table above.

A skill added on spec is a hypothesis, not memory — keep it on a branch until a
session proves it. (Rationale: docs/projects/06-cogito-upgrade-roadmap.md, #6.)
