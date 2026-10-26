# Harness adapter — Codex

Detect: Codex / ChatGPT agent CLI session.

## Orchestrator

You are the Codex session model. You dispatch; you do not write project code.

## Background shell — Softoria tickets

```bash
<skillRoot>/engines/softoria-hd/run.sh tmp/softoria/<run>-NN.prompt.md "<Title>" "$PWD"
```

If the harness supports background jobs: **one job per ticket**, never `run.sh … &` packs. If it does not: run tickets **serially** (still correct) or use the log-watcher pattern from `phases/5-wait.md` as the tracked wait.

## Wait

Prefer harness job completion. Else one tracked process per ticket:

```bash
while ! grep -q '^SOFTORIA_EXIT=' tmp/softoria/<slug>.log 2>/dev/null; do sleep 30; done
```

Never promise to «check later» without such a waiter.

## Subagent (reviewer = harness)

If Codex can spawn an isolated agent, use that. Otherwise Softoria-HD via `run.sh` with a review prompt.

## Dashboard

Print and open `http://127.0.0.1:<port>/dashboard.html`.

## Vision

```bash
<skillRoot>/engines/vision/see.sh /abs/path/image.png "<question>"
```
