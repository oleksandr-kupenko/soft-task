# Phase 5 — Wait contract (do not orphan a wave)

**Read with `phases/5-subagents.md` before every Softoria launch.** This file exists because an orchestrator can silently stall for an hour: the tickets finish, nothing wakes the session.

## How you wake up

Your next turn starts only when:

1. the **user** sends a message, or  
2. the **harness** notifies you that a tracked background job finished (`AwaitShell` / background-task completion).

You have **no clock**. Promises like «I'll check the logs every few minutes» are void — there is no mechanism behind them. If nothing is tracking the Softoria processes, you will sleep until the user pings.

## Hard rules (Cursor and any Shell-based harness)

| Do | Do not |
|---|---|
| **One Softoria ticket = one Shell / Bash tool call** | Pack `run.sh … & run.sh … & sleep 5; cat logs` into a single command |
| `block_until_ms: 0` (or harness `run_in_background: true`) on **each** of those calls | Background with shell `&` inside one tracked command — the outer command exits in seconds and the harness forgets the children |
| Launch the whole wave as **several tool calls in one assistant message** (parallel) | Launch wave 2 differently from ticket 01 «to save a turn» |
| After launch: **end the turn**, or call **`AwaitShell`** (or the harness wait) on those job ids | Say you will poll later and stop |
| Treat a completion notification as the next work unit — land that ticket | Wait for the user to ask «how's it going?» before landing |

### Forbidden patterns (copy-paste killers)

```bash
# BAD — outer shell exits ~10s later; Softoria children are invisible to the harness
run.sh a.prompt.md "t02" "$PWD" &
run.sh b.prompt.md "t03" "$PWD" &
run.sh c.prompt.md "t04" "$PWD" &
sleep 5
tail tmp/softoria/*.log
```

```bash
# BAD — nohup / disown / setsid that detaches from the tool's process tree
nohup run.sh … >/dev/null 2>&1 &
```

```text
# BAD — a promise without a waiter
"I'll check the logs every few minutes"
```

### Correct wave (Cursor)

In **one** assistant message:

1. `python3 .soft-task/st.py ticket 02 03 04 start` (one Shell, short, blocking is fine).  
2. Shell `block_until_ms: 0` → `run.sh … "t02" …`  
3. Shell `block_until_ms: 0` → `run.sh … "t03" …`  
4. Shell `block_until_ms: 0` → `run.sh … "t04" …`  

Then either:

- **end the turn** (harness wakes you per finished shell), or  
- **`AwaitShell`** on those background ids (preferred when the harness supports waiting on several).

`run.sh` already writes `tmp/softoria/<slug>.log` and ends with `SOFTORIA_EXIT=<code>`. You do not wrap it in `&`.

### Correct wave (OpenCode / Claude Code)

Same shape: **one background bash per ticket**, not one bash that backgrounds three. Wait on the completion notification, not on `sleep`.

## After a ticket finishes

On notification (or when you discover `SOFTORIA_EXIT=`):

1. Land that ticket (`phases/5-subagents.md` — diff, tests, commit, `st.py ticket NN done`).  
2. Launch the next ready ticket if a slot is free.  
3. Do not batch-wait for the whole wave if one ticket is already done — land early, keep the pipeline moving.

## Recovery — if you (or a prior turn) orphaned a wave

Symptoms: tickets marked `in-progress` on the dashboard, logs already contain `SOFTORIA_EXIT=`, user asks why nothing happens, or you find `opencode` / Softoria processes with no tracked shell.

1. **Do not relaunch** those tickets.  
2. For each in-flight ticket, `tail -5 tmp/softoria/<slug>.log`:  
   - has `SOFTORIA_EXIT=` → land it now (same as a notification).  
   - no exit line but process still alive → adopt wait: `AwaitShell` on the PID if known, else one **tracked** Shell per ticket (`block_until_ms: 0`):

     ```bash
     <skillRoot>/engines/softoria-hd/await-log.sh <slug> "$PWD"
     ```

     Never three watchers in one command with `&`.  
3. Tell the user in one line that the wave was orphaned and you re-attached waiters — then end the turn.

## What you may say to the user

- «Wave 2 out — three Softoria jobs tracked; I'll continue when each finishes.»  
- Not: «I'll peek at the logs in a bit.»

If the harness has no background tracking at all, say so once and use the **log watcher** pattern above as the only wait mechanism.
