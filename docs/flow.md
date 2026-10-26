# soft-task flow

See also the diagrams in [`images/`](images/) and the root [README](../README.md).

## Stages

1. **Setup** — detect harness, write `.soft-task/config.json`, open dashboard  
2. **Requirements** — redact secrets, write brief + numbered manifest  
3. **Briefing** — close open forks (mode-dependent)  
4. **Spec** — explore existing code (`notes.md`), write `spec.md` + `interfaces.md`  
5. **Plan** — tickets with zones/waves; `st.py check-plan` (G3)  
6. **Build** — Softoria-HD executors; vision for UI tickets  
7. **Review** — point reviews + whole-branch review  
8. **Acceptance** — blind check against the brief (G4); HTTP smoke / screenshots as needed  

## Engines

| Role | Default |
|---|---|
| Executor | Softoria-HD (`engines/softoria-hd/run.sh`) |
| Reviewer | Softoria-HD (or `harness`) |
| Acceptance (G4) | Softoria-HD (or `harness`) |
| Helper (exploration, G2, ADR, memory) | Softoria-HD (or `harness`) |
| Vision | Softoria-SD (`engines/vision/see.sh`) |

Override in `.soft-task/config.json`.
