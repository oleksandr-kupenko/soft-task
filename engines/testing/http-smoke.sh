#!/usr/bin/env bash
# Backend blind-acceptance helper: hit a list of URLs, expect 2xx/3xx.
#
# usage: http-smoke.sh <base-url> [path...]
#   or:  http-smoke.sh --file smoke.urls
#
# smoke.urls format: one path or absolute URL per line; # comments allowed.
# Exit 0 if all pass; non-zero otherwise. Prints PASS/FAIL lines.
set -euo pipefail

base=""
paths=()

if [ "${1:-}" = "--file" ]; then
  file=${2:?urls file required}
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    paths+=("$line")
  done < "$file"
else
  base=${1:?base url required}
  shift
  paths=("$@")
  if [ ${#paths[@]} -eq 0 ]; then
    paths=("/")
  fi
fi

fail=0
for p in "${paths[@]}"; do
  if [[ "$p" == http://* || "$p" == https://* ]]; then
    url="$p"
  else
    url="${base%/}/$(echo "$p" | sed 's#^/##')"
  fi
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 -L "$url" || echo "000")
  if [[ "$code" =~ ^(2|3)[0-9][0-9]$ ]]; then
    echo "PASS $code $url"
  else
    echo "FAIL $code $url"
    fail=1
  fi
done
exit $fail
