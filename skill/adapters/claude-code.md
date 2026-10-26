# Harness adapter — Claude Code

Detect: Claude Code session (`Agent` tool, `Bash` with `run_in_background`, optional `preview_start`).

## Orchestrator

You are the Claude Code session model. You dispatch; you do not write project code.

## Background shell — Softoria tickets

**One ticket = one** `Bash` with `run_in_background: true`:

```bash
<skillRoot>/engines/softoria-hd/run.sh tmp/softoria/<run>-NN.prompt.md "<Title>" "$PWD"
```

Wave = several background Bash calls in one message. **Never** one Bash that backgrounds three with `&` — the parent exits and you lose completion events (`phases/5-wait.md`).

## Wait

Use the background-task completion notification. Peek at `tmp/softoria/<slug>.log` only when landing. Orphan recovery: per-ticket log watcher, separate Bash each (`phases/5-wait.md`).

## Subagent (reviewer = harness)

```
Agent tool — fresh agent per review
```

When `engines.reviewer` is `softoria-hd` (default), use `run.sh` instead (same background rules).

## Dashboard

Preferred: `preview_start({ url: "http://localhost:PORT" })` then navigate to `/dashboard.html`. Also print the address in chat.

## Vision

```bash
<skillRoot>/engines/vision/see.sh /abs/path/image.png "<question>"
```
