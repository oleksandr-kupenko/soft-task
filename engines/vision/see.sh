#!/usr/bin/env bash
# Ask Softoria-SD (vision agent) about one image. Text-only stdout for the orchestrator.
#
# usage: see.sh <image-path> "<question>" [workdir]
#
# Requires: opencode, vision agent in opencode.json (soft-task install configures it),
#           Softoria API reachable (corporate VPN).
#
# The image MUST be passed with -f/--file. Paths inside the prompt alone do not work
# with `opencode run` (single-turn; tool-calls never complete).
set -euo pipefail

image=${1:?image path required}
question=${2:?question required}
workdir=${3:-$PWD}

if [ ! -f "$image" ]; then
  echo "error: image not found: $image" >&2
  exit 2
fi

# Resolve to absolute path (opencode -f needs a real file)
case "$image" in
  /*) abs="$image" ;;
  *) abs="$(cd "$(dirname "$image")" && pwd)/$(basename "$image")" ;;
esac

cd "$workdir" || exit 2

# --pure: disable plugins. --agent vision: tools disabled, steps:1 (see opencode pack).
# -- before the prompt: -f is an array flag in yargs.
exec opencode run --auto --standalone --pure --agent vision \
  -f "$abs" -- "$question"
