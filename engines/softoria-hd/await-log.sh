#!/usr/bin/env bash
# Tracked waiter for ONE Softoria log. Use when a wave was orphaned and the
# harness no longer watches the Softoria process: run this as its own Shell
# with block_until_ms: 0 / run_in_background so completion wakes the agent.
#
# usage: await-log.sh <slug> [workdir] [poll-seconds]
#   slug   as in tmp/softoria/<slug>.log (same slug run.sh derived from the title)
#   exits 0 when SOFTORIA_EXIT= appears; prints the last 5 log lines.
set -euo pipefail

slug=${1:?slug required}
workdir=${2:-$PWD}
poll=${3:-30}
log="$workdir/tmp/softoria/$slug.log"

cd "$workdir" || exit 2
mkdir -p "$(dirname "$log")"

echo "awaiting $log (poll=${poll}s)"
while ! grep -q '^SOFTORIA_EXIT=' "$log" 2>/dev/null; do
  sleep "$poll"
done
tail -5 "$log"
exit 0
