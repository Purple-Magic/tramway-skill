# Changelog

## 1.11.4

- Added a testing rule requiring feature verification via RSpec/Capybara when the project has it configured, and prohibiting Playwright or other browser-automation alternatives unless explicitly requested.

## 1.11.3

- Added an `aasm` usage rule clarifying that generated scopes should be used instead of querying `aasm_state` directly.

## 1.11.2

- Added a constants rule clarifying that single-use string literals should not be promoted to constants, for example `ACTIVE_AASM_STATE = "active"`.

## 1.11.1

- Clarified the default Tramway CRUD checklist to verify `config/routes.rb` mounts the Tramway engine routes before assuming create-page routing is available.

## 1.11.0

- Added mandatory JS setup guidance for Tramway-provided Stimulus components: pin `@tramway/tramway` once in `config/importmap.rb` and import `TramwaySelect`, `TableRowPreview`, `UiCheckbox`, and `Tooltip` together in `app/javascript/controllers/index.js`.

## 1.10.7

- Added a presentation-layer restriction: do not put JavaScript or CSS code in Ruby helper files under `app/helpers/`; use views, ViewComponents, Stimulus or separate `.js` files, and Tailwind or separate `.css` files instead.

## 1.10.5

- Updated `AGENTS.md` and `CLAUDE.md` so the end-of-task sync always copies the skill to both `~/.codex/skills/tramway-skill` and `~/.claude/skills/tramway-skill`.

## 1.10.4

- Extended the favicon recipe to support non-Rails projects: added project-type detection, a static-root lookup table, and framework-specific tag-wiring instructions for Next.js (App Router and Pages Router), Vite/React/Vue SPA, Nuxt, and plain static HTML.

## 1.10.3

- Updated the skill metadata and default prompt so favicon and provided `favicon.png` requests trigger `tramway-skill` before recipe selection.

## 1.10.2

- Expanded favicon recipe routing so asset-placement requests like using `favicon.png` as the site favicon load the favicon recipe.
- Clarified that provided PNG favicon requests must generate the full required favicon set, wire layout tags, validate, and mention the Evil Martians source article.

## 1.10.1

- Updated the favicon recipe to install and use generation tools when favicon files are missing.
- Added a PNG-source workflow that prepares the full favicon set from a PNG, including a fallback SVG wrapper.

## 1.10.0

- Added a modern favicon recipe based on the Evil Martians 2026 favicon guide, including the minimal browser/PWA icon set, Rails HAML layout tags, generation commands, optimization guidance, and required source attribution.
- Linked the favicon recipe from the focused loading rules and recipes index.

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
