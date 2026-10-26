# Engines — who runs every agent you launch

Read once in preflight, with `adapters/<harness>.md`. **Every agent launch in every phase is routed here.** A phase file that says «subagent», «fresh reviewer», «independent reader» or «agent» means: look up its role below and launch it the way this file says. Never fall back to «whatever the harness does by default» — that silently moves work off the engine the user configured.

## Roles

| Role | Config key | Default | Who it is | Variant |
|---|---|---|---|---|
| **executor** | `engines.executor` | `softoria-hd` | every ticket, its repairs, `F1` | `max` |
| **reviewer** | `engines.reviewer` | `softoria-hd` | point review, re-review of a repair, whole-branch review (`phases/6-review.md`) | `max` |
| **acceptance** | `engines.acceptance` | `softoria-hd` | the blind checker, gate G4 (`phases/8-final.md` §1) | `max` |
| **helper** | `engines.helper` | `softoria-hd` | agents that write no project code: repo exploration → `notes.md` and the G2 coverage reader (`phases/3-spec.md`); ADR and memory agents (`phases/9-memory.md`); git-history digest (`phases/0-memory.md`) | `high` |
| **vision** | `engines.vision` | `softoria-sd` | design specs and screenshot QA via `engines/vision/see.sh` | — |

Values: `softoria-hd` or `harness`. `vision` takes only `softoria-sd`.

- **`softoria-hd`** — a fresh `opencode run --standalone` through `<skillRoot>/engines/softoria-hd/run.sh`. Same shape as an executor: its own background shell, the wait contract in `phases/5-wait.md`.
- **`harness`** — a fresh isolated subagent of this session, through the call in `adapters/<harness>.md` («Subagent»). Never yourself, never a subagent kept alive from an earlier launch.
- **`engines.executor: harness` is not supported yet.** If the config or the user asks for it, say so in one line and run the executor on `softoria-hd`.
- **The harness has no isolated subagent** (OpenCode; Codex builds without one) → `harness` falls back to `softoria-hd`. Say it once, in preflight.

## Launching a non-executor role on Softoria-HD

1. **Prompt file** — `tmp/softoria/<run>-<role>[-NN].prompt.md`, e.g. `…-review-03`, `…-acceptance`, `…-g2`, `…-notes`, `…-adr`, `…-memory`. It holds the quoted brief from the phase file **word for word**, the files it receives **by path**, the files it must never open, and this closing line:

   > When you are done, print a line `=== RESULT ===` and after it your full answer in the format asked above. Nothing after the answer.

2. **Launch** — one background shell per launch, never `&` packs:

   ```bash
   <skillRoot>/engines/softoria-hd/run.sh tmp/softoria/<run>-<role>.prompt.md "<run>-<role>" "$PWD" <variant>
   ```

3. **Read the answer** — the text after the last `=== RESULT ===` in `tmp/softoria/<slug>.log`. No marker → resume once with `-s <sessionID>` asking for the result block; still none → treat the role as not run and say so in the report.

4. **Check what it touched** — `<skillRoot>/engines/softoria-hd/diff.sh <slug> "$PWD" --stat`. Each role may write only:

   | Role | May write in the working tree |
   |---|---|
   | reviewer, acceptance, G2 reader, history digest | nothing |
   | exploration | `.soft-task/<dir>/notes.md` |
   | ADR | `docs/adr/**` |
   | memory | the memory file, or `.soft-task/<dir>/memory-proposal.md` when the file is the user's |

   The diff also shows what executors flying beside it wrote. **Ignore paths inside the zones of tickets in flight** during the launch; the rest is this role's.

   Anything else → `git restore --worktree -- <paths>` (delete new untracked files), one line in `st.py add concerns`, and use the answer anyway — the finding stands, the stray edit does not.

5. **Acceptance works in a clone**, as its brief says, so its working tree stays clean by construction. Softoria-HD is text-only: when the brief has a UI, add to its prompt the paths to `<skillRoot>/engines/playwright/shot.mjs` and `<skillRoot>/engines/vision/see.sh` and tell it to judge screens through them, not by reading markup.

## Parallel launches

The phase files say what goes out together — the blind checker with the ADR agent, a point review beside the next wave. On Softoria that is several background shells **in one message**, each its own tool call. At most three Softoria processes in flight across all roles.
