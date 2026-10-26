#!/usr/bin/env bash
# Block until the Softoria gateway answers again, then exit.
# Launch it as a tracked background shell: its exit is the event that wakes
# the orchestrator to resume tickets stopped with SOFTORIA_STATUS=gateway|vpn.
#
# usage: wait-softoria.sh [max-minutes=30] [interval-seconds=60]
# last line:  SOFTORIA_UP=ok | timeout | auth
# exit: 0 healthy · 3 still down after max-minutes · 4 auth / no key
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
max_min=${1:-30}
interval=${2:-60}
deadline=$(( $(date +%s) + max_min * 60 ))

while :; do
  line=$("$here/probe.sh" 2>/dev/null)
  echo "$(date +%H:%M:%S) $line"
  case "$line" in
    PROBE=ok*) echo "SOFTORIA_UP=ok"; exit 0 ;;
    PROBE=auth*|PROBE=nokey*) echo "SOFTORIA_UP=auth"; exit 4 ;;
  esac
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "SOFTORIA_UP=timeout"; exit 3
  fi
  sleep "$interval"
done
