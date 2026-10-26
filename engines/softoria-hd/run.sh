#!/usr/bin/env bash
# Run one task on Softoria-HD (reasoning max) through opencode, headless.
# Survives short gateway outages: retries in-process and resumes the same session.
#
# usage: run.sh <prompt-file> <title> [workdir] [variant] [session-id]
#   prompt-file  markdown task for the executor (absolute or relative to workdir);
#                "-" with a session-id sends the built-in "continue after outage" message
#   title        opencode session title, also used for log/snapshot names
#   workdir      repo to run in (default: current directory)
#   variant      low | high | max (default: max)
#   session-id   continue this opencode session instead of starting a new one
#                (take it from SOFTORIA_SESSION= in the previous log)
#
# env:
#   SOFTORIA_RETRIES  extra attempts after a gateway/network failure (default 3)
#   SOFTORIA_BACKOFF  seconds to wait before each retry (default "30 90 180")
#
# Writes into <workdir>/tmp/softoria/:
#   <slug>.base.tree  git tree of the working copy before the first run
#                     (kept as is when resuming, so diff.sh shows all work)
#   <slug>.log        full opencode output of every attempt; ends with
#                       SOFTORIA_STATUS=ok|gateway|vpn|auth|error
#                       SOFTORIA_RETRIES=<n>
#                       SOFTORIA_SESSION=<id or empty>
#                       SOFTORIA_EXIT=<code>          (always the last line)
#   <slug>.log.N      logs of earlier runs with the same title
#
# Review afterwards with engines/softoria-hd/diff.sh <slug> [workdir].
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

prompt_file=${1:?prompt file required}
title=${2:?title required}
workdir=${3:-$PWD}
variant=${4:-max}
session=${5:-}
retries=${SOFTORIA_RETRIES:-3}
read -r -a backoff <<< "${SOFTORIA_BACKOFF:-30 90 180}"

cd "$workdir" || exit 2
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
out="$workdir/tmp/softoria"
mkdir -p "$out"
log="$out/$slug.log"
part="$out/$slug.part"

if [ "$prompt_file" = "-" ]; then
  [ -z "$session" ] && { echo "prompt '-' needs a session-id" >&2; exit 2; }
elif [ ! -f "$prompt_file" ]; then
  if [ -f "$workdir/$prompt_file" ]; then
    prompt_file="$workdir/$prompt_file"
  else
    echo "prompt file not found: $prompt_file" >&2
    exit 2
  fi
fi

if [ -f "$log" ]; then
  n=1
  while [ -e "$log.$n" ]; do n=$((n + 1)); done
  mv "$log" "$log.$n"
fi

if [ -z "$session" ] || [ ! -s "$out/$slug.base.tree" ]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    idx="$out/$slug.idx"
    rm -f "$idx"
    GIT_INDEX_FILE="$idx" git add -A >/dev/null 2>&1
    GIT_INDEX_FILE="$idx" git write-tree > "$out/$slug.base.tree"
    rm -f "$idx"
  fi
fi

now_ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }

# Newest session with exactly this title, created after $1 (ms).
find_session() {
  opencode session list --format json -n 50 2>/dev/null | python3 -c '
import json, sys
title, since = sys.argv[1], int(sys.argv[2])
try:
    rows = json.load(sys.stdin)
except Exception:
    sys.exit(0)
rows = [r for r in rows if r.get("title") == title and int(r.get("created") or 0) >= since]
rows.sort(key=lambda r: int(r.get("created") or 0), reverse=True)
if rows:
    print(rows[0].get("id", ""))
' "$title" "$1"
}

# gateway | network | auth | error, from the tail of one attempt.
classify() {
  local tail
  tail=$(tail -n 40 "$1")
  if grep -qiE 'BadGateway|ServiceUnavailable|GatewayTimeout|Error code: 50[0234]|InternalServerError|RateLimit|Error code: 429|model group .* failed|overloaded' <<< "$tail"; then
    echo gateway
  elif grep -qiE 'ECONNREFUSED|ENOTFOUND|ETIMEDOUT|ECONNRESET|EAI_AGAIN|fetch failed|socket hang up|APIConnectionError|Connection error|network error' <<< "$tail"; then
    echo network
  elif grep -qiE 'AuthenticationError|Error code: 401|Error code: 403|invalid api key' <<< "$tail"; then
    echo auth
  else
    echo error
  fi
}

resume_msg="The previous turn was cut off by a Softoria gateway error, not by you. \
Continue the same task from where you stopped. Check the working tree first. \
Do not redo finished steps. Finish with the return block the task asks for."

echo "log: $log"
attempt=0
status=error
code=1
while :; do
  start_ms=$(now_ms)
  if [ -n "$session" ]; then
    msg="$resume_msg"
    [ "$attempt" -eq 0 ] && [ "$prompt_file" != "-" ] && msg="$(cat "$prompt_file")"
    opencode run --auto --standalone \
      --model "softoria/Softoria-HD#$variant" \
      --session "$session" \
      "$msg" > "$part" 2>&1
  else
    opencode run --auto --standalone \
      --model "softoria/Softoria-HD#$variant" \
      --title "$title" \
      "$(cat "$prompt_file")" > "$part" 2>&1
  fi
  code=$?
  cat "$part" >> "$log"
  [ -z "$session" ] && session=$(find_session "$start_ms")

  if [ "$code" -eq 0 ]; then
    status=ok
    break
  fi

  kind=$(classify "$part")
  case "$kind" in
    auth) status=auth; break ;;
    error) status=error; break ;;
  esac

  probe=$("$here/probe.sh" 2>/dev/null | sed -n 's/^PROBE=\([a-z]*\).*/\1/p')
  case "$probe" in
    vpn) status=vpn; break ;;
    auth|nokey) status=auth; break ;;
  esac
  status=gateway
  [ "$attempt" -ge "$retries" ] && break

  wait_s=${backoff[$attempt]:-${backoff[${#backoff[@]}-1]:-60}}
  attempt=$((attempt + 1))
  echo "=== SOFTORIA_RETRY $attempt/$retries kind=$kind wait=${wait_s}s session=${session:-none} ===" >> "$log"
  sleep "$wait_s"
done
rm -f "$part"

{
  echo "SOFTORIA_STATUS=$status"
  echo "SOFTORIA_RETRIES=$attempt"
  echo "SOFTORIA_SESSION=$session"
  echo "SOFTORIA_EXIT=$code"
} >> "$log"
echo "SOFTORIA_STATUS=$status SOFTORIA_SESSION=$session SOFTORIA_EXIT=$code"
exit "$code"
