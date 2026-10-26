---
name: soft-task
description: Task-first AI build framework — brief or ticket → requirements → tickets → Softoria-HD executors → review → acceptance, with a live dashboard. Works as orchestrator under OpenCode, Cursor, Claude Code, or Codex. Starts on /soft-task; a bare /soft-task resumes an interrupted run.
disable-model-invocation: true
argument-hint: "[full|semi|interview|manual] [strict|deep|task] <brief path | ticket text | what to build>"
metadata:
  version: "0.1.1"
---

# soft-task

soft-task takes a **task or a brief** and delivers working code **in one dialogue**, without making the user approve each stage. Rules live in `phases/` and `prompts/`; engines and harness adapters live beside them.

**Built for large tasks in existing codebases**, not only greenfield MVPs. A `task` depth profile keeps the flight light (T1–T2, no scaffolding/ADR unless asked).

**The order is the product.** Code is written in the second-to-last phase. Everything before it decides *what* to build; everything after it proves the right thing got built.

**The brief is the contract, not the design.** *Nothing may quietly vanish*: the user's words become a numbered manifest before anything else, and every phase is gated on it. The brief is a silhouette of the happy path — empty states, failures and limits are legitimate work, bounded by the [depth](phases/0-modes.md) dial. Depth that **detaches** from the brief is never allowed.

## Roles

| Role | Default | Override |
|---|---|---|
| **Orchestrator** (you) | the session agent — OpenCode, Cursor, Claude Code, or Codex | — |
| **Executor** (every ticket) | Softoria-HD via `opencode run` | `.soft-task/config.json` → `engines.executor` |
| **Reviewer** | Softoria-HD (same engine), or the harness subagent | `engines.reviewer`: `softoria-hd` \| `harness` |
| **Vision** | Softoria-SD via `engines/vision/see.sh` | `engines.vision` |

Read `adapters/<harness>.md` once in preflight for how *this* session runs background shells, waits, and opens the dashboard. Read `phases/5-subagents.md` for how tickets are launched (Softoria-HD is the default engine).

## Reading this skill

This file is the orchestrator: order, gates, the rules that never lose. Each phase's rules are in its own file, **read when that phase starts and not before**.

| Phase | Read | Produces |
|---|---|---|
| 0 Preflight | `phases/0-modes.md`, `phases/0-preflight.md`, then `0-memory.md`, `0-instruments.md`, `adapters/<harness>.md` | mode announced, config written, dashboard open |
| 1 Manifest | `phases/1-manifest.md` | `<date>-brief.md`, `manifest.md` |
| 2 Briefing | `phases/2-briefing.md` (+ `2-adversarial.md` when it runs) | answers recorded into the manifest |
| 3 Spec | `phases/3-spec.md` | `notes.md`, `spec.md`, `interfaces.md` |
| 4 Plan | `phases/4-plan.md` | `tickets/NN-*.md`, the plan commit |
| 5 Build | `phases/5-subagents.md` + `phases/5-wait.md` (launch/wait contract — never orphan Softoria) | code, one commit per ticket |
| 6 Review | `phases/6-review.md` | reviewed code |
| 8 Final | `phases/8-final.md`, `phases/9-memory.md` | blind acceptance, memory proposal, report |
| — | `phases/0-resume.md` — instead of preflight, when resuming | |
| — | `phases/5-repair.md` — when a ticket is not a clean `DONE` | |
| — | `phases/rationalizations.md` — on a failed gate, once before the report | |

**After a compaction, re-read the state, not the phases:** `state.js` (holds `dir` and `skillDir`), `manifest.md`, `interfaces.md`, `config.json`, `carried.md` if present, and the file of the phase you are in.

## The words the user sees

Phase names in this skill are English and never shown. Speak to the user **in the language they used** (English, Ukrainian, or Russian). The dashboard has an en/uk/ru switch; default stage labels:

| Stage id | en | uk | ru |
|---|---|---|---|
| `preflight` | Setup | Підготовка | Подготовка |
| `manifest` | Requirements | Вимоги | Требования |
| `briefing` | Briefing | Брифінг | Брифинг |
| `spec` | Spec | Специфікація | Спецификация |
| `plan` | Plan | План | План |
| `build` | Build | Розробка | Разработка |
| `review` | Review | Код-рев'ю | Код-ревью |
| `final` | Acceptance | Приймання | Приёмка |

The whole flight is the «run»; a ticket is the unit of work; the user's request is the «task».

## The flight

Two dials, decided once in Phase 0 (`phases/0-modes.md`): **mode** — `full`, `semi` (default), `interview`, `manual`; **depth** — `strict`, normal (default), `deep`, or **`task`** (task-first: T1–T2 cap, skip scaffolding/ADR).

| Phase | full | semi | interview | manual |
|---|---|---|---|---|
| 1 Manifest | auto | auto | auto | auto |
| 2 Briefing | self-briefing | only what the brief leaves open | adversarial, then every fork | the same |
| 3 Spec | auto | auto | auto | show → wait for «ok» |
| 4 Plan | auto, notify | auto, stoppable | auto, stoppable | discuss → wait for «ok» |
| 5 Build · 6 Review | auto | auto | auto | auto |
| 8 Final | report + Assumptions | report | report | report |

**Manifest gates in every mode:**

| Gate | After | Passes when |
|---|---|---|
| **G1** | Briefing | every requirement has a status; none `open` without a recorded reason |
| **G2** | Spec | zero `open` — and an independent reader given only the brief and the spec finds nothing missing |
| **G3** | Plan | every `in-spec` requirement is in a ticket and every ticket traces to one — `st.py check-plan` |
| **G4** | Final | blind acceptance against the brief, spec withheld |

**The plan may be corrected; the brief may not.** When the build proves the plan wrong, the spec is amended and a `D##` row records what the code demonstrated (`phases/5-repair.md`).

## Secrets

- **Never request one.** Which provider / whether an account exists are questions; the key never is.
- **Redact at ingest** (`phases/1-manifest.md`). «Verbatim» means after redaction.
- **Refer by name** — `STRIPE_SECRET_KEY`. User fills `.env`; report lists empty names.
- **A leaked secret is a stop** — `st.py ask stop`, tell the user to rotate.

## Files this skill owns

```
.soft-task/
├── config.json             engines + harness + language
├── <YYYY-MM-DD>-<slug>--wip/
│   ├── <date>-brief.md · manifest.md · spec.md · interfaces.md · notes.md
│   ├── reference.md · carried.md · memory-proposal.md · visual/
│   └── tickets/NN-<slug>.md
├── README.md · PROGRESS.md · state.js · st.py · dashboard.html · index.html
```

`.soft-task/` is committed. Spec is throwaway once the work ships.

## Judgement

Numbers in this skill are calibration, never targets — except the rules that set the run's cost (repair loops, point reviews). Break those only by telling the user what it will cost.

**Five rules never lose:**

1. A requirement is removed only by the user, in their own words.
2. A secret is never requested, echoed or written.
3. A fact about the user is never invented.
4. An irreversible or outward-facing action is a question.
5. **The orchestrator does not write the project's code.** Its keyboard reaches `.soft-task/`, memory files, `.gitignore`, `.env.example` and git; everything else goes to an executor (`phases/5-subagents.md`).

## When to use it

The user has a **large task** (or a brief) and expects the finished thing without reviewing specs or code. «Збери під ключ», "just build it", «собери».

**Not:** co-writing code line by line; a small single-file change (just do it); an idea bigger than one project whose destination is unclear.
