# Repository Instructions

## Scope

These instructions apply to the entire `tramway-skill` repository.

## Cross-Platform Requirement

This skill must work correctly in both **Codex** and **Claude Code**. Every change to `SKILL.md`, `agents/*.md`, and `references/*.md` must preserve compatibility for both environments:

- **Codex**: `agents/*.md` files are loaded natively by the Codex agents system.
- **Claude Code**: `agents/*.md` files are not auto-loaded. Claude must read them explicitly using its file-reading tool. Instructions in `SKILL.md` that say "load `agents/X.md`" must be written so Claude knows to use the Read tool with path `~/.claude/skills/tramway-skill/agents/X.md`.

When writing or updating instructions:
1. Use platform-neutral language where possible.
2. If an instruction is platform-specific, label it with **Codex** or **Claude Code**.
3. Verify that file-loading instructions are actionable for both runtimes.
4. Never remove explicit file-path guidance from `SKILL.md`; it is required for Claude Code to function correctly.

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
- If the skill welcome/default prompt displays a version, keep it synchronized with `skills/tramway-skill/VERSION`.
- Maintain `skills/tramway-skill/CHANGELOG.md` for every version bump. Add a new entry for the new version and summarize what the user asked to change.
- When the user asks which version they are using, answer from `skills/tramway-skill/VERSION` in the active skill copy.

Then run these commands from the repo root:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ./skills/tramway-skill
rm -rf ~/.codex/skills/tramway-skill
cp -R ./skills/tramway-skill ~/.codex/skills/tramway-skill
rm -rf ~/.claude/skills/tramway-skill
cp -R ./skills/tramway-skill ~/.claude/skills/tramway-skill
```

This is a developer workflow requirement for local testing of the current skill revision in both Codex and Claude Code.
