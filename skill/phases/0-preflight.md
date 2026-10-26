# Phase 0 — Preflight

Configure the repo, pick the project memory, raise the instruments. Decide which case you are in **before** doing anything else — first match wins:

| On disk | Case | What happens |
|---|---|---|
| `state.js` with `finishedAt: null`, `updatedAt` under five minutes old **and** the server in `.soft-task/serve.pid` answering | **the run is going on in another window** | nothing — say so in one line and ask which window carries on |
| `state.js` with `finishedAt: null` | **resume** | read `phases/0-resume.md` and follow it instead of this file |
| `state.js` with `finishedAt` set | **new feature in a configured repo** | everything below; `init` archives the finished run's state into its own directory |
| no `.soft-task/state.js` | **new run** | everything below, in order |

**«Finish this too» for a flight that already landed**: new dated brief in the same run directory (`phases/1-manifest.md`), `python3 .soft-task/st.py reopen`. Landed tickets stay landed.

**Nothing here is a question for the user.** Where files live is a process decision.

## 1. Look before writing

- `git rev-parse --git-dir` — is this a repo?
- `CLAUDE.md`, `AGENTS.md` — for `phases/0-memory.md`.
- Stack markers — for the check command (§1b):
  - `*.sln` / `*.csproj` → .NET
  - `composer.json` → PHP
  - `package.json` → Node
  - `pyproject.toml` / `pytest.ini` / `setup.py` → Python
  - `go.mod` → Go
  - `Cargo.toml` → Rust
- **Existing code at all** — explore before the spec (`phases/3-spec.md`). Default path for `task` depth.
- `CONTEXT.md`, `GLOSSARY.md`, `docs/adr/` — project vocabulary; flag contradictions, do not silently override.
- `.soft-task/PROGRESS.md` — what the last run left; §6.

### 1b. Stack detector → check command

Write into `.soft-task/config.json` under `check`, and later into `interfaces.md`:

| Stack | Prefer |
|---|---|
| .NET | `dotnet test` |
| PHP + Pest | `./vendor/bin/pest` |
| PHP + PHPUnit | `./vendor/bin/phpunit` |
| Node (npm test script) | `npm test` |
| Node (nx) | `npx nx test <project>` when obvious |
| Python | `pytest` |
| Go | `go test ./...` |

If several match, pick the one the repo already documents in README/`AGENTS.md`. If none, leave `check.command` null and record that in `interfaces.md` — tickets must still propose a scoped command.

### 1c. Project rules discovery

Scan and list **full paths** into a draft that Phase 3 copies into `interfaces.md` under «Project rules»:

- `AGENTS.md`, `CLAUDE.md`, `CONTEXT.md`
- `.cursor/rules/**/*.mdc`, `.cursor/rules/**/*.md`
- `.claude/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md`
- Project-local soft-task notes if any

Do not paste their contents into your context — paths only. Executors receive the matching paths in their prompt.

## 2. Harness + config

Detect the harness (OpenCode / Cursor / Claude Code / Codex) from available tools and env. Read `adapters/<harness>.md` and `phases/engines.md` once.

Copy `config.default.json` → `.soft-task/config.json` if missing. Set `harness`, `language` (`auto` or en/uk/ru from the user's message), `profile` (`task` when depth is task), and keep engine defaults unless the user named overrides — «рев'ю/приймання/допоміжні агенти субагентом Cursor» → `engines.reviewer` / `acceptance` / `helper` = `harness`. A config without `acceptance` or `helper` (older run) gets them added as `softoria-hd`.

## 3. Git

No repo → `git init` now. Write `.gitignore` with at least `.env`, `.env.*`, `!.env.example`, `node_modules/`, `__pycache__/`, `.DS_Store`, `tmp/softoria/`. `.soft-task/` is **committed**; only `serve.*` is ignored (`init` adds that). First commit at end of Phase 4.

Dirty tree → say so in one line and continue; never stash/reset/clean; never commit the user's unrelated work.

## 4. Project memory

**Read `phases/0-memory.md`**. In **`task` depth**: never create a new memory file; if none exists, skip creation and only propose at the end.

## 5. Instruments

**Read `phases/0-instruments.md`**: copy the template and `st.py`, run `init`, open the dashboard.

Slug is short, kebab-case, latin; never changes mid-flight. Every path is built from `dir` in `state.js`.

## 6. What the last run left

Only when a run has landed — `PROGRESS.md` exists, or a commit `soft-task: run landed` does.

```bash
L=$(git log -1 --format=%h --grep='^soft-task: run landed')
git log --oneline --no-merges "$L"..HEAD -- . ':(exclude).soft-task'
```

Write `.soft-task/<dir>/carried.md`. Offer unfinished items in Phase 2; in full mode take none.

## 7. Announce and go

Opening block from `phases/0-modes.md` (user's language). Then `python3 .soft-task/st.py stage manifest` and Phase 1.
