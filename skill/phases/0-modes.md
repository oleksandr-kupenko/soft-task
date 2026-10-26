# Phase 0 — Mode and depth

Read in Phase 0 with `phases/0-preflight.md`. Both dials are decided once, from what the user typed, announced in one block, and only *applied* from then on.

Everything after `/soft-task` splits into **the mode** (`full`, `semi`, `interview`, `manual`), **the depth** (`strict`, `deep`, `task`) and **the brief** — everything else. Bare words, any order, both optional; anything unrecognised is brief. `/soft-task full deep online store` — full mode, deep elaboration. `/soft-task task fix pagination on invoices` — task profile.

Speak the opening block in the **user's language** (en / uk / ru). Templates below are English; translate when they wrote in another language.

## Mode — how much the user is asked

| Mode | Triggers | Human gates |
|---|---|---|
| **full** — full auto | `full`, «полный автомат», «повний автомат», "fully automatic", "don't ask me anything" | none |
| **semi** — semi-auto **(default)** | `semi`, «полуавтомат», «напівавтомат», nothing said | questions, on genuine forks only |
| **interview** | `interview`, «режим интервью», «погриль», "interview me", "ask me everything" | questions, all of them |
| **manual** | `manual`, «ручной режим», «ручний режим», "approve every step" | the same questions + the spec + the tickets |

`interview` asks about the *product*; `manual` is `interview` plus approval of the two *process* artifacts.

- **Ambiguity resolves to semi.**
- **Switchable mid-run** — applies from the next phase; one line of acknowledgement.
- **No mode removes the manifest gates or the safety gates.** Deploy, publish, pay, message a third party, delete data, rewrite history — a question in all four modes, with `st.py ask action --note "…"` before it goes out.

## Depth — how much is worked out for the user

| Depth | Triggers | Deepening (`R##.n`) | New capabilities (`A##`) | Extra |
|---|---|---|---|---|
| **strict** | `strict`, «строго по брифу», «строго за брифом», "strictly as written" | only what the requirement cannot work without | **not allowed** | — |
| **normal** **(default)** | nothing said | by judgement | allowed, with a parent, within proportion | — |
| **deep** | `deep`, «проработай глубоко», «продумай», "go deep" | every dimension | encouraged, same limits | adversarial pass |
| **task** | `task`, «таска», «задача», a pasted ticket / Jira-like text as the whole input | only what the task needs | rare; must name the parent | **T1–T2 cap**; no scaffolding, no `docs/architecture.md` / ADR unless the task asks; never create a memory file — only propose; existing-codebase exploration is the default path |

- `strict` does not mean careless: errors and empty states are still handled.
- `deep` never lifts attachment rules — every `A##` names its parent.
- `task` is the default when the input is clearly a ticket in an existing repo (has ticket id, acceptance criteria, or points at existing paths) and the user did not pick another depth.
- **The adversarial pass** (`phases/2-adversarial.md`) runs at `deep` in every mode, and in `interview` / `manual` at every depth (including `task` only if interview/manual).
- Changeable mid-run — from the next phase.

The rules for each level live in `phases/3-spec.md`.

## The opening block

Once, before Phase 1. **A hint, not a question** — say it and go.

```
Mode: semi · depth: normal — I'll ask only what the task leaves open, then build.
Dashboard: http://localhost:PORT/dashboard.html
Project memory — AGENTS.md (+ CLAUDE.md pointer).
Harness: <opencode|cursor|claude-code|codex> · executor: Softoria-HD · review: <engine> · acceptance: <engine> · helpers: <engine> · vision: Softoria-SD

You can switch anytime:
• "full" — ask nothing
• "interview" — question the task fully, then build
• "manual" — same plus you approve the spec and tickets
• "strict" / "deep" / "task" — less or more elaboration, or task-first profile
```

No server → name the file: `.soft-task/dashboard.html`. Never repeat later; a mid-run switch gets one line.
