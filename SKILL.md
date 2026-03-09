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
4. If Rails is missing on host, install it before project creation (`gem install rails`).
5. Do not suggest direct `bundle`, `bin/rails`, or `bin/rspec` commands for project operations.

## Canonical Reference Project

Use `https://github.com/purple-magic/base_project` as the main reference for baseline project structure and configuration.

Rules:

1. Always compare the current project against `base_project` during upgrade/maintenance tasks.
2. Pull only applicable updates; do not blindly overwrite app-specific code.
3. Never copy domain models, business logic, or exact product functionality from `base_project`.
4. Reuse only application-level setup: framework configuration, infrastructure wiring, tooling, CI/CD, security defaults, and implementation approaches.
5. Document what was adopted, skipped, and why.

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

## 2.1) Create New Rails Project

When asked to `create rails project`, use this baseline flow:

```bash
rails -v || gem install rails
rails new my_app -d postgresql
cd my_app
dip bundle install
dip rails db:prepare
```

API-only option:

```bash
rails -v || gem install rails
rails new my_api --api -d postgresql
```

Then align with the reference baseline:

1. Compare generated files against `base_project`.
2. Apply applicable config differences (CI, lint, security, deployment defaults).
3. Verify app boot and tests.

## 3) Daily Task Flows

### Feature work

1. Reproduce or define acceptance criteria.
2. Add or update focused tests first (request/model/system as appropriate).
3. Implement minimal code change.
4. Run nearest tests, then affected suite.
5. Check schema/migration side effects.

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

1. Fetch latest `base_project`.
2. Diff current project vs reference at config/tooling layers first.
3. Classify changes:
   - Safe to apply directly.
   - Needs adaptation for local domain logic.
   - Not applicable.
4. Exclude models and feature-level behavior from sync scope; keep upgrades to app/platform layers only.
5. Apply in small commits by area (CI, linters, initializers, Docker/dev tooling, security).
6. Run validation after each batch.
7. Provide summary of adopted vs skipped updates.

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
