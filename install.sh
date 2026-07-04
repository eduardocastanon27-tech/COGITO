#!/usr/bin/env bash
# Cogito installer — makes the protocol "online": durable + live + auto-loading.
#
#   ./install.sh                 install the skill + verify the ledger is writable
#   ./install.sh --global-hook   also auto-load Cogito in EVERY session, every repo
#
# Idempotent and safe to re-run. Never clobbers an accumulated LESSONS.md.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILL_SRC="$REPO_DIR/skills/cogito-protocol"
SKILL_DST="$CLAUDE_HOME/skills/cogito-protocol"
LEDGER="$SKILL_DST/LESSONS.md"
ARCHIVE_SRC="$SKILL_SRC/LESSONS-ARCHIVE.md"
ARCHIVE_DST="$SKILL_DST/LESSONS-ARCHIVE.md"

say() { printf '  %s\n' "$*"; }

echo "Cogito installer"
say "repo:        $REPO_DIR"
say "claude home: $CLAUDE_HOME"

# --- 1. Install the skill (protocol), preserving any accumulated ledger -------
mkdir -p "$SKILL_DST"
cp -f "$SKILL_SRC/SKILL.md" "$SKILL_DST/SKILL.md"
cp -f "$REPO_DIR/.claude/hooks/cogito-session-start.sh" "$SKILL_DST/session-start.sh"
chmod +x "$SKILL_DST/session-start.sh"
say "installed SKILL.md + session-start.sh"

if [ ! -f "$LEDGER" ]; then
  cp "$SKILL_SRC/LESSONS.md" "$LEDGER"
  say "seeded LESSONS.md"
else
  say "kept existing LESSONS.md (preserving accumulated lessons)"
fi

# Seed the consolidation archive too (raw lessons retired by /consolidate land
# here; the loader never reads it, so archiving removes a lesson from context
# without losing it). Preserve any accumulated archive, like the ledger.
if [ -f "$ARCHIVE_SRC" ]; then
  if [ ! -f "$ARCHIVE_DST" ]; then
    cp "$ARCHIVE_SRC" "$ARCHIVE_DST"; say "seeded LESSONS-ARCHIVE.md"
  else
    say "kept existing LESSONS-ARCHIVE.md"
  fi
fi

# --- 1b. Install companion skills (every other skill under skills/) -----------
for src in "$REPO_DIR"/skills/*/; do
  name="$(basename "$src")"
  [ "$name" = "cogito-protocol" ] && continue
  [ -f "$src/SKILL.md" ] || continue
  dst="$CLAUDE_HOME/skills/$name"
  mkdir -p "$dst"
  cp -f "$src"/*.md "$dst"/
  say "installed companion skill: $name"
done

# --- 2. Verify the ledger is writable AND survives a write (protocol §4b) -----
probe="<!-- install-probe $(date -u +%Y-%m-%dT%H:%M:%SZ) $$ -->"
printf '%s\n' "$probe" >> "$LEDGER"
if grep -qF "$probe" "$LEDGER"; then
  grep -vF "$probe" "$LEDGER" > "$LEDGER.tmp" && mv "$LEDGER.tmp" "$LEDGER"
  say "ledger is writable and persists ✓"
else
  echo "  WARNING: ledger write did not persist — the capture path is broken." >&2
  exit 1
fi

# --- 3. Optional: --global — the box-wide brain (every session, every repo) ---
# Installs the lean global scripts to ~/.claude/cogito/bin (a VERSION-stamped
# snapshot: updates are DELIBERATE — re-run this installer — never auto-pulled
# from a remote; same supply-chain posture as the SKILL.md council ruling) and
# wires three global hooks in ~/.claude/settings.json:
#   SessionStart (matcher startup|clear|compact — NEVER resume: the Hermes proxy
#     resumes per WhatsApp turn and re-injection would break the prompt cache)
#       -> cogito-global-load.sh   (lean brain: CORE + criticals + top strategies)
#   PreToolUse:Bash -> cogito-guard.sh  (box-wide command guard, fail-open)
#   UserPromptSubmit -> cogito-recall.sh (relevant deferred lessons, any repo)
# Rollback without uninstalling: COGITO_GLOBAL=0 or touch ~/.claude/cogito/DISABLED.
if [ "${1:-}" = "--global" ] || [ "${1:-}" = "--global-hook" ]; then
  [ "${1:-}" = "--global-hook" ] && say "note: --global-hook is superseded by --global (same effect now)"
  BIN="$CLAUDE_HOME/cogito/bin"
  mkdir -p "$BIN"
  for s in cogito-global-load.sh cogito-guard.sh cogito-recall.sh cogito-learn.sh cogito-progress.sh; do
    cp -f "$REPO_DIR/scripts/$s" "$BIN/$s"
    chmod +x "$BIN/$s"
  done
  printf '%s %s\n' "$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)" \
                   "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CLAUDE_HOME/cogito/VERSION"
  say "installed global scripts -> $BIN (VERSION $(cat "$CLAUDE_HOME/cogito/VERSION"))"

  settings="$CLAUDE_HOME/settings.json"
  if [ -f "$settings" ]; then
    cp -f "$settings" "$settings.bak-$(date +%F)"
    say "backed up settings.json -> $settings.bak-$(date +%F)"
  fi
  python3 - "$settings" "$BIN" <<'PY'
import json, os, sys
settings, bin_dir = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(settings):
    with open(settings) as f:
        try: data = json.load(f) or {}
        except json.JSONDecodeError:
            sys.stderr.write("  ERROR: existing settings.json is invalid JSON — fix it first\n")
            sys.exit(1)
hooks = data.setdefault("hooks", {})

def ensure(event, matcher, cmd, timeout=None):
    groups = hooks.setdefault(event, [])
    for g in groups:
        for h in g.get("hooks", []):
            if h.get("command") == cmd:
                return False
    h = {"type": "command", "command": cmd}
    if timeout is not None: h["timeout"] = timeout
    g = {"hooks": [h]}
    if matcher is not None: g["matcher"] = matcher
    groups.append(g)
    return True

changed = 0
changed += ensure("SessionStart", "startup|clear|compact", bin_dir + "/cogito-global-load.sh")
changed += ensure("PreToolUse", "Bash", bin_dir + "/cogito-guard.sh", 10)
changed += ensure("UserPromptSubmit", None, bin_dir + "/cogito-recall.sh", 10)
changed += ensure("Stop", None, bin_dir + "/cogito-progress.sh --flush", 10)
os.makedirs(os.path.dirname(settings), exist_ok=True)
with open(settings, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("  wired %d global hook group(s) in %s (idempotent)" % (changed, settings))
PY
  say "kill switch: COGITO_GLOBAL=0 or touch $CLAUDE_HOME/cogito/DISABLED"
else
  say "skipped global wiring (run with --global for the box-wide brain + guard)"
  say "this repo already auto-loads via .claude/settings.json"
fi

echo "Done. Cogito is live. Skill: $SKILL_DST"
