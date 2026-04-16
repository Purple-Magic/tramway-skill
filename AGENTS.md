# Repository Instructions

## Scope

These instructions apply to the entire `tramway-skill` repository.

## End-of-Task Skill Sync

At the end of every task that changes this repository, run these commands from the repo root:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ./skills/tramway-skill
rm -rf ~/.codex/skills/tramway-skill
cp -R ./skills/tramway-skill ~/.codex/skills/tramway-skill
```

This is a developer workflow requirement for local testing of the current skill revision in Codex.
