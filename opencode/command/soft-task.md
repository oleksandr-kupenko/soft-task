---
description: "Run soft-task — task-first AI build: brief/ticket → tickets → Softoria-HD → acceptance. Resume with a bare /soft-task."
agent: build
---

# /soft-task

Load and follow the **soft-task** skill (`SKILL.md`) end to end.

1. Resolve the skill directory (installer sets `SOFT_TASK_ROOT`; else look under `~/.claude/skills/soft-task`, `~/.agents/skills/soft-task`, or this package's `skill/`).
2. Read `SKILL.md` and start Phase 0 (`phases/0-modes.md` + `phases/0-preflight.md`).
3. Pass through any arguments after `/soft-task` as mode / depth / brief text.

Do not summarise the skill instead of running it. Do not write project code yourself — dispatch Softoria-HD executors.
