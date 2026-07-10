#!/usr/bin/env bash
# Cogito guard — a PreToolUse hook that BLOCKS specific known-bad Bash commands at
# the moment they are about to run. It is the mechanical enforcer for "knowing !=
# doing": a loaded lesson does not fire by itself, but a hook at the tool boundary
# does (learning-log Lesson 3).
#
# FAIL-OPEN BY CONTRACT. It denies ONLY a command it positively recognises as
# known-bad; everything else (and any internal error) is allowed. A buggy guard must
# never brick a session. (Hence no `set -e`.)
#
# MENTION vs EXECUTION: a dangerous string INSIDE a quoted argument — a commit
# message, an `echo`, a captured lesson — is a mention, not a command. So we remove
# quoted SPANS first and inspect only the unquoted command skeleton, and we anchor
# detection to command position (start, or right after a shell operator ; && || | ( ).
# (Flattening quote *characters* was an earlier bug: it merged message text into the
# command and blocked a `git commit` whose message merely mentioned `pkill -f`.)
set -uo pipefail   # deliberately NOT -e: a stray non-zero must never become a block

# classify <command> -> echoes a human reason iff the command is known-bad (=> deny),
# else echoes nothing.
classify() {
  local cmd res
  cmd="$1"
  # Drop single- and double-quoted spans (chr(39)/chr(34) avoid quote-hell in -c).
  res="$(python3 -c 'import sys,re
s=sys.argv[1]; q=chr(39); d=chr(34)
s=re.sub(q+"[^"+q+"]*"+q,"",s)
s=re.sub(d+"[^"+d+"]*"+d,"",s)
print(s)' "$cmd" 2>/dev/null || true)"

  # 1. self-matching pkill -f / --full — matches the FULL command line incl. this
  #    shell; killed our own shell twice (exit 144).
  if printf '%s' "$res" | grep -qE '(^|[;&|(])[[:space:]]*pkill[[:space:]][^;&|]*(-[[:alnum:]]*f([[:space:]]|$)|--full)'; then
    echo "pkill -f/--full matches the FULL command line — including this shell (it has killed our own shell twice, exit 144). Kill by PID instead: pgrep -f '<pat>' then kill <pid>, or use a pattern that cannot match the kill command itself."
    return
  fi

  # 2. catastrophic root wipe — rm (any flags) with a root-ish target (/ /* ~ $HOME).
  if printf '%s' "$res" | grep -qE '(^|[;&|(])[[:space:]]*(sudo[[:space:]]+)?rm([[:space:]]+-[[:alnum:]]+)*[[:space:]]+(/|/\*|~|\$HOME)([[:space:]]|$)'; then
    echo "rm on a root path (/ ~ \$HOME /*) is catastrophic and unrecoverable. Target a specific subdirectory, never the root."
    return
  fi

  # 2b. rm whose root target was QUOTED — the strip-spans blind spot. Stripping quoted
  #     spans (for the mention-vs-execution call) also erases a genuinely-dangerous quoted
  #     ARGUMENT, so `rm -rf "/"` / `rm -rf '$HOME'` slipped past check 2 (verified). Deny
  #     only when BOTH hold: (a) the skeleton has rm AT COMMAND POSITION with its argument
  #     stripped (= the arg was quoted), and (b) the raw command contains a quoted root
  #     token. The conjunction keeps mentions safe — `echo "rm -rf /"` and
  #     `git commit -m "done; rm -rf /"` have NO rm at command position in the skeleton.
  if printf '%s' "$res" | grep -qE '(^|[;&|(])[[:space:]]*(sudo[[:space:]]+)?rm([[:space:]]+-[[:alnum:]]+)*[[:space:]]*($|[;&|])' \
     && printf '%s' "$cmd" | python3 -c 'import sys,re
s=sys.stdin.read(); q=chr(39); d=chr(34)
pat="(["+q+d+"])(/|/\\*|~|\\$HOME)\\1"
sys.exit(0 if re.search(pat,s) else 1)' 2>/dev/null; then
    echo "rm targeting a quoted root path (\"/\", '\$HOME', \"/*\") is catastrophic and unrecoverable — quoting it does not make it safe. Target a specific subdirectory, never the root."
    return
  fi

  # 3. direct push to the protected main branch. The most-recorded git scar (lessons:
  #    a main-push bundled into a chained command; consent inferred from a generic "go"
  #    or an after-the-fact aside). A main push must be DELIBERATE and main-SPECIFIC,
  #    never incidental or bundled. The sanctioned brain->main path is the converge Stop
  #    hook, which runs in ITS OWN process and never passes through this PreToolUse hook —
  #    so this rule does not touch it. Escape hatch for a genuine, approved push: the user
  #    sets COGITO_ALLOW_MAIN_PUSH=1 for that one command.
  if [ -z "${COGITO_ALLOW_MAIN_PUSH:-}" ] || [ "${COGITO_ALLOW_MAIN_PUSH:-}" = "0" ]; then
    # 'main' must appear in the SAME command segment as the git push — a compound
    # like `git push origin feature && git checkout main` is NOT a main push
    # (that false positive was confirmed 2026-07-07). Known fail-open gaps, by
    # contract: `time git push origin main`, `env X=1 git push origin main`.
    if printf '%s' "$res" | python3 -c 'import sys,re
s=sys.stdin.read()
for seg in re.split(r"[;|&()\n]+", s):
    if re.search(r"^\s*git\s+push(\s|$)", seg) and re.search(r"([\s:+]|heads/)main(\s|$)", seg):
        sys.exit(0)
sys.exit(1)' 2>/dev/null; then
      echo "direct push to 'main' is gated. main is the one canonical brain, and a main push must be deliberate + main-specific — the top recorded git scar is a bundled/inferred main-push. Push your feature branch instead (the converge hook carries brain files to main on its own). If you TRULY mean to push main right now, re-run it with COGITO_ALLOW_MAIN_PUSH=1 set for that single command — and only on an explicit, main-specific yes from the user."
      return
    fi
  fi

  # 4. disabling TLS verification. #security scar: a "make the egress work" hack sent a
  #    Bearer token over an UNVERIFIED TLS connection (MITM-exposable). This egress
  #    intercepts TLS with a trusted CA at /root/.ccr/ca-bundle.crt — that is the
  #    sanctioned path; verification must never be turned off, least of all with a token
  #    in the environment. Covers curl -k/--insecure, wget --no-check-certificate, the
  #    NO_VERIFY / REJECT_UNAUTHORIZED env switches, and git's http.sslVerify=false.
  if printf '%s' "$res" | grep -qE '(^|[;&|(])[[:space:]]*curl\b[^;&|]*([[:space:]]--insecure([[:space:]]|$)|[[:space:]]-[[:alpha:]]*k[[:alpha:]]*([[:space:]]|$))' \
     || printf '%s' "$res" | grep -qE 'wget\b[^;&|]*--no-check-certificate' \
     || printf '%s' "$res" | grep -qE '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z_0-9]*=[^[:space:]]*[[:space:]]+)*(GIT_SSL_NO_VERIFY=([1-9]|true|yes|on)|NODE_TLS_REJECT_UNAUTHORIZED=0|PYTHONHTTPSVERIFY=0)' \
     || printf '%s' "$res" | grep -qE 'http\.sslVerify[=[:space:]]+(false|0)([[:space:]]|$)'; then
    echo "disabling TLS verification is blocked. The egress intercepts TLS with a trusted CA at /root/.ccr/ca-bundle.crt — pass --cacert (or set CURL_CA_BUNDLE), never -k / --insecure / *_NO_VERIFY / sslVerify=false. A secret sent over an unverified connection is MITM-exposable (a recorded #security scar): fail loudly and point at the CA instead."
    return
  fi
}

# ---- selftest: the contract, as runnable assertions -------------------------------
selftest() {
  local fails=0
  check() { # check <expect deny|allow> <command>
    local want="$1" cmd="$2" reason; reason="$(classify "$cmd")"
    local got="allow"; [ -n "$reason" ] && got="deny"
    if [ "$got" = "$want" ]; then printf '  ok   [%s] %s\n' "$want" "$cmd"
    else printf '  FAIL want=%s got=%s : %s\n' "$want" "$got" "$cmd"; fails=$((fails+1)); fi
  }
  echo "cogito-guard selftest"
  # must DENY (real execution of a known-bad command)
  check deny  'pkill -f "next dev"'
  check deny  'pkill -f http.server'
  check deny  'pkill --full myproc'
  check deny  'pkill -9 -f pattern'
  check deny  'pkill -ef foo'
  check deny  'cd /tmp && pkill -f server'
  check deny  'rm -rf /'
  check deny  'rm -rf /*'
  check deny  'rm -rf ~'
  check deny  'rm -rf $HOME'
  check deny  'sudo rm -rf /'
  check deny  'rm -r -f /'
  check deny  'git commit -m "x"; rm -rf /'         # real rm after an operator
  check deny  'rm -rf "/"'                          # quoted root — the strip-spans blind spot
  check deny  "rm -rf '/'"
  check deny  'rm -rf "$HOME"'
  check deny  'rm -rf "/*"'
  check deny  'sudo rm -rf "/"'
  # must DENY — direct push to the protected main branch (gated, lessons #96/#97/#80/#77)
  check deny  'git push origin main'
  check deny  'git push -u origin main'
  check deny  'git push origin HEAD:main'
  check deny  'git push --force origin main'
  check deny  'git push -f origin +main'
  check deny  'git push origin refs/heads/main'
  check deny  'git push origin HEAD:refs/heads/main'
  check deny  'git commit -m "x" && git push origin main'   # bundled main-push
  check deny  'git add -A && git commit -m "y"; git push origin main'
  check deny  'git checkout main && git push origin main'   # push segment itself names main
  check deny  'FOO=1 NODE_TLS_REJECT_UNAUTHORIZED=0 node app.js'  # env-prefixed assignment still caught
  # must DENY — disabling TLS verification (lesson #104: token over unverified TLS)
  check deny  'curl -k https://example.com'
  check deny  'curl --insecure https://example.com'
  check deny  'curl -sSk https://example.com/api'
  check deny  'wget --no-check-certificate https://example.com'
  check deny  'GIT_SSL_NO_VERIFY=1 git fetch origin'
  check deny  'NODE_TLS_REJECT_UNAUTHORIZED=0 node app.js'
  check deny  'git -c http.sslVerify=false push origin feature'
  check deny  'git config http.sslVerify false'
  # must ALLOW — safe commands, or merely MENTIONING a dangerous string
  check allow 'rm -rf "./build"'                     # quoted RELATIVE path — safe
  check allow 'git commit -m "done; rm -rf /"'       # operator + root INSIDE a message (not execution)
  check allow 'pkill -x exactname'
  check allow 'pkill chrome'
  check allow 'pgrep -f pattern'
  check allow 'echo "pkill -f x"'
  check allow 'echo pkill -f'                        # unquoted mention (not cmd pos)
  check allow './scripts/cogito-learn.sh "lesson: never pkill -f a self-matching pattern"'
  check allow 'git commit -m "fix: never pkill -f or rm -rf /"'   # THE regression
  check allow 'git commit -q -m "guard blocks pkill -f and rm -rf /"'
  check allow $'git commit -m "title\n\nnote: pkill -f and rm -rf / are banned"'  # multiline msg
  check allow 'grep "rm -rf" notes.md'
  check allow 'echo "rm -rf /"'
  check allow 'rm -rf ./build'
  check allow 'rm -rf /tmp/foo'
  check allow 'rm -rf node_modules'
  check allow 'git commit -m "m" && rm -rf ./dist'   # real rm of a specific dir
  check allow 'git status'
  # must ALLOW — main-push rule must not over-block
  check allow 'git push -u origin claude/optimistic-clarke-ptim35'  # feature branch
  check allow 'git push origin feature'
  check allow 'git push origin main-feature'         # a different branch, not main
  check allow 'git push origin develop:develop'
  check allow 'git commit -m "push to main later"'   # main only MENTIONED in a message
  check allow 'git push origin main:staging'         # pushing FROM main TO staging (not to main)
  check allow 'git push origin feature && git checkout main'   # main in a DIFFERENT segment (fp fixed 2026-07-07)
  check allow 'git fetch origin main && git push origin mybranch'
  check allow 'git pull origin main; git push origin dev'
  COGITO_ALLOW_MAIN_PUSH=1 check allow 'git push origin main'        # explicit one-shot approval
  # must ALLOW — TLS rule must not over-block
  check allow 'curl -sS https://example.com'         # no -k
  check allow 'curl --cacert /root/.ccr/ca-bundle.crt https://example.com'
  check allow 'curl -K configfile https://example.com'   # -K (config) is not -k (insecure)
  check allow 'git -c http.sslVerify=true push origin feature'
  check allow 'echo "curl -k is banned here"'        # mention in a quoted string
  check allow 'git commit -m "never use curl -k or NODE_TLS_REJECT_UNAUTHORIZED=0"'
  check allow 'grep NODE_TLS_REJECT_UNAUTHORIZED=0 server.js'  # unquoted MENTION at arg position (fp fixed 2026-07-07)
  echo
  [ "$fails" -eq 0 ] && echo "selftest: ALL PASS" || { echo "selftest: $fails FAILED"; return 1; }
}

# ---- hook mode: read PreToolUse JSON on stdin, decide ------------------------------
# Contract (verified vs code.claude.com/docs/en/hooks 2026-06-15): deny via exit 0 +
# {hookSpecificOutput.permissionDecision:"deny"} (preferred) or exit 2 + stderr. ANY
# other exit code (incl. crash/timeout) is non-blocking -> the tool proceeds. So every
# path here except a positive match returns 0 = allow. That is the fail-open guarantee.
hook_mode() {
  local input cmd reason
  input="$(cat 2>/dev/null || true)"
  cmd="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
    if d.get("tool_name")=="Bash": print(d.get("tool_input",{}).get("command",""))
except Exception: pass' 2>/dev/null || true)"
  [ -n "$cmd" ] || exit 0                 # non-Bash / no command / parse failed -> allow
  reason="$(classify "$cmd")"
  [ -n "$reason" ] || exit 0              # not known-bad -> allow
  if printf '%s' "$reason" | python3 -c 'import sys,json
print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"cogito-guard blocked this — "+sys.stdin.read()}}))' 2>/dev/null; then
    exit 0
  fi
  echo "cogito-guard blocked this — $reason" >&2
  exit 2
}

case "${1:-}" in
  --selftest) selftest ;;
  *) hook_mode ;;
esac
