#!/usr/bin/env bash
# Run one task on Softoria-HD (reasoning max) through opencode, headless.
#
# usage: run.sh <prompt-file> <title> [workdir] [variant]
#   prompt-file  markdown task for the executor (absolute or relative to workdir)
#   title        opencode session title, also used for log/snapshot names
#   workdir      repo to run in (default: current directory)
#   variant      low | high | max (default: max)
#
# Writes into <workdir>/tmp/softoria/:
#   <slug>.base.tree  git tree of the working copy before the run
#   <slug>.log        full opencode output; last line is SOFTORIA_EXIT=<code>
#
# Review afterwards with engines/softoria-hd/diff.sh <slug> [workdir].
set -uo pipefail

prompt_file=${1:?prompt file required}
title=${2:?title required}
workdir=${3:-$PWD}
variant=${4:-max}

cd "$workdir" || exit 2
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
out="$workdir/tmp/softoria"
mkdir -p "$out"
log="$out/$slug.log"

if [ ! -f "$prompt_file" ]; then
  # allow path relative to workdir
  if [ -f "$workdir/$prompt_file" ]; then
    prompt_file="$workdir/$prompt_file"
  else
    echo "prompt file not found: $prompt_file" >&2
    exit 2
  fi
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  idx="$out/$slug.idx"
  rm -f "$idx"
  GIT_INDEX_FILE="$idx" git add -A >/dev/null 2>&1
  GIT_INDEX_FILE="$idx" git write-tree > "$out/$slug.base.tree"
  rm -f "$idx"
fi

echo "log: $log"
opencode run --auto \
  --standalone \
  --model "softoria/Softoria-HD#$variant" \
  --title "$title" \
  "$(cat "$prompt_file")" > "$log" 2>&1
code=$?
echo "SOFTORIA_EXIT=$code" >> "$log"
echo "SOFTORIA_EXIT=$code"
exit "$code"
