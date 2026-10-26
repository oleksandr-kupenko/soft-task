# Harness adapter — OpenCode

Detect: `opencode` is in PATH, or the session was started with `opencode`, or `$OPENCODE_SESSION` is set. Prefer this adapter when the user runs soft-task from OpenCode.

## Orchestrator

You are Softoria-HD (or whatever model OpenCode selected). You dispatch; you do not write project code.

## Background shell — Softoria tickets

Each ticket is a **separate** background bash (OpenCode `run_in_background` / equivalent). Command:

```bash
<skillRoot>/engines/softoria-hd/run.sh tmp/softoria/<run>-NN.prompt.md "<Title>" "$PWD"
```

A wave = several background bashes in one turn, **not** one bash that starts three with `&`.

### Forbidden

```bash
run.sh a … & run.sh b … & sleep 5; tail logs   # orphans the wave
```

Full contract: `phases/5-wait.md`.

## Wait

Rely on the background-task **completion notification**. Peek at `tmp/softoria/<slug>.log` only when landing. Done when the last line is `SOFTORIA_EXIT=<code>`.

If you orphaned a wave: attach one tracked watcher per log (`phases/5-wait.md` recovery); do not relaunch finished tickets.

## Subagent (reviewer = harness)

OpenCode has no Cursor-style Task tool. Review with Softoria-HD:

```bash
<skillRoot>/engines/softoria-hd/run.sh tmp/softoria/<run>-NN-review.prompt.md "review-NN" "$PWD"
```

Always a **fresh** `opencode run --standalone` so review context dies with the review.

## Dashboard

Print `http://127.0.0.1:<port>/dashboard.html` from `st.py init`. Open with `xdg-open` / `open` when not in SSH/CI.

## Vision

```bash
<skillRoot>/engines/vision/see.sh /abs/path/image.png "Describe layout top to bottom. List components."
```
