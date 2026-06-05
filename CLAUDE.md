# Repository Instructions

Follow all instructions in `AGENTS.md`.

## Cross-Platform Requirement

This skill must work correctly in both **Codex** and **Claude Code**. Instructions in `SKILL.md` must be readable and actionable for both AI systems. The key difference:

- **Codex** loads `agents/*.md` files natively via the Codex agents system.
- **Claude Code** does NOT auto-load `agents/*.md` files. The skill file must include explicit Read-tool guidance so Claude knows *how* and *from where* to load each file.

Every change to this skill must preserve this dual-platform compatibility. When in doubt, test the updated skill in both environments.

## End-of-Task Skill Sync

At the end of every task that changes this repository, update `skills/tramway-skill/VERSION` and sync with:

```bash
rm -rf ~/.claude/skills/tramway-skill
cp -R ./skills/tramway-skill ~/.claude/skills/tramway-skill
rm -rf ~/.codex/skills/tramway-skill
cp -R ./skills/tramway-skill ~/.codex/skills/tramway-skill
```
