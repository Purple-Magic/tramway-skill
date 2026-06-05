---
name: tramway-skill
description: 'Manage Ruby on Rails projects end-to-end: new apps, setup, development, debugging, tests, maintenance, updates/upgrades, deployment, favicon/site-icon setup, and database dump/restore. Use for phrases like "create rails project", "new rails app", "update application", "upgrade from reference project", "implement deployment", "favicon", "favicon.png", "browser tab icon", "site icon", "apple touch icon", "web app manifest", "implement dump", "dump database", or "restore database". Also use in Rails codebases when tasks involve app setup, tests, features, fixes, migrations, deploy readiness, wiring a provided PNG/logo/icon as the proper favicon set, or syncing a deployed database locally. Treat https://github.com/purple-magic/base_project as the canonical reference project during update/upgrade tasks.'
---

# Tramway Skill

Use this skill as an operational playbook. Prefer small, safe, verifiable changes over big-bang edits.
At every stage, the user can skip any proposed step; respect skips, note risks briefly, and continue with the remaining workflow.

## Runtime and File Loading

This skill runs in two environments. Behavior differs for file loading:

**Codex** — `agents/*.md` files are loaded natively by the Codex agents system. The "load `agents/X.md`" instructions work without extra steps.

**Claude Code** — `agents/*.md` files are NOT auto-loaded. Whenever this document says "load `agents/X.md`", you MUST use the Read tool to read that file before continuing. Use the following path:

```
~/.claude/skills/tramway-skill/agents/X.md
```

If that path does not resolve, fall back to a project-local path:

```
skills/tramway-skill/agents/X.md
```

Do NOT skip loading agents files. They contain mandatory rules for the active surface area. If a file cannot be read, report the error to the user instead of silently continuing.

Version policy:

1. The skill version is stored in `VERSION` at the root of this skill directory.
2. **MANDATORY: When this skill is loaded, immediately read the `VERSION` file and show the version to the user** as the first output, before any other response. Format: `tramway-skill v<version>`. Try `~/.claude/skills/tramway-skill/VERSION`, then `~/.codex/skills/tramway-skill/VERSION`, then any repository-local `skills/tramway-skill/VERSION`.
3. If the user asks for the `tramway-skill` version, read and report that `VERSION` value.

Command policy:

1. Assume Ruby is already installed on the host system.
2. Use `dip` only in the local development environment. Never use or suggest `dip` for production, staging, or CI commands, scripts, jobs, deploy hooks, or operational runbooks.
3. In local development, run Rails/Ruby project commands through `dip`. Do not use `docker` or `docker-compose` directly for project operations. Use `dip` as the main interface for project commands.
4. Exception: use direct `rails new ...` only when creating a brand-new Rails project (before `dip` setup exists).
5. If Rails is missing on host, run `gem install rails` before project creation.
6. Inside a Rails project in local development, run all Bundler commands via `dip` (for example, `dip bundle install`, `dip bundle add ...`, `dip bundle outdated`).
7. If `dip` is missing in local development, explicitly offer the user to install it with `gem install dip`.
8. Local development services must run in containers through `dip`. Do not use host-installed PostgreSQL, Redis, Node/Yarn, or other project services for Rails project operations unless the user explicitly asks for a non-container setup.
9. If a task requires Terraform and `terraform` is missing, install it with `bash scripts/install_terraform.sh` before running Terraform commands.
10. Scoped exception: when implementing the reference-project database dump/restore feature, preserve the reference script behavior. A direct `docker` volume reset is allowed only inside the imported/adapted `script/dump/restore` flow if needed to match the reference local restore behavior.
11. If `dip` reports that a required port is already in use or a container cannot be created because a name is already used, pause the task. Ask the user to free the needed resources, or explain the project-local configuration changes needed to use different ports/container names and wait for confirmation before changing them.
12. Do not suggest direct `bundle`, `bin/rails`, `bin/rspec`, `docker`, or `docker-compose` commands for local development project operations.

View policy:

1. All Rails views must use HAML.
2. Do not add new `.erb` templates.
3. If touched feature still uses `.erb`, migrate it to `.haml` as part of the change when safe.
4. Use Tailwind as the main CSS framework.
5. Use `tailwindcss-rails` gem for Tailwind integration.

Testing policy:

1. For every generated feature, create RSpec tests by default.
2. Switch to another test framework only when user explicitly asks for it.
3. Do not create model tests by default.
4. Create model tests only when user explicitly asks for model tests.
5. In local development, run RSpec tests via `dip rspec` (not direct `rspec`/`bin/rspec`). In CI, use CI-native test commands and services; do not use `dip`.

Secrets policy:

1. Never ask user to post secrets in chat (tokens, API keys, passwords, private keys, webhooks, credentials content).
2. Always instruct user to store secrets locally (environment variables, `.env*`, secret manager) or in repository/CI secret storage.
3. Ask user to confirm secret is set (for example: "done") instead of sending secret value.
4. If user pastes a secret anyway, instruct immediate rotation and continue with secure flow.
5. After project creation, guide secret setup directly in chat, step-by-step for each secret.
6. Do not replace secret guidance with generating app pages/docs (for example, "main page with instructions") unless user explicitly asks for that.
7. For any app keys, credentials, or recovery material generated during setup, explicitly ask the user how they want to store them before continuing.
8. Strongly recommend encrypted storage such as password managers or another secure secrets manager.
9. Mention `1Password` as the recommended option because this skill already has implemented and tested guidance for it; also mention alternatives such as `Bitwarden`.
10. If the user chooses unencrypted local `.env*` files, clearly warn that this is not safe, the keys may be lost with the machine or filesystem, and recovery may be impossible without backups.
11. During update, upgrade, and maintenance workflows, detect how the user currently stores keys and credentials before asking for any new secret-handling steps.
12. If current storage is unsafe or unencrypted, propose moving to an encrypted password manager or another secure method the user prefers.

Host environment policy:

1. Do not create or modify user home dotfiles during project setup or maintenance unless the user explicitly asks for it.
2. This includes files such as `.bashrc`, `.zshrc`, `.psqlrc`, `.irbrc`, and similar shell/editor/database client config files.
3. Prefer project-local configuration and explicit commands over persistent host-level changes.

## Focused Guidance Files

This skill includes focused guidance under `agents/`. Keep the main workflow in this file, then load only the matching guidance files for the active task.

Load files only when needed:

- `agents/rails.md` for Rails conventions, migrations, models, routes, seeds, configuration, services, and deployment command shape.
- `agents/testing.md` when adding or changing specs, factories, feature coverage, or Tramway entity page tests.
- `agents/ui.md` when changing Haml views, ViewComponents, Tailwind, page layout, buttons, tables, flashes, or form markup.
- `agents/tramway.md` is mandatory when the task touches CRUD, create/update forms, decorators, entities, components, or Tramway-specific controller/view patterns.
- `agents/integrations.md` when the task touches third-party services, service objects, background jobs, controller orchestration, or external APIs.
- `agents/documentation.md` when the task changes a user-visible feature or workflow that should be reflected in `docs/users/`.
- `agents/recipes.md` when the user asks for a usual implementation pattern or the task clearly matches an existing feature recipe. After opening the index, load only the specific recipe file that matches the feature.
- `agents/recipes/create-rails-project.md` when the user asks to create a new Rails project. **Claude Code**: Read `~/.claude/skills/tramway-skill/agents/recipes/create-rails-project.md`; if unavailable, read `skills/tramway-skill/agents/recipes/create-rails-project.md`.
- `agents/recipes/deployment-recipe.md` when the user asks to implement deployment, update deployment, or add deployment during new-project setup. **Claude Code**: Read `~/.claude/skills/tramway-skill/agents/recipes/deployment-recipe.md`; if unavailable, read `skills/tramway-skill/agents/recipes/deployment-recipe.md`.
- `agents/recipes/save-rails-secrets-1password.md` when the user asks how to save `config/master.key`, Rails credentials keys, staging/production secrets, or deployment secrets, and whenever create/update/deployment work introduces or touches those secrets. **Claude Code**: Read `~/.claude/skills/tramway-skill/agents/recipes/save-rails-secrets-1password.md`; if unavailable, read `skills/tramway-skill/agents/recipes/save-rails-secrets-1password.md`.
- `agents/recipes/add-flash-messages.md` when the user asks to add, fix, render, or standardize flash messages or notifications. **Claude Code**: Read `~/.claude/skills/tramway-skill/agents/recipes/add-flash-messages.md`; if unavailable, read `skills/tramway-skill/agents/recipes/add-flash-messages.md`.
- `agents/recipes/favicon.md` when the user asks to add, update, generate, use, place, wire, or standardize favicons, browser tab icons, Apple touch icons, Android/PWA icons, or a web app manifest. Also load it when the user mentions a file such as `favicon.png`, `favicon.ico`, `icon.png`, `logo.png`, or an uploaded/provided image that should be used as the site's favicon or browser tab icon. **Claude Code**: Read `~/.claude/skills/tramway-skill/agents/recipes/favicon.md`; if unavailable, read `skills/tramway-skill/agents/recipes/favicon.md`.
- For button requests that change a record's business state, including wording like "make a button on `<resource>#show` that calls `<event_or_method>` for the object", load `agents/recipes.md` and then `agents/recipes/state-change-recipe.md` before designing routes or controller actions.
- `agents/recipes/pagination.md` when the user asks to add pagination to any list of records. **Claude Code**: Read `~/.claude/skills/tramway-skill/agents/recipes/pagination.md`; if unavailable, read `skills/tramway-skill/agents/recipes/pagination.md`.

Usage rules:

1. Do not load every `agents/*.md` file by default.
2. Combine only the smallest relevant set for the current task.
3. Treat these files as scenario-specific rules that refine this skill, not as blanket instructions for unrelated work.
4. When two files overlap, prefer the more specific file for the active surface area and keep the rest of the workflow from this `SKILL.md`.
5. If a recurring feature pattern is missing, add a focused recipe under `agents/recipes/` and link it from `agents/recipes.md`.

## Canonical Reference Project

Use `https://github.com/purple-magic/base_project` as the main reference for baseline project structure and configuration.

Rules:

1. Always compare the current project against the reference project during update/upgrade/maintenance tasks.
2. Pull only applicable updates; do not blindly overwrite app-specific code.
3. Never copy domain models, business logic, or exact product functionality from the reference project.
4. Reuse only application-level setup: framework configuration, infrastructure wiring, tooling, CI/CD, security defaults, and implementation approaches.
5. During updates/upgrades of an existing project, deployment configuration stays protected unless the user explicitly asks for deployment work or for project-wide updating/upgrading.
6. Do not clone the reference project locally; read it remotely from GitHub.
7. Do not ask user whether to use the reference project; use it by default and only notify user that it is being used.
8. Always read/download reference project content from the `main` branch.
9. Every downloaded file/snippet from the reference project must be checked for applicability to current project setup before applying.
10. Adapt imported content to current project context (for example, rename reference-project-specific names, repository identifiers, and environment values to `<project_name>`/current repo values).
11. Document what was adopted, skipped, and why.
12. Never ask for approval file-by-file when importing from the reference project.
13. Ask the user only decision-level inputs that matter (for example: git platform, team chat choice, deployment target, privacy, and integration preferences), not file names.
14. Internally build the full candidate file list and adaptation plan without exposing file-by-file prompts to the user.
15. Execute imports through a temporary script that contains all required commands, then remove the script after execution.
16. Ensure repository is created/connected before configuring team chat integrations and related secrets.
17. In user-facing messages, call it "reference project" (not `base_project`).
18. If user asks what the reference project is, explain briefly and include this link: `https://github.com/purple-magic/base_project`.
19. Never offer or request posting secrets in chat. Use local secret setup + confirmation-only flow.
20. If the user asks to `Implement deployment`, treat that as an explicit request to add or update deployment configuration.
21. For `Implement deployment`, always check and implement all of these areas together:
    - Kamal deployment for `staging` and `production`
    - Terraform configuration for creating `staging` and `production`
    - `Makefile` commands for infra/deploy management
    - CI configuration
22. For `Implement deployment`, use the same approach as the reference project and use the reference project files/configuration as the source whenever they are applicable to the current project.
23. If a reference project file is not directly applicable, preserve the same deployment approach, behavior, naming conventions, workflow shape, and operator experience from the reference project, adapting only the parts required by the current hosting/git platform.
24. For `Implement deployment`, treat partial deployment setup as incomplete until all four areas above are covered or explicitly skipped by the user.
25. If the user asks for project updating/upgrading, always check the reference project for applicable updates to `.gitignore`, `AGENTS.md`, `Makefile`, deployment configuration, and Terraform configuration in addition to the usual app/tooling review.
26. If the user asks to `update deployment`, treat that as an explicit request to apply all applicable deployment-related setup from the reference project, including deployment configuration, `Makefile`, and Terraform usage patterns.
27. When creating or updating Kamal deployment configuration, `.kamal/secrets` must not contain shell `if` statements. Keep conditional secret resolution in project scripts or external secret tooling, and keep `.kamal/secrets` as a simple declarative secret-loading file.
28. If the user asks to `Implement dump`, `implement dump and restore`, `dump database to local environment`, `dump database`, or equivalent, treat that as an explicit request to add the reference-project database dump/restore workflow. Use the same operator experience as the reference project: the user runs `./dump ENVIRONMENT` and the remote database is dumped, downloaded, and restored into the local development database.
29. For database dump/restore implementation, read these reference project files remotely from GitHub `main` and adapt them to the current project:
    - `dump`
    - `script/dump/prepare_secrets.rb`
    - `script/dump/restore`
    - `config/database.yml` only as needed to determine local/remote database naming and credential shape.
29. Preserve the reference dump/restore approach unless a project-specific difference makes direct copy unsafe:
    - Top-level executable command is `./dump <environment>`.
    - Secrets are prepared by `ruby script/dump/prepare_secrets.rb "$ENVIRONMENT"`.
    - `MAIN_HOST` can come from Terraform output `main_host_ip` or environment variable.
    - Before adapting `prepare_secrets.rb`, inspect how the current project's Kamal deployment already gets secrets and use that same source for database host/user/password/name.
    - Use Rails credentials paths from the reference project only when the current Kamal setup already uses Rails credentials for those values.
    - Remote dump is created with `kamal app exec -d "$ENVIRONMENT"` and `pg_dump --format=custom --encoding=UTF8 --no-owner`.
    - Remote dump is downloaded with `scp`.
    - Local restore uses `pg_restore --clean --if-exists --no-owner` into the development database.
    - The local test database is recreated/migrated after restore, matching the reference flow.
30. Warn the user that dumping, downloading, and restoring a full deployed database can be very heavy for large databases. Ask which high-row-count tables they want to exclude before implementing or updating the dump script:
    - Copy the reference project's existing `EXCLUDED_TABLES=(...)` approach in `dump`.
    - Put the user's chosen tables into that static excluded-table list, adapting the reference defaults only as needed for the current schema.
    - Pass each excluded table to `pg_dump` as `--exclude-table-data=<table>` so table schemas are restored but their rows are skipped.
    - Keep the command shape as `./dump <environment>`; do not add table names as command-line arguments unless the reference project changes to that approach.
31. Adapt only project-specific values:
    - app name and Docker volume/storage path, for example replace `base_project_storage` with the current Kamal storage volume name;
    - local development database name, for example replace `base_project_development` with the current project's development database;
    - default excluded table list, keeping reference exclusions when matching tables exist and removing or changing only when the current schema requires it;
    - deploy user/host handling only when the current deployment is not `root@$MAIN_HOST`.
32. Do not ask the user to paste database credentials. Use the existing project-defined Kamal secret source, Terraform output, local environment variables, or confirmed local secret storage following the secrets policy.
33. Validate dump/restore setup without requiring a live production dump unless the user explicitly wants to run it:
    - syntax-check `dump` with `bash -n dump`;
    - syntax-check Ruby scripts with `ruby -c script/dump/prepare_secrets.rb` and `ruby -c script/dump/restore`;
    - verify scripts are executable where needed;
    - verify `./dump` prints usage or exits predictably when no environment is provided.

## Workflow

0. On skill start, check current directory context and announce capabilities.
1. Identify project shape and constraints.
2. Bootstrap and verify the environment.
3. Execute task-specific workflow (feature, bugfix, maintenance, update/upgrade, release).
4. Validate with targeted then broader tests.
5. Summarize risk and next actions.

## 0) Start-of-Skill Context Check

Before any other step, determine whether the current working directory is a Rails project.
Determine this only by checking for these paths:

- `config/application.rb`
- `config.ru`
- `Gemfile`

Do not list or scan all files in the directory for this detection step.

Do not describe technical detection details to the user. Only state the conclusion.

If inside a Rails project, tell the user you figured out you are in a Rails project and list what you can do there, for example:

1. Feature implementation with RSpec-first workflow.
2. Bug reproduction and targeted fixes with regression tests.
3. Refactors with safety checks.
4. Rails/gem updates and upgrades using the reference project.
5. Migration review and DB safety checks.
6. CI/CD and deploy-readiness improvements.

If not inside a Rails project, tell the user you figured out you are not in a Rails project and that you can create a best-practice, fully configured Rails project with:

1. CI configured for their selected git platform.
2. Deployment setup and release workflow.
3. Team chat notifications integration (for example, Discord by default and other chats on request).
4. HAML-first view setup and RSpec testing baseline.
5. Secure, production-ready defaults and useful starter features.

## 1) Identify Project Shape

If Rails project detection passed, inspect before changing anything:

```bash
test -f Gemfile
test -f config.ru
test -f config/application.rb
ls -la
```

Detect key rails signals:

- Gem management: `Gemfile`, `Gemfile.lock`
- App stack: `config/application.rb`, `config/environments/*`
- DB stack: `config/database.yml`, `db/schema.rb` or `db/structure.sql`
- Test stack: `spec/`, `test/`, CI config
- Tooling: `dip.yml`, `dip*`, `Procfile*`, `docker-compose*`

Choose execution path from project tooling. Use `dip` as the default command runner only for local development. For production, staging, and CI, use the environment's native commands and service definitions; do not use `dip`.

## 2) Bootstrap Safely

Run the smallest setup path first:

```bash
dip bundle install
dip rails db:prepare
```

If unavailable, run equivalent steps:

```bash
dip bundle install
dip rails db:prepare
```

Verify app boots:

```bash
dip rails runner 'puts Rails.version'
dip rails zeitwerk:check
```

If setup fails, capture exact command, error, and missing dependency before attempting fixes.

If `dip` is not available in local development, ask user whether to install it and use:

```bash
gem install dip
```

## 2.1) Create New Rails Project

When asked to create a new Rails project, load `agents/recipes/create-rails-project.md` and follow it as the authoritative workflow.

That recipe includes the required repository, reference-project import, local `dip` setup, HAML/Tailwind baseline, deployment handoff, and mandatory `config/master.key` storage guidance.

If the new project setup creates, reads, rotates, or references `config/master.key` or `config/credentials/*.key`, also load `agents/recipes/save-rails-secrets-1password.md` and run that recipe before continuing past the secret-handling step.

## 3) Daily Task Flows

### Implement deployment

Treat a request like `Implement deployment` as a full deployment-systems task, not a narrow single-file change.

Load `agents/recipes/deployment-recipe.md` and follow its "Implement deployment" path. Also load `agents/recipes/save-rails-secrets-1password.md` before requesting, configuring, or documenting `RAILS_MASTER_KEY`, `config/master.key`, Rails credentials keys, staging secrets, production secrets, provider tokens, or repository secrets.

### Update deployment

Treat a request like `update deployment` as a deployment-sync task against the reference project.

Load `agents/recipes/deployment-recipe.md` and follow its "Update deployment" path. Also load `agents/recipes/save-rails-secrets-1password.md` if the update touches secret storage, repository secrets, Rails credentials, or `.kamal/secrets`.

### Implement database dump/restore

Treat a request like `Implement dump`, `implement dump and restore`, or `dump database to local environment` as an operations-tooling task based on the reference project.

Load `agents/rails.md` for database and deployment command conventions. Also load `agents/integrations.md` if the current dump/restore flow depends on external providers or deployment secrets.

Required scope:

1. Inspect current project before editing:
   - `config/database.yml`
   - `config/deploy.yml`
   - `config/deploy.<environment>.yml`
   - `.kamal/secrets*`
   - `config/secrets*`
   - `bin/kamal`
   - scripts referenced by Kamal secret hooks or deploy configuration
   - `terraform/`
   - `dip.yml`
   - existing `dump` or `script/dump/`
2. Read the reference project files remotely from GitHub `main`:
   - `dump`
   - `script/dump/prepare_secrets.rb`
   - `script/dump/restore`
3. Implement the same user workflow: `./dump ENVIRONMENT`.
   - Do not replace it with a Make task, Rails task, README-only instructions, or manual multi-command procedure.
   - The command should dump the selected deployed environment and restore it into local development.
   - Tell the user this can be very heavy for a large database because it dumps, downloads, and restores the deployed data.
   - Ask which high-row-count tables the user wants to exclude from dumped data. Excluded tables keep their schema but skip row data.
4. Copy/adapt the reference scripts instead of inventing a different design.
   - Keep `prepare_secrets.rb` responsible for resolving `MAIN_HOST`, `DB_HOST`, `POSTGRES_DB`, `POSTGRES_PASSWORD`, and `POSTGRES_USER`.
   - Before implementing secret lookup, determine how Kamal already obtains these values in the current project.
   - Inspect `config/deploy*.yml` `env.clear`, `env.secret`, accessories, builder/registry secrets, `.kamal/secrets*`, `config/secrets*`, `bin/kamal`, and any scripts those files call.
   - Adapt `prepare_secrets.rb` to read database secrets through the same mechanism Kamal already uses: Rails credentials, `.kamal/secrets`, 1Password/`op`, dotenv, repository/env variables, or another project-local secret command.
   - Do not introduce a second secret source just for dump/restore.
   - Keep Terraform output for host discovery when the current deployment uses Terraform for host discovery.
   - Keep environment variables as overrides.
   - Keep the reference `dump` script's static `EXCLUDED_TABLES=(...)` pattern. Put the user's chosen excluded tables there, together with applicable reference defaults.
5. Adapt hardcoded reference values to the current project:
   - Kamal app/storage volume path used for the remote dump file.
   - Local development database name used by `pg_restore`.
   - Any deploy SSH user that differs from the reference project's `root`.
   - Default excluded tables, based on current schema.
6. Preserve the destructive local-restore behavior visibly and intentionally.
   - The restore replaces the local development database.
   - Do not run `./dump ENVIRONMENT` for validation unless the user explicitly confirms they want to overwrite local data.
7. Keep secrets out of chat and source control.
   - Do not request database passwords in chat.
   - Do not create committed files containing database credentials.
8. Validate the implementation locally:
   - `bash -n dump`
   - `ruby -c script/dump/prepare_secrets.rb`
   - `ruby -c script/dump/restore`
   - `test -x dump`
   - run no-live-network checks only unless the user confirms an actual dump.
9. In the final summary, explicitly tell the user:
   - the command to run: `./dump <environment>`;
   - which large tables are excluded from row-data dumping;
   - how the dump script gets secrets and how that matches the existing Kamal setup;
   - that it overwrites the local development database;
   - which reference files were copied/adapted;
   - which values were adapted for the current project.

### Feature work

Load the smallest matching set from `agents/` before implementation:

- `agents/testing.md` for spec conventions and coverage shape
- `agents/ui.md` for views/components/forms/layout work
- `agents/tramway.md` is mandatory for any CRUD flow, including `index`, `show`, `new`, `edit`, `create`, `update`, and `destroy`
- `agents/integrations.md` for services/jobs/external APIs
- `agents/documentation.md` when the feature is user-visible
- `agents/recipes.md` plus one matching recipe when the feature matches an existing implementation pattern
- `agents/recipes/state-change-recipe.md` when the user asks for a button that calls a record method or event and the purpose is to move that record through a business state, even if the user does not use the word "state"

1. Reproduce or define acceptance criteria.
2. Add or update RSpec tests first for the feature.
3. Skip model specs unless user explicitly requests them.
4. Implement minimal code change.
5. Keep view changes in HAML only; avoid introducing `.erb`.
6. Run nearest tests, then affected suite.
7. Check schema/migration side effects.

### Bugfix work

Load the same focused `agents/` files as feature work, but only for the surfaces touched by the bug. Add `agents/documentation.md` only if the bugfix changes visible behavior or user workflow documentation.

1. Reproduce with failing test or script.
2. Add regression test.
3. Implement fix with smallest blast radius.
4. Run regression + nearby files + lint.
5. Document root cause in PR notes.

### Refactor work

Load only the `agents/` files that match the code surface being refactored so the refactor preserves the established patterns for that layer.

1. Lock behavior with tests.
2. Refactor in small commits.
3. Re-run tests after each meaningful step.
4. Avoid mixing behavior change with structural change unless necessary.

## 4) Debugging and Triage

Start with fast, deterministic signals:

```bash
dip rails routes | head
dip rails runner 'puts ActiveRecord::Base.connection_db_config.database'
```

For failing tests:

```bash
dip rspec path/to/spec.rb:123
dip rspec --seed <seed>
```

For runtime issues:

1. Identify environment (`development`, `test`, `production`).
2. Confirm data preconditions and feature flags.
3. Inspect logs and backtrace top frames first.
4. Reduce to minimal reproduction (console, runner, single spec).

Avoid speculative rewrites before reproduction is stable.

## 5) Database and Migrations

Rules:

1. Keep migrations reversible when possible.
2. Separate schema changes from data backfills unless tightly coupled.
3. For risky migrations, use batched/background approach.
4. Validate indexes and constraints explicitly.

Before merge:

```bash
dip rails db:migrate
dip rails db:rollback STEP=1
dip rails db:migrate
```

If project uses `structure.sql`, ensure dump is updated by project convention.

## 6) Dependency and Rails Upgrades

Prefer incremental upgrades:

1. Upgrade patch versions first.
2. Upgrade minor versions with changelog review.
3. Upgrade Rails one minor at a time.

For each bump:

1. Update dependency.
2. Run boot checks and focused tests.
3. Run full suite when stable.
4. Record deprecations and follow-ups.
5. If the bumped dependency is the `tramway` gem, get the target `tramway` version first and replace the version in the project's `Gemfile` explicitly instead of leaving it implicit.
6. If the `tramway` gem version was upgraded, it is mandatory to run `dip rails g tramway:install` in local development right after the bundle update step before broader validation.

Use:

```bash
dip bundle outdated
dip brakeman -q
dip rubocop
```

If command wrappers exist in project, use them instead.

## 6.1) Update/Upgrade From Reference Project

Use this feature whenever the user asks for `update`, `upgrade`, or periodic maintenance.

Procedure:

1. Read latest reference project remotely from GitHub `main` branch (no local clone).
2. Detect how the user currently stores keys and credentials for the project (for example password manager, encrypted secret manager, repository secrets, `terraform/secrets.auto.tfvars`, unencrypted `.env*` files, or another local approach).
3. If the project has `config/master.key` or `config/credentials/*.key`, explicitly warn that these files are mandatory recovery material, are ignored by git, and must be saved in a secure place before secret-related update work continues. Load and run `agents/recipes/save-rails-secrets-1password.md` when the user asks for help saving them or when new staging/production secrets must be stored.
4. If current key storage is unsafe or unencrypted, explicitly propose moving to a password manager or another encrypted approach before continuing secret-related update steps.
   - Recommend `1Password` first because it is implemented and tested via this skill.
   - Mention `Bitwarden` and other secure methods the user prefers as acceptable alternatives.
   - If user chooses to keep an unsafe local approach, clearly warn about the risk and continue only after that warning is acknowledged.
5. Diff current project vs reference at config/tooling layers first.
6. Classify changes:
   - Safe to apply directly.
   - Needs adaptation for local domain logic.
   - Not applicable.
7. Exclude models and feature-level behavior from sync scope; keep updates/upgrades to app/platform layers only.
8. During any project update request, inspect the target `tramway` gem version and replace the project's `Gemfile` `tramway` version with that exact version when needed.
9. If the `tramway` gem version changed to a newer version, running `dip rails g tramway:install` in local development is mandatory and must happen before the rest of the update validation.
10. For any downloaded reference content, apply required project-specific rewrites (project name, repository path, env keys/values) before merge.
11. Apply in small commits by area (CI, linters, initializers, Docker/dev tooling, security).
12. During project update/upgrade requests, always inspect the reference project for applicable changes to:
   - `.gitignore`
   - `AGENTS.md`
   - `Makefile`
   - deployment configuration such as `config/deploy.yml`, `config/deploy.staging.yml`, `config/deploy.production.yml`
   - Terraform configuration in `terraform/`
13. If those `.gitignore`, `AGENTS.md`, and deployment-related updates are applicable, apply/adapt them as part of the project update instead of skipping them by default. When deployment files are included, load `agents/recipes/deployment-recipe.md`.
14. Keep or enforce HAML-only view setup from the reference project (no new `.erb`).
15. Run validation after each batch.
16. After update/upgrade execution, provide summary of adopted vs skipped updates with explicit reasons for every skipped item, including whether `.gitignore`, `AGENTS.md`, `Makefile`, deployment, and Terraform updates were applied or skipped and why.
17. For reference-file imports, request user approval once per import batch, not once per file.
18. Ask only decision-level update/upgrade questions, not file-level copy questions.
19. For each approved batch, build one temporary script for import/apply commands, run it, then remove it.

CI parity rule during updates/upgrades:

1. For GitHub repositories, keep `.github/workflows` aligned with applicable updates from the reference project.
2. For non-GitHub repositories, keep CI scenarios equivalent to reference GitHub Actions even if syntax/platform differs.
3. Apply Discord notification config only when user chose `Discord`.
4. For non-Discord team chat integration, ask for explicit confirmation and warn that generated notification config is untested.
5. If non-Discord team chat integration is not explicitly requested, keep notification config without Discord-specific workflow parts.

Minimum validation:

```bash
dip rails zeitwerk:check
dip rails db:prepare
dip rspec
```

## 7) Release and Operations

Before release:

1. Ensure migrations are safe for deploy order.
2. Confirm required env vars and credentials changes.
3. Verify jobs/queues, cache, and cron impacts.
4. Define rollback steps.

After release:

1. Check health endpoints and core user flow.
2. Watch error tracker and logs.
3. Validate background job throughput.

## 8) Output Format for User Updates

When reporting progress:

1. State what changed.
2. State how it was validated.
3. State residual risk.

Use concrete file paths and commands. Avoid vague "should work" conclusions.

## References

Load only what is needed:

- Command cookbook: `references/commands.md`
- Incident, update/upgrade, and release checklists: `references/checklists.md`
