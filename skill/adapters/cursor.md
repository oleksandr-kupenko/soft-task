# Harness adapter — Cursor

Detect: Cursor agent session (Task / Shell / AwaitShell tools available).

## Orchestrator

You are the Cursor session model. You dispatch; you do not write project code.

## Background shell — Softoria tickets

**Critical:** each Softoria ticket is its **own** `Shell` tool call with `block_until_ms: 0`. The command is only:

```bash
<skillRoot>/engines/softoria-hd/run.sh tmp/softoria/<run>-NN.prompt.md "<Title>" "$PWD"
```

### Wave of N tickets (example N=3)

In **one** assistant message, emit:

1. Shell (blocking OK): `python3 .soft-task/st.py ticket 02 03 04 start`
2. Shell `block_until_ms: 0` — `run.sh` for ticket 02  
3. Shell `block_until_ms: 0` — `run.sh` for ticket 03  
4. Shell `block_until_ms: 0` — `run.sh` for ticket 04  

Then **end the turn**, or call `AwaitShell` on those background shells.

### Forbidden

- `run.sh A & run.sh B & run.sh C & sleep 5; tail logs` in **one** Shell — the outer command exits in seconds; Cursor stops tracking; when Softoria finishes you are **not** woken. This already caused a multi-hour stall in production.
- `nohup` / `disown` / `setsid` around `run.sh`.
- «I'll check the logs every few minutes» — you have no timer; only user messages and harness notifications wake you.

Full contract: `phases/5-wait.md`.

## Wait

1. Prefer harness completion on each `block_until_ms: 0` shell (end turn and resume on notify).  
2. Or `AwaitShell` on the job id(s).  
3. Fallback if a wave was orphaned: one tracked Shell per ticket that loops until `SOFTORIA_EXIT=` appears in that ticket's log (`phases/5-wait.md` recovery) — still **separate** Shell calls, never `&`.

## Subagent (reviewer = harness)

```
Task tool, subagent_type: generalPurpose
```

Use a capable model for review when `engines.reviewer` is `harness`. Never use `inherit` unless the session model itself is the intended reviewer.

When `engines.reviewer` is `softoria-hd` (default), launch Softoria-HD via `run.sh` the same way as executors (own Shell, `block_until_ms: 0`).

## Dashboard

Open `http://127.0.0.1:<port>/dashboard.html` in the browser pane or with `xdg-open`. Say the address in chat once.

## Vision

```bash
<skillRoot>/engines/vision/see.sh /abs/path/image.png "<question>"
```

Cursor vision subagent is a fallback only when Softoria-SD is unavailable.
