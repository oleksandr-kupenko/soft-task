#!/usr/bin/env bash
# Detect the project's test stack and print JSON: {"stack":"...","command":"..."}
# usage: detect-stack.sh [workdir]
set -euo pipefail
cd "${1:-$PWD}"

stack=""
cmd=""

if ls *.sln >/dev/null 2>&1 || ls *.csproj >/dev/null 2>&1 || find . -maxdepth 3 -name '*.csproj' | grep -q .; then
  stack="dotnet"
  cmd="dotnet test"
elif [ -f composer.json ]; then
  stack="php"
  if [ -x vendor/bin/pest ] || grep -q '"pestphp/pest"' composer.json 2>/dev/null; then
    cmd="./vendor/bin/pest"
  elif [ -x vendor/bin/phpunit ]; then
    cmd="./vendor/bin/phpunit"
  else
    cmd="./vendor/bin/phpunit"
  fi
elif [ -f go.mod ]; then
  stack="go"
  cmd="go test ./..."
elif [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -f setup.py ]; then
  stack="python"
  cmd="pytest"
elif [ -f Cargo.toml ]; then
  stack="rust"
  cmd="cargo test"
elif [ -f package.json ]; then
  stack="node"
  if grep -q '"test"' package.json; then
    cmd="npm test"
  elif [ -f nx.json ]; then
    cmd="npx nx test"
  else
    cmd="npm test"
  fi
fi

if [ -z "$stack" ]; then
  printf '{"stack":null,"command":null}\n'
else
  printf '{"stack":"%s","command":"%s"}\n' "$stack" "$cmd"
fi
