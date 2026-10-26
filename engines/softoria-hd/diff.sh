#!/usr/bin/env bash
# Show what a Softoria run changed, relative to the snapshot taken by run.sh.
#
# usage: diff.sh <slug> [workdir] [--stat]
#   Prints `git diff` between <slug>.base.tree and the current working copy
#   (including untracked files). The user's git index is not touched.
set -uo pipefail

slug=${1:?slug required (see tmp/softoria/*.base.tree)}
workdir=${2:-$PWD}
mode=${3:-}

cd "$workdir" || exit 2
out="$workdir/tmp/softoria"
base=$(cat "$out/$slug.base.tree") || exit 2

idx="$out/$slug.after.idx"
rm -f "$idx"
GIT_INDEX_FILE="$idx" git add -A >/dev/null 2>&1
after=$(GIT_INDEX_FILE="$idx" git write-tree)
rm -f "$idx"

if [ "$mode" = "--stat" ]; then
  git diff --stat "$base" "$after" -- . ':(exclude)tmp/softoria'
else
  git diff "$base" "$after" -- . ':(exclude)tmp/softoria'
fi
