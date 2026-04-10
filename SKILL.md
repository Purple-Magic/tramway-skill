---
name: tramway-skill
description: Minimal router for Rails/Tramway work. Load extra guidance only when the current task needs it.
---

# Tramway Skill

Startup:

- If the user only activated this skill and gave no task yet, read only this file and reply:
  `Tramway workflow ready. Опишите конкретную задачу.`
- Do not read project files, `AGENTS.md`, or references at startup.
- Do not run `pwd`, `ls`, `rg`, `find`, `test`, or any other repository-inspection command at startup.
- Do not inspect directory contents unless the user explicitly asked for directory or project inspection.

Task routing:

- Generic repository work:
  codebase explanation, commit/PR summary, docs work, read-only review, search, and small non-runtime edits.
  For these tasks, skip Rails detection and do not inspect directory contents broadly. Go directly to the task.
- Rails-dependent work:
  feature work, bugfixes with app behavior, tests, generators, migrations, routes, console, boot checks, Rails/gem/CI/deploy/bootstrap updates, and new Rails project creation.
  For these tasks, do not inspect directory contents broadly. Open only the specific files needed for the current task. Run a Rails probe only if the task actually requires Rails-dependent behavior, and then use exactly:
  `test -f Gemfile -a -f config/application.rb`
  Do not add `pwd`, `ls`, `rg`, `find`, or a second confirmation command.

Progressive loading:

- Open `references/commands.md` only when command syntax, bootstrap, create-project, deploy, secrets, lint, test, or update commands are needed.
- Open `references/checklists.md` only when upgrade, migration, incident, release, or reference-project update checklists are needed.
- Read only the relevant section.

Always:

- Inside a Rails project, use `dip` for Rails/Bundler commands.
- Use HAML, Tailwind, and RSpec defaults.
- Do not ask for secrets in chat.
- Use the reference project by default for applicable baseline work:
  `https://github.com/purple-magic/base_project`
- Do not inspect repository contents just because this skill is active. Any repository inspection must be narrow and justified by the current task.
