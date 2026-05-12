# Repository Instructions

## Scope

These instructions apply to the entire `tramway-skill` repository.

## End-of-Task Skill Sync

At the end of every task that changes this repository, update `skills/tramway-skill/VERSION` before validation and sync.

Version rules:

- Use semantic versioning: `MAJOR.MINOR.PATCH`.
- Every repository-changing task must increase the version exactly once before validation and sync.
- If the skill has no version yet, create `skills/tramway-skill/VERSION` with `0.1.0`.
- If the existing version is not full semantic versioning, normalize it first by treating missing components as `0`, then apply the required bump.
- Bump `PATCH` for wording, clarification, examples, and narrow bugfixes.
- Bump `MINOR` for new workflows, recipes, scripts, or materially expanded behavior.
- Bump `MAJOR` for breaking instruction changes or behavior reversals.
- Never leave `skills/tramway-skill/VERSION` unchanged after modifying this repository.
- When the user asks which version they are using, answer from `skills/tramway-skill/VERSION` in the active skill copy.

Then run these commands from the repo root:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ./skills/tramway-skill
rm -rf ~/.codex/skills/tramway-skill
cp -R ./skills/tramway-skill ~/.codex/skills/tramway-skill
```

This is a developer workflow requirement for local testing of the current skill revision in Codex.
