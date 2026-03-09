---
name: tramway-skill
description: Manage Ruby on Rails projects end-to-end with reliable workflows for creating new apps, setup, development, debugging, testing, maintenance, upgrades, and releases. Use when the request includes phrases like "create rails project", "new rails app", "upgrade from base project", or when working in a Rails codebase (Gemfile, config/, app/, db/, spec/ or test/) and the task involves bootstrapping environments, running app/test jobs, triaging failing specs or production issues, adding/changing features safely, upgrading gems or Rails versions, reviewing migrations, or preparing deployments. Treat https://github.com/purple-magic/base_project as the canonical reference project and always check for applicable updates from it during upgrade tasks.
---

# Tramway Skill

Use this skill as an operational playbook. Prefer small, safe, verifiable changes over big-bang edits.

Command policy:

1. Assume Ruby is already installed on the host system.
2. Run Rails/Ruby project commands through `dip`.
3. Exception: use direct `rails new ...` only when creating a brand-new Rails project (before `dip` setup exists).
4. If Rails is missing on host, run `gem install rails` before project creation.
5. Inside a Rails project, run all Bundler commands via `dip` (for example, `dip bundle install`, `dip bundle add ...`, `dip bundle outdated`).
6. If `dip` is missing, explicitly offer the user to install it with `gem install dip`.
7. Do not suggest direct `bundle`, `bin/rails`, or `bin/rspec` commands for project operations.

View policy:

1. All Rails views must use HAML.
2. Do not add new `.erb` templates.
3. If touched feature still uses `.erb`, migrate it to `.haml` as part of the change when safe.

Testing policy:

1. For every generated feature, create RSpec tests by default.
2. Switch to another test framework only when user explicitly asks for it.
3. Do not create model tests by default.
4. Create model tests only when user explicitly asks for model tests.

## Canonical Reference Project

Use `https://github.com/purple-magic/base_project` as the main reference for baseline project structure and configuration.

Rules:

1. Always compare the current project against `base_project` during upgrade/maintenance tasks.
2. Pull only applicable updates; do not blindly overwrite app-specific code.
3. Never copy domain models, business logic, or exact product functionality from `base_project`.
4. Reuse only application-level setup: framework configuration, infrastructure wiring, tooling, CI/CD, security defaults, and implementation approaches.
5. Do not clone `base_project` locally; read it remotely from GitHub.
6. Document what was adopted, skipped, and why.

## Workflow

1. Identify project shape and constraints.
2. Bootstrap and verify the environment.
3. Execute task-specific workflow (feature, bugfix, maintenance, upgrade, release).
4. Validate with targeted then broader tests.
5. Summarize risk and next actions.

## 1) Identify Project Shape

Inspect before changing anything:

```bash
rg --files | head -n 200
ls -la
```

Detect key rails signals:

- Gem management: `Gemfile`, `Gemfile.lock`
- App stack: `config/application.rb`, `config/environments/*`
- DB stack: `config/database.yml`, `db/schema.rb` or `db/structure.sql`
- Test stack: `spec/`, `test/`, CI config
- Tooling: `dip.yml`, `dip*`, `Procfile*`, `docker-compose*`

Choose execution path from project tooling. Use `dip` as the default command runner.

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

If `dip` is not available, ask user whether to install it and use:

```bash
gem install dip
```

## 2.1) Create New Rails Project

When asked to `create rails project`, do this first:

1. Explicitly ask for the project name before running any command.
2. Tell the user: "Choose a simple name. Try to avoid `-` character besides you want explicitly. Renaming a Rails project later is possible but usually difficult and time-consuming."
3. Explicitly ask which git service they use (GitHub, GitLab, etc.).
4. Explicitly ask which chat to connect for CI notifications. Supported chats: `Discord`.

After the user confirms `<project_name>`, use this baseline flow:

```bash
if ! command -v rails >/dev/null 2>&1; then gem install rails; fi
rails new <project_name> -d postgresql
cd <project_name>
if ! command -v dip >/dev/null 2>&1; then gem install dip; fi
dip provision
```

API-only option:

```bash
if ! command -v rails >/dev/null 2>&1; then gem install rails; fi
rails new <project_name> --api -d postgresql
cd <project_name>
if ! command -v dip >/dev/null 2>&1; then gem install dip; fi
dip provision
```

Then align with the reference baseline:

1. Compare generated files against `base_project`.
2. Apply applicable config differences (CI, lint, security, deployment defaults).
3. If service is GitHub, copy/adapt GitHub Actions workflows from `base_project/.github/workflows/`.
4. If service is not GitHub, create CI for the chosen service with the same scenarios covered by reference GitHub Actions (for example: lint, test, security checks, build/deploy gates).
5. If chat is `Discord`, copy/adapt Discord CI notification configuration from reference GitHub workflows and ask for `DISCORD_WEBHOOK_URL`.
6. If chat is not `Discord` (for example Telegram), ask whether they still want CI notifications and clearly warn: configuration will be fully generated and not tested.
7. If chat is not `Discord` and user does not want generated notifications, do not apply Discord notification configuration from reference workflows.
8. Take HAML setup and configuration from `base_project` (do not configure HAML manually in this step).
9. Ensure view layer is HAML-only (`app/views/**/*.haml`).
10. Verify app boot and tests.

## 3) Daily Task Flows

### Feature work

1. Reproduce or define acceptance criteria.
2. Add or update RSpec tests first for the feature.
3. Skip model specs unless user explicitly requests them.
4. Implement minimal code change.
5. Keep view changes in HAML only; avoid introducing `.erb`.
6. Run nearest tests, then affected suite.
7. Check schema/migration side effects.

### Bugfix work

1. Reproduce with failing test or script.
2. Add regression test.
3. Implement fix with smallest blast radius.
4. Run regression + nearby files + lint.
5. Document root cause in PR notes.

### Refactor work

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

Use:

```bash
dip bundle outdated
dip brakeman -q
dip rubocop
```

If command wrappers exist in project, use them instead.

## 6.1) Upgrade From Reference Project

Use this feature whenever the user asks for `upgrade` or periodic maintenance.

Procedure:

1. Read latest `base_project` remotely from GitHub (no local clone).
2. Diff current project vs reference at config/tooling layers first.
3. Classify changes:
   - Safe to apply directly.
   - Needs adaptation for local domain logic.
   - Not applicable.
4. Exclude models and feature-level behavior from sync scope; keep upgrades to app/platform layers only.
5. Apply in small commits by area (CI, linters, initializers, Docker/dev tooling, security).
6. Keep or enforce HAML-only view setup from `base_project` (no new `.erb`).
7. Run validation after each batch.
8. Provide summary of adopted vs skipped updates.

CI parity rule during upgrades:

1. For GitHub repositories, keep `.github/workflows` aligned with applicable updates from `base_project`.
2. For non-GitHub repositories, keep CI scenarios equivalent to reference GitHub Actions even if syntax/platform differs.
3. Apply Discord notification config only when user chose `Discord`.
4. For non-Discord chat notifications, ask for explicit confirmation and warn that generated notification config is untested.
5. If non-Discord notifications are not explicitly requested, keep notification config without Discord-specific workflow parts.

Minimum validation:

```bash
dip rails zeitwerk:check
dip rails db:prepare
dip rspec || dip rails test
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
- Incident, upgrade, and release checklists: `references/checklists.md`
