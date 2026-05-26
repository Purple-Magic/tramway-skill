# Changelog

## 1.9.2

- Added an Add Flash Messages recipe that makes `tramway_flash` mandatory for rendered flash messages and notifications.
- Linked the recipe from the focused loading rules and recipes index.

## 1.8.5

- Added Tramway feature lookup guidance: read the upstream Tramway README before inspecting installed gem source code for feature usage.

## 1.8.4

- Clarified mandatory navbar guidance: use `tramway_navbar` instead of raw `<nav>`, link groups styled as navbars, or custom navbar components for standard navigation.

## 1.8.3

- Clarified mandatory button guidance: use `tramway_button` instead of `button_to`, button-styled links, or raw `<button>` markup.

## 1.8.2

- Updated the new Rails project recipe to create or update project-root `AGENTS.md` and `CLAUDE.md` so future Codex and Claude Code sessions use `tramway-skill` by default.

## 1.8.1

- Made button guidance explicit: use `tramway_button` for every button unless an existing Tramway component API requires another Tramway Button invocation form.

## 1.8.0

- Moved the new Rails project workflow into a dedicated recipe.
- Moved deployment implementation/update workflows into a dedicated recipe.
- Added a dedicated recipe for saving `config/master.key`, Rails credentials keys, staging/production secrets, and deployment secrets in 1Password or another secure store.
- Updated create, update, and deployment routing so mandatory `config/master.key` backup warnings and 1Password guidance are used whenever relevant.

## 1.7.0

- Added cross-platform requirement sections to `AGENTS.md` and `CLAUDE.md` stating that the skill must work in both Codex and Claude Code, with notes on the key file-loading difference between the two runtimes.
- Added "Runtime and File Loading" section to `SKILL.md` explaining that in Claude Code, `agents/*.md` files must be read explicitly via the Read tool (with the `~/.claude/skills/tramway-skill/agents/` path), since they are not auto-loaded as they are in Codex. This is the primary fix for Claude ignoring agents-file instructions.

## 1.6.2

- Added table of contents to `README.md`.
- Added Claude Code installation instructions to `README.md`.

## 1.6.1

- Made the after-task sync instruction explicit in `CLAUDE.md` instead of relying on implicit inheritance from `AGENTS.md`.

## 1.6.0

- Added `CLAUDE.md` for Claude Code support; it delegates to `AGENTS.md` and overrides only the sync command to install to `~/.claude/skills/tramway-skill/`.
- Updated version policy in `SKILL.md` to reference both Claude Code and Codex install paths.

## 1.5.5

- Strengthened state-change recipe routing so show-page buttons that call state-transition methods load the recipe before route or controller design.

## 1.5.4

- Clarified that the state-change recipe applies to button actions that imply a business state transition by calling a record method.

## 1.5.3

- Reverted the expanded state-change recipe trigger for record-page buttons that call object methods.

## 1.5.2

- Expanded the state-change recipe trigger to cover record-page buttons that call methods on the current object.

## 1.5.1

- Refined shared Set Form recipe references, clarified controller assumptions, generalized shared recipe examples, and fixed the state-change recipe typo.

## 1.5.0

- Added an empty state-change recipe and linked it for record state changes triggered by a button.

## 1.3.3

- Added changelog management instructions so every future version bump records what the user asked to change.
- Created this changelog for tracking `tramway-skill` version changes.

## 1.3.2

- Updated the welcome/default prompt to show the active `tramway-skill` version.
- Added an instruction to keep displayed welcome/default-prompt versions synchronized with `VERSION`.

## 1.3.1

- Updated repository instructions to require semantic version increments for every repository-changing task.
- Normalized incomplete semantic versions by treating missing components as `0` before applying the required bump.
