# Changelog

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
