# soft-task

**Task-first AI build framework.** You give a brief or a ticket; soft-task turns it into requirements, a plan, Softoria-HD executors, review, and blind acceptance — with a live dashboard.

Derived from [Autopilot](https://github.com/nick-vels/skills) (MIT). See [NOTICE](NOTICE).

![Roles](docs/images/roles.svg)

![Flow](docs/images/flow.svg)

```mermaid
flowchart LR
  User --> Orchestrator
  Orchestrator -->|ticket prompt| Executor[Softoria-HD]
  Orchestrator -->|review prompt| Reviewer[Softoria-HD or harness]
  Orchestrator -->|screenshot| Vision[Softoria-SD]
  Executor --> Repo[(git tree)]
```

## Why soft-task

| Problem | soft-task |
|---|---|
| Vibecoding loses requirements by the third rewrite | Numbered **manifest** + gates G1–G4 against *your* words |
| Long agent sessions rot context | **One ticket → one fresh Softoria-HD process** |
| Company tools are Softoria, not Claude | Default executor / reviewer / vision = Softoria HD & SD |
| Real work is large tasks in existing repos | **`task` depth**: T1–T2, no scaffolding/ADR unless asked |
| Everyone uses a different agent | Orchestrator = OpenCode, Cursor, Claude Code, or Codex |

## Quick install

```bash
# from a clone (no npm publish required)
git clone https://github.com/oleksandr-kupenko/soft-task.git soft-task
cd soft-task
node bin/soft-task.mjs install --harness all --yes

export SOFT_TASK_ROOT="$PWD"
export SOFTORIA_API_KEY="…"   # never commit this

node bin/soft-task.mjs doctor
```

Later, from any machine:

```bash
npx github:oleksandr-kupenko/soft-task install --harness all --yes
```

`--yes` merges the Softoria provider + vision agent into `~/.config/opencode/opencode.json` with `apiKey: "{env:SOFTORIA_API_KEY}"`. Existing keys are never read or copied.

## Run a task

In OpenCode / Cursor / Claude Code / Codex, after install:

```text
/soft-task task Fix invoice pagination — accept criteria in the pasted ticket below
```

or

```text
/soft-task semi path/to/brief.md
```

Modes: `full` · `semi` (default) · `interview` · `manual`  
Depth: `strict` · `normal` (default) · `deep` · **`task`**

The agent opens a dashboard at `http://127.0.0.1:<port>/dashboard.html` (EN / UK / RU).

## Layout

```
soft-task/
  bin/soft-task.mjs          install · doctor · uninstall
  skill/                     orchestrator skill (SKILL.md + phases + adapters)
  engines/
    softoria-hd/             run.sh · diff.sh
    vision/                  see.sh (Softoria-SD)
    playwright/              shot.mjs
    testing/                 detect-stack.sh · http-smoke.sh
  opencode/                  provider fragment + /soft-task command
  docs/                      flow + diagrams
```

Per project, soft-task writes `.soft-task/` (committed): brief, manifest, spec, tickets, dashboard state.

## Roles

1. **Orchestrator** — your session agent. Reads phases, runs `st.py`, never writes app code.  
2. **Executor** — Softoria-HD via `opencode run --standalone` (fresh context per ticket).  
3. **Reviewer** — Softoria-HD by default; set `engines.reviewer: "harness"` to use the host agent’s subagent.  
4. **Vision** — Softoria-SD through `engines/vision/see.sh` for design specs and screenshot QA.

Harness details: `skill/adapters/{opencode,cursor,claude-code,codex}.md`.

## Testing helpers

- `engines/testing/detect-stack.sh` → `.NET` / PHP / Node / Python / Go check command  
- Scoped tests in each ticket; orchestrator re-runs them before commit  
- `engines/testing/http-smoke.sh` for API blind acceptance  
- `engines/playwright/shot.mjs` + `see.sh` for UI tickets  

## FAQ

**VPN?** Softoria API needs the corporate VPN. If a run hangs or returns 5xx, turn VPN on and retry — do not debug anything else first.

**No vision?** Softoria-HD is text-only. Visual tickets always go through Softoria-SD (`see.sh`). Backend-only tasks skip vision.

**Backend (.NET / PHP)?** Use `task` depth. Stack detector picks `dotnet test` / Pest / PHPUnit. Add `smoke.urls` for G4 HTTP checks.

**Update?** Re-run `install`. There is no phone-home update check.

**Secrets?** soft-task never asks for key *values*. Set `SOFTORIA_API_KEY` yourself. Briefs are redacted before they hit disk.

## License

MIT. Upstream attribution in [NOTICE](NOTICE).
