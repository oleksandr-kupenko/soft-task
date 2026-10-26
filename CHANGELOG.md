# Changelog

## Unreleased

- Dashboard restyled (Netlify-like palette, flat cards, soft hero block); Russian UI language removed, Ukrainian fully translated, EN and UK remain.
- Per-ticket agent: ticket header `**Агент:**` / `**Agent:**`, filled from `config.json` when missing; `st.py ticket NN start|review --agent "…"` overrides it. Shown on the dashboard bars and in the hero line.
- Transparent logo mark, text wordmark in the dashboard header, new favicon, dashboard screenshot on the site and in the README.

## 0.1.4

- **Softoria gateway outages (502).** `run.sh` now retries gateway/network errors in-process (`SOFTORIA_RETRIES`, default 3; `SOFTORIA_BACKOFF`, default `30 90 180`) and resumes the **same opencode session**. The log ends with `SOFTORIA_STATUS=ok|gateway|vpn|auth|error`, `SOFTORIA_RETRIES`, `SOFTORIA_SESSION`; `SOFTORIA_EXIT` stays the last line.
- `run.sh` takes an optional 5th argument `session-id`; prompt `-` sends a built-in «continue after outage» message. Earlier logs with the same title rotate to `<slug>.log.N`; the diff base is kept on resume.
- New `engines/softoria-hd/probe.sh`: one 1-token request that tells `vpn` (no connection) from `gateway` (5xx/429/hang) and `auth`.
- New `engines/softoria-hd/wait-softoria.sh`: a tracked waiter. Its exit wakes the orchestrator, which resumes paused tickets by session (`phases/5-subagents.md` «Gateway down»).
- `doctor` uses the probe; a missing `SOFTORIA_API_KEY` env is a warning when `opencode.json` holds the key.
- New blue–yellow logo (check mark made of tickets) for the dashboard, the site and the README; the dashboard sets it as the tab favicon. Hand-drawn SVG logos removed; master raster: `docs/images/logo-mark-1024.png`.

## 0.1.3

- **Engine routing for every agent** (`skill/phases/engines.md`): new roles `acceptance` (blind checker, G4) and `helper` (repo exploration, G2 reader, ADR, memory, history digest), each configurable as `softoria-hd` | `harness`. Previously these agents had no engine and silently ran on the harness default.
- Adapters: one «Subagent» section for any role set to `harness`; OpenCode and Codex without isolated agents fall back to Softoria-HD.
- Softoria launches for non-executor roles: prompt file, `=== RESULT ===` marker, per-role write allowlist checked with `diff.sh`.

## 0.1.2

- Ukrainian GitHub Pages landing (`docs/index.html`).
- Brand logo (mark + wordmark) for dashboard and site.

## 0.1.1 — 2026-10-26

- **Wait contract** (`phases/5-wait.md`): one Softoria ticket = one tracked Shell; forbid `&` / `nohup` wave packs; ban «I'll check logs later»; recovery via `await-log.sh` when a wave was orphaned.
- Adapters (Cursor / OpenCode / Claude / Codex) updated with the same hard rules.

## 0.1.0 — 2026-10-26

- Initial soft-task fork of Autopilot (nick-vels/skills, MIT).
- Softoria-HD default executor/reviewer; Softoria-SD vision via `engines/vision/see.sh`.
- Harness adapters: OpenCode, Cursor, Claude Code, Codex.
- `task` depth profile for large tasks in existing repos.
- `npx`/local installer with doctor; no upstream update check.
- Dashboard EN / UK / RU; stack detector; HTTP smoke helper.
