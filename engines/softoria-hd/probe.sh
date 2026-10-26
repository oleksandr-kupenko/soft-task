#!/usr/bin/env bash
# Tell a VPN problem from a Softoria gateway problem with one tiny request.
#
# usage: probe.sh
# prints one line:  PROBE=<state> http=<code>
#   ok       the gateway answers                     exit 0
#   gateway  reachable, but 5xx / 429 / timeout      exit 1
#   vpn      no connection at all (VPN off, DNS)      exit 3
#   auth     401 / 403 — wrong or missing key         exit 4
#   nokey    no key in env or opencode.json           exit 4
#   unknown  no baseURL configured                    exit 5
#
# Key: $SOFTORIA_API_KEY, else the literal apiKey in ~/.config/opencode/opencode.json.
# The key is passed to curl only; it is never printed.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
fragment="$here/../../opencode/provider.fragment.json"

conf=$(python3 - "$fragment" <<'PY'
import json, os, sys
base, key = "", os.environ.get("SOFTORIA_API_KEY", "")
for path in (os.path.expanduser("~/.config/opencode/opencode.json"), sys.argv[1]):
    try:
        opts = json.load(open(path))["provider"]["softoria"]["options"]
    except Exception:
        continue
    base = base or str(opts.get("baseURL") or "").rstrip("/")
    k = str(opts.get("apiKey") or "")
    if not key and k and not k.startswith("{env:"):
        key = k
print(base)
print(key)
PY
)
base=$(printf '%s\n' "$conf" | sed -n 1p)
key=$(printf '%s\n' "$conf" | sed -n 2p)

[ -z "$base" ] && { echo "PROBE=unknown http=-"; exit 5; }
[ -z "$key" ] && { echo "PROBE=nokey http=-"; exit 4; }

out=$(curl -s -o /dev/null -w '%{http_code} %{time_connect}' --connect-timeout 10 --max-time 90 \
  -H "Authorization: Bearer $key" -H 'Content-Type: application/json' \
  -d '{"model":"Softoria-HD","max_tokens":1,"messages":[{"role":"user","content":"ping"}]}' \
  "$base/chat/completions")
http=${out%% *}
connected=${out##* }

case "$http" in
  000)
    # TCP connected but no HTTP answer in time: the gateway hangs, the VPN is fine.
    if [ "${connected:-0}" != "0.000000" ] && [ "${connected:-0}" != "0" ]; then
      echo "PROBE=gateway http=timeout"; exit 1
    fi
    echo "PROBE=vpn http=000"; exit 3 ;;
  2??) echo "PROBE=ok http=$http"; exit 0 ;;
  401|403) echo "PROBE=auth http=$http"; exit 4 ;;
  429|5??) echo "PROBE=gateway http=$http"; exit 1 ;;
  *) echo "PROBE=ok http=$http"; exit 0 ;;
esac
