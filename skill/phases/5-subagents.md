# Phase 5 — Build

`st.py stage build`. Where the code gets written. **Identical in all four modes, and hands-free**: manual buys control over *what* gets built, not over each edit.

## One ticket, one executor, one fresh context

Never two tickets in one context — accumulated context is what makes long sessions start breaking what used to work.

**You dispatch; you do not build.** Your keyboard reaches `.soft-task/**`, the memory files, `.gitignore`, `.env.example`, and git (`add`, `commit`, `status`, `--stat` — never the diff). Every other file is written by an executor whose context dies with the ticket. This is rule 5.

## Default engine: Softoria-HD

Read `.soft-task/config.json`. Defaults:

| Role | Engine |
|---|---|
| Executor | Softoria-HD via `engines/softoria-hd/run.sh` |
| Reviewer | Softoria-HD (same), unless `engines.reviewer` is `harness` |
| Vision | Softoria-SD via `engines/vision/see.sh` |

Softoria-HD is **text only**. It never gets a task whose acceptance needs looking at an image. Visual work is split: vision writes a text spec → Softoria builds → vision checks screenshots.

The ticket field `Модель` / `Model` is ignored when the executor is Softoria-HD. The `Агент` / `Agent` field is not: it is what the dashboard shows. When the actual executor differs from it, launch with `st.py ticket NN start --agent "<name>"`.

### Preflight once per run (build stage)

1. `<skillRoot>/engines/softoria-hd/probe.sh` → `PROBE=ok`. `vpn` → ask the user to turn on the corporate VPN. `gateway` → Softoria itself is down; start the gateway waiter (see «Gateway down» below). `auth`/`nokey` → ask the user to check `SOFTORIA_API_KEY`.
2. `opencode --version` works; `engines/softoria-hd/run.sh` exists under `skillDir`.
3. `tmp/softoria/` is git-ignored. If not, add it to `.gitignore`.

### Launching one ticket (Softoria-HD)

1. Write `tmp/softoria/<run>-NN.prompt.md` (English, self-contained). It must contain:
   - ticket path, spec section headings, `interfaces.md`, `notes.md`, `reference.md` — **by path**;
   - required first read: `<skillDir>/prompts/executor.md`;
   - project rules listed in `interfaces.md` (discovered in preflight) — **full paths**; Softoria will not discover them;
   - "Read these first, before the first edit. In the report, list what you read.";
   - its zone, and zones of tickets flying beside it; scoped test commands only;
   - "Do NOT commit. Do NOT touch the git index. Do NOT edit files outside the zone.";
   - the return block from `executor.md` printed at the end.
2. `st.py ticket NN start`, then launch. **Read `phases/5-wait.md` first** — wrong launch shape orphans the wave and the session sleeps until the user pings.

```bash
<skillRoot>/engines/softoria-hd/run.sh tmp/softoria/<run>-NN.prompt.md "<Title>" "$PWD"
```

**One ticket = one harness Shell/Bash call** (`block_until_ms: 0` / `run_in_background: true`). A wave of three = three tool calls in **one assistant message**, not one shell line with `&`. Never `run.sh … &`; never `sleep`+`cat logs` as the wait. After launch, end the turn or `AwaitShell` — you have no clock; «I'll check later» is forbidden.

`skillRoot` is the soft-task install root (parent of `skill/` when installed as a package, or `skillDir` when the skill folder *is* the root). Prefer the path recorded in `config.json` / installer notes; fall back to `$SOFT_TASK_ROOT` or `<skillDir>/..`.

3. **At most three in flight**, zones disjoint.
4. Finished when the tracked shell exits **and** the log ends with `SOFTORIA_EXIT=<code>`. Land on the harness notification, not on a user nudge. Just above it, `run.sh` writes `SOFTORIA_STATUS=` and `SOFTORIA_SESSION=`.
5. Act on `SOFTORIA_STATUS`:

   | Status | Meaning | Action |
   |---|---|---|
   | `ok` | run finished | land the ticket |
   | `gateway` | Softoria returned 5xx/429 after all in-process retries; VPN is fine | «Gateway down» below |
   | `vpn` | no connection to Softoria | tell the user to turn on VPN; on «on» → resume as in «Gateway down» step 3 |
   | `auth` | key rejected or missing | tell the user; do not retry |
   | `error` | executor failed for another reason | read the log tail; `phases/5-repair.md` |

   `run.sh` already retries gateway and network errors itself (`SOFTORIA_RETRIES`, default 3, backoff 30/90/180 s) and resumes the **same session**. Do not add your own retry loop.
6. Orphaned wave (logs already have `SOFTORIA_EXIT=` or processes live with no tracked shell) → recovery in `phases/5-wait.md`; do not relaunch.

### Gateway down

The gateway sometimes returns 502 for minutes. This is not a VPN problem and not a ticket problem. Work done so far stays in the session and in the working tree.

1. Keep the ticket `in-progress`. Do not relaunch it from scratch and do not change its prompt.
2. Start **one** tracked waiter (Shell `block_until_ms: 0` / background bash), not one per ticket:

   ```bash
   <skillRoot>/engines/softoria-hd/wait-softoria.sh 30 60
   ```

   Tell the user in one line: «Softoria gateway down (502); N tickets paused, I resume them when it answers.» Then end the turn or `AwaitShell`. The waiter's exit wakes you.
3. Waiter ends with `SOFTORIA_UP=ok` → for each paused ticket, one tracked Shell:

   ```bash
   <skillRoot>/engines/softoria-hd/run.sh - "<Title>" "$PWD" max <SOFTORIA_SESSION>
   ```

   `-` sends the built-in «continue after outage» message; the diff base stays the same. Empty `SOFTORIA_SESSION` → relaunch with the original prompt file.
4. `SOFTORIA_UP=timeout` → tell the user Softoria is still down after 30 min; ask whether to wait again or stop. `SOFTORIA_UP=auth` → as status `auth`.

### Landing a Softoria ticket

1. Read the return block from the end of the log. Missing → write the request to `tmp/softoria/<run>-NN.more.md` and resume in a new tracked Shell: `run.sh tmp/softoria/<run>-NN.more.md "<Title>" "$PWD" max <SOFTORIA_SESSION>`.
2. `<skillRoot>/engines/softoria-hd/diff.sh <slug> "$PWD" --stat` — only zone paths? Outside → `phases/5-repair.md`.
3. Re-run the ticket's scoped tests yourself. The report is not evidence.
4. `BLOCKED` / `NEEDS_CONTEXT` → `phases/5-repair.md`. Relaunch with a fuller prompt, not another model.
5. Append `INTERFACES` to `interfaces.md`, commit the zone, `st.py ticket NN done`.

### Visual tickets

Mark `**Visual:** yes` (or `**Визуал:** да`) in Phase 4 when acceptance includes how it looks. Three steps:

1. **Visual spec — before Softoria starts.** Run vision on the design images named by the ticket; write `.soft-task/<dir>/visual/NN.md` (layout top to bottom, spacing, reuse, tokens, states, texts). Words only — no "see the image". Attach by path to the Softoria prompt.
2. **Build.** Softoria builds from the ticket and the visual spec.
3. **Visual acceptance — after the commit.** Screenshot via `engines/playwright/shot.mjs` (or the project's visual-check skill), then `engines/vision/see.sh` with the acceptance list. Returns a **text fix list**. Empty → done. Else resume Softoria with the list — **at most two rounds**. Still failing → orchestrator may ask a harness vision-capable agent to fix remaining markup/SCSS inside the zone, and says so in one line. Never loop a third time.

## What an executor gets — paths, not contents

| | |
|---|---|
| `prompts/executor.md` | by path (`skillDir` in `state.js`), **required before the first edit** |
| its ticket | by path; carries verbatim brief quotes |
| the spec sections the ticket names | `spec.md` by path **and section headings** |
| `interfaces.md` | by path, read first |
| `notes.md` / `reference.md` | by path when present |
| the check command | from `interfaces.md` |
| its zone | zones of tickets in flight included |
| credentials | variable **names**, never values |

Every rule the executor must follow travels in its prompt or in `prompts/executor.md`.

**Dependencies.** Ticket 01 installs what the spec's implementation decisions name. A later ticket that needs something else returns `BLOCKED`; if it fits a decided choice, amend «Implementation decisions», relaunch with permission to install exactly that.

## Waves

Phase 4 gave every ticket a wave and a zone. **Launch a whole wave in one assistant message** — meaning several parallel Softoria Shell calls plus `st.py ticket … start`, not one compound shell.

- **At most three in flight.**
- **Zones disjoint** — when in doubt, serialise.
- **A wave is not a barrier.** When a ticket returns, first launch the next whose dependencies are committed, then process the one that landed.
- **A dependent never launches on an uncommitted parent.**
- `st.py ticket 02 03 start` goes **before** the Softoria launches, in the same message.
- **Waiting for the wave is ending your turn** (or `AwaitShell`). Details and recovery: `phases/5-wait.md`.

## The return contract

```
STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
FILES: created and changed — paths only
TESTS: check command → result and prior count
REDPROOF: new test → how it failed before the code (one line each, ≤5)
INTERFACES: public signatures / schemas / event formats you exposed
REQUIREMENTS: R01 done | R01.1 placeholder — <what was missing>
CONCERNS: done with caveats and why
BLOCKERS: what was missing
```

**No more than 25 lines, no code, no diffs.**

## After each ticket

1. **Read the contract.** No block → ask again. `BLOCKED` / `NEEDS_CONTEXT` / plan-breaking `CONCERNS` → `phases/5-repair.md`.
2. **Nothing outside the zone.** `git status --porcelain`.
3. **Append `INTERFACES` to `interfaces.md`** — you, never the executors.
4. **Run the check**, full, truncated: `<check> 2>&1 | tail -30`, and read it.
5. **Red → `phases/5-repair.md`.** Nothing committed on red; you do not repair.
6. **Commit and record — one call, only its zone:**

   ```bash
   git add -A -- <zone-paths> .env.example && git commit -qm "T03: accept request" \
     --trailer "Soft-Task-Run: 2026-10-26-repair-bot" --trailer "Requirements: R01, R02" -- <zone-paths> .env.example \
     && python3 .soft-task/st.py ticket 03 done --tests 34/0 --commit "$(git rev-parse --short HEAD)"
   ```

7. **Point review** if the ticket says `Review: yes` / `Ревью: да`, or a requirement is incomplete — `st.py ticket NN review`, then `phases/6-review.md`.
8. **The ledger.** Stubs → `add debt.placeholders`; empty env → `add debt.emptyEnv NAME`; `A##` → `add additions`; craft concerns → `add concerns`.
9. **One plain line to the user** in their language: what became possible, and the count.

**Two tickets returning together are processed one at a time.**

## When the build is over

Every ticket is `done`, or `failed` with dependents named. Then `st.py stage review` and `phases/6-review.md`.
