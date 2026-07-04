---
name: new-project-setup
description: Scaffold and deploy a new web project (Next.js) from zero to live on Vercel via GitHub. Use whenever starting a new tool, site, or product for Eduardo.
---

# New Project Setup

## Stack (Eduardo's defaults)
- **Framework:** Next.js 14+ (App Router, TypeScript, Tailwind)
- **GitHub org:** COGITO-SUM-cloude
- **Vercel team:** jfl-lol-projects (team_6eSiIJVqg7pNbeZEF2itapmi)
- **Deployment:** GitHub → Vercel auto-deploy on push to master

## Step-by-step workflow

### 1. Scaffold
```bash
cd ~/projects
npx create-next-app@latest <name> --typescript --tailwind --app --no-src-dir --import-alias "@/*" --yes
cd <name> && npm install @anthropic-ai/sdk   # if using Claude API
```

### 2. Build MVP, then commit
```bash
# Set git identity first — GitHub rejects pushes with real emails if privacy is on
git config user.email "COGITO-SUM-cloude@users.noreply.github.com"
git config user.name "Eduardo"
git add . && git commit -m "Initial <name> MVP"
```

### 3. Create GitHub repo and push
```bash
gh repo create <name> --public --source=. --remote=origin --push
```
If push fails with GH007 email privacy error → the email wasn't set correctly (step 2).

### 3.5. Turn on Job B project memory (every new project)
```bash
~/.claude/cogito/bin/cogito-project.sh init <name>          # writes PROGRESS.md into the repo
git add PROGRESS.md && git commit -m "Add PROGRESS.md (Job B project memory)"
```
`PROGRESS.md` is this project's "where are we / what's left" state. It **auto-loads** whenever a session opens in the repo and **auto-commits its own edits** (the cogito Stop hook), so cross-session continuity is on from commit one. Fill in the one-line description + first to-dos as you build.

### 4. Deploy to Vercel — IMPORT VIA WEB, not MCP tool
**Critical pitfall:** `mcp__claude_ai_Vercel__deploy_to_vercel` does NOT deploy. It returns "run vercel deploy" instructions. Ignore it for new projects.

Correct path:
1. Tell Eduardo: go to **vercel.com/new**
2. Import from GitHub → `COGITO-SUM-cloude/<name>`
3. Add environment variables (API keys) in the Vercel UI before clicking Deploy
4. Click Deploy → get live URL

After the first import, every `git push origin master` auto-deploys.

### 5. Environment variables
- Local dev: write to `.env.local` (gitignored by default in Next.js)
- Production: set in Vercel project → Settings → Environment Variables
- **Never commit `.env.local` or secrets to git**
- If Eduardo shares an API key in chat, flag it immediately: tell him to rotate it after use

## Pitfalls

| Symptom | Root cause | Fix |
|---|---|---|
| `deploy_to_vercel` returns CLI instructions, nothing happens | MCP tool doesn't actually deploy new projects | Use vercel.com/new import instead |
| GitHub push rejected with GH007 | Real email in git config violates GitHub privacy settings | `git config user.email "COGITO-SUM-cloude@users.noreply.github.com"` |
| Agent fails with "Prompt is too long" | Build agent prompts > ~2000 words crash | Keep prompts focused: what to build, not how to implement every detail. Provide key code snippets inline rather than in prose |
| API 500 after deploy | API key not set in Vercel env vars, OR zero credit balance | Check Vercel env vars; if Anthropic error "credit balance too low" → console.anthropic.com → Billing → Add $5 |
| Port conflict in dev | Port 3000 = Hermes WhatsApp bridge, always taken | Next.js auto-picks 3001; dev URL is http://localhost:3001 |
| `git init` / `git push` "fails silently" mid-build | Command sandbox blocks git write ops | Re-run the git/gh steps with the sandbox disabled (`dangerouslyDisableSandbox: true` on the Bash call). Seen on both StoreScript and Puente builds |
| Can't deploy to Vercel from here | `deploy_to_vercel` MCP only returns CLI instructions; no local Vercel token; git-integration connect is OAuth | Hand the user the 4-click `vercel.com/new` import. Once they enable the GitHub integration on their account, future pushes auto-deploy and this step disappears |

## Design defaults (Eduardo's aesthetic)
- Background: `bg-slate-950`
- Cards: `bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl p-8`
- Accent: `amber-500` (CTA buttons, active states, highlights)
- Labels: `text-xs font-semibold tracking-widest uppercase text-white/40`
- Input focus: `focus:border-amber-400/50 focus:ring-1 focus:ring-amber-400/20`
- Reference: hermes-agent.nousresearch.com for the engraving/premium feel

## After deploy checklist
- [ ] `PROGRESS.md` created + committed (step 3.5) — Job B memory on
- [ ] Test API endpoint with `curl -X POST ...`
- [ ] Confirm env vars are set in Vercel (runtime errors visible via `mcp__claude_ai_Vercel__get_runtime_errors`)
- [ ] Verify rate limiting works
- [ ] Check Vercel project ID (list via `mcp__claude_ai_Vercel__list_projects`, teamId: team_6eSiIJVqg7pNbeZEF2itapmi)
