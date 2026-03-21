---
name: tramway-skill
description: Manage Ruby on Rails projects end-to-end with reliable workflows for creating new apps, setup, development, debugging, testing, maintenance, updates/upgrades, and releases. Use when the request includes phrases like "create rails project", "new rails app", "update application", "upgrade from base project", or when working in a Rails codebase (Gemfile, config/, app/, db/, spec/ or test/) and the task involves bootstrapping environments, running app/test jobs, triaging failing specs or production issues, adding/changing features safely, upgrading gems or Rails versions, reviewing migrations, or preparing deployments. Treat https://github.com/purple-magic/base_project as the canonical reference project and always check for applicable updates from it during update/upgrade tasks.
---

# Tramway Skill

Use this skill as an operational playbook. Prefer small, safe, verifiable changes over big-bang edits.
At every stage, the user can skip any proposed step; respect skips, note risks briefly, and continue with the remaining workflow.

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
4. Use Tailwind as the main CSS framework.
5. Use `tailwindcss-rails` gem for Tailwind integration.

Testing policy:

1. For every generated feature, create RSpec tests by default.
2. Switch to another test framework only when user explicitly asks for it.
3. Do not create model tests by default.
4. Create model tests only when user explicitly asks for model tests.
5. Run RSpec tests via `dip rspec` (not direct `rspec`/`bin/rspec`).

## Canonical Reference Project

Use `https://github.com/purple-magic/base_project` as the main reference for baseline project structure and configuration.

Rules:

1. Always compare the current project against `base_project` during update/upgrade/maintenance tasks.
2. Pull only applicable updates; do not blindly overwrite app-specific code.
3. Never copy domain models, business logic, or exact product functionality from `base_project`.
4. Reuse only application-level setup: framework configuration, infrastructure wiring, tooling, CI/CD, security defaults, and implementation approaches.
5. Do not clone `base_project` locally; read it remotely from GitHub.
6. Do not ask user whether to use `base_project`; use it by default and only notify user that it is being used.
7. Always read/download `base_project` content from the `main` branch.
8. Every downloaded file/snippet from `base_project` must be checked for applicability to current project setup before applying.
9. Adapt imported content to current project context (for example, rename `base_project`-specific names, repository identifiers, and environment values to `<project_name>`/current repo values).
10. Document what was adopted, skipped, and why.
11. Never ask for approval file-by-file when importing from `base_project`.
12. Ask the user only decision-level inputs that matter (for example: git platform, team chat choice, deployment target, privacy, and integration preferences), not file names.
13. Internally build the full candidate file list and adaptation plan without exposing file-by-file prompts to the user.
14. Execute imports through a temporary script that contains all required commands, then remove the script after execution.
15. Ensure repository is created/connected before configuring team chat integrations and related secrets.

## Workflow

0. On skill start, check current directory context and announce capabilities.
1. Identify project shape and constraints.
2. Bootstrap and verify the environment.
3. Execute task-specific workflow (feature, bugfix, maintenance, update/upgrade, release).
4. Validate with targeted then broader tests.
5. Summarize risk and next actions.

## 0) Start-of-Skill Context Check

Before any other step, determine whether the current working directory is a Rails project.

Do not describe technical detection details to the user. Only state the conclusion.

If inside a Rails project, tell the user you figured out you are in a Rails project and list what you can do there, for example:

1. Feature implementation with RSpec-first workflow.
2. Bug reproduction and targeted fixes with regression tests.
3. Refactors with safety checks.
4. Rails/gem updates and upgrades using `base_project` as reference.
5. Migration review and DB safety checks.
6. CI/CD and deploy-readiness improvements.

If not inside a Rails project, tell the user you figured out you are not in a Rails project and that you can create a best-practice, fully configured Rails project with:

1. CI configured for their selected git platform.
2. Deployment setup and release workflow.
3. Team chat notifications integration (for example, Discord by default and other chats on request).
4. HAML-first view setup and RSpec testing baseline.
5. Secure, production-ready defaults and useful starter features.

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

Questioning style:

1. Ask setup questions one-by-one in separate messages.
2. Do not send all setup questions in one message.
3. Do not ask whether to use `base_project`; notify that it will be used by default.
4. During bootstrap import from `base_project`, do not ask about each file separately.
5. Ask only about project-level decisions that matter; do not ask the user which files to copy.
6. Collect full planned import list internally (files to download, applicability notes, planned adaptations) without asking file-by-file questions.
7. Build a temporary script with all download/apply commands, run it, and delete it right after execution.
8. Accept either `yes` (apply all) or user-requested changes to the high-level plan.
9. When asking about team chat, briefly explain value: shared visibility for CI status, deploy events, failures, and release updates helps the team react faster and stay aligned.
10. User may skip any setup step or integration; accept skip, record what was skipped, and continue.

1. Explicitly ask for the project name before running any command.
2. Tell the user: "Choose a simple name. Try to avoid `-` character besides you want explicitly. Renaming a Rails project later is possible but usually difficult and time-consuming."
3. Explicitly ask which git service they use (GitHub, GitLab, etc.).
4. Explicitly ask which team chat they want to connect. Supported chats: `Discord`.
5. Explicitly ask where they want to store the repository (GitHub recommended; GitLab, etc. also supported).
6. Ask for either remote URL or organization name to create the repository.
7. Make repository private by default unless user explicitly asks for public.
8. Do not ask about app type (standard vs API-only); create a standard Rails app by default.
9. After user provides repository URL or name, check whether it already exists on the selected service.
   - For GitHub, always run `scripts/check_github_repo_exists.sh <owner/repo>` for this check.
10. If repository does not exist, ask user explicitly whether they want to create it.
11. Before creating a GitHub repository, check `gh` availability and authentication:
    - Run `command -v gh` to verify GitHub CLI is installed.
    - Run `gh auth status` to verify it is authenticated.
    - If auth check fails, run `env -u GH_TOKEN -u GITHUB_TOKEN gh auth status` to rule out stale env-token override.
12. If `gh` is missing, tell user to pause this chat, install GitHub CLI for their OS, and authenticate `gh` in another terminal window.
13. If both auth checks fail, ask user to run `gh auth status` in their terminal. If user confirms it works there, continue and attempt repo creation anyway.
14. If repo creation command fails due to auth, then tell user to pause this chat, authenticate `gh` in another terminal window, and resume this Codex chat.
15. When repository is missing and user approved creation, Codex should attempt to create it (private by default) instead of stopping at instructions.

After the user confirms `<project_name>`, use this baseline flow:

```bash
if ! command -v rails >/dev/null 2>&1; then gem install rails; fi
rails new <project_name> -d postgresql
cd <project_name>
if ! command -v dip >/dev/null 2>&1; then gem install dip; fi
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/dip.yml -o dip.yml
mkdir -p config
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/config/database.yml -o config/database.yml
dip provision
```

Then align with the reference baseline:

1. Compare generated files against `base_project`.
2. Apply applicable config differences (CI, lint, security, deployment defaults).
3. If service is GitHub, copy/adapt GitHub Actions workflows from `base_project/.github/workflows/`.
4. If service is not GitHub, create CI for the chosen service with the same scenarios covered by reference GitHub Actions (for example: lint, test, security checks, build/deploy gates).
5. Create or connect repository using provided remote URL or organization, private by default.
6. If repository was missing and user confirmed creation, Codex should run repository creation command (`gh repo create ... --private`) unless user asked for public.
7. Prepare one consolidated bootstrap-import plan at decision level (scope, integrations, risks) and ask once for approval (`yes`) or changes.
8. Build a temporary bootstrap script with all required file downloads/adaptations/commands.
9. Run the script and then delete it.
10. If chat is `Discord`, copy/adapt Discord CI/deploy/team-update notification configuration from reference GitHub workflows.
11. If chat is `Discord`, ask user for `DISCORD_WEBHOOK_URL` only after repository exists, then instruct how to create it in Discord and store it in repository secrets.
12. If chat is not `Discord` (for example Telegram), ask whether they still want team chat integration for CI/deploy updates and clearly warn: configuration will be fully generated and not tested.
13. If chat is not `Discord` and user does not want generated team chat integration, do not apply Discord notification configuration from reference workflows.
14. Get and apply `.gitignore` from `base_project` `main` branch, adapting entries only if needed for current project specifics.
    - Clearly warn user that `config/master.key` and `config/credentials/*.key` are ignored by git and will not be stored in repository history.
    - Tell user to save these keys in a secure place (for example 1Password or another secrets manager) and keep backup/recovery access.
15. Take HAML setup and configuration from `base_project` (do not configure HAML manually in this step).
16. Ensure Tailwind is configured as the main CSS framework via `tailwindcss-rails` gem (follow `base_project` approach where applicable).
17. Enable PostgreSQL `uuid-ossp` extension during bootstrap by creating a migration that enables extension (follow the approach from `base_project`).
    - Tell user this supports security-minded public IDs: expose UUID-based record IDs publicly instead of sequential integer IDs, because incrementable IDs can leak approximate dataset size and make unauthorized record enumeration easier.
18. Ensure view layer is HAML-only (`app/views/**/*.haml`).
19. Ensure imported reference content is adapted to current project naming/settings.
20. Verify app boot and tests.
21. After bootstrap is complete, commit and push created code to the configured repository (unless user explicitly skips push).
22. After bootstrap is complete, tell user how to run server with both options and explain tradeoffs:
    - `dip rails s`: runs server with ability to interact with the container in the same terminal (for example, breakpoints), but shows logs only from Rails container.
    - `dip up web`: shows logs from all containers, but does not allow connecting to the running container in the same terminal.

When requesting `DISCORD_WEBHOOK_URL`, provide these instructions:

1. In Discord: open Server Settings -> Integrations -> Webhooks -> New Webhook, choose channel, copy webhook URL.
2. In repository secrets, create secret `DISCORD_WEBHOOK_URL` with that value before running CI notification jobs.
3. For GitHub: Settings -> Secrets and variables -> Actions -> New repository secret.
4. For GitLab: Settings -> CI/CD -> Variables -> Add variable (`Key`: `DISCORD_WEBHOOK_URL`, masked/protected as needed).

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

## 6.1) Update/Upgrade From Reference Project

Use this feature whenever the user asks for `update`, `upgrade`, or periodic maintenance.

Procedure:

1. Read latest `base_project` remotely from GitHub `main` branch (no local clone).
2. Diff current project vs reference at config/tooling layers first.
3. Classify changes:
   - Safe to apply directly.
   - Needs adaptation for local domain logic.
   - Not applicable.
4. Exclude models and feature-level behavior from sync scope; keep updates/upgrades to app/platform layers only.
5. For any downloaded reference content, apply required project-specific rewrites (project name, repository path, env keys/values) before merge.
6. Apply in small commits by area (CI, linters, initializers, Docker/dev tooling, security).
7. Keep or enforce HAML-only view setup from `base_project` (no new `.erb`).
8. Run validation after each batch.
9. After update/upgrade execution, provide summary of adopted vs skipped updates with explicit reasons for every skipped item.
10. For reference-file imports, request user approval once per import batch, not once per file.
11. Ask only decision-level update/upgrade questions, not file-level copy questions.
12. For each approved batch, build one temporary script for import/apply commands, run it, then remove it.

CI parity rule during updates/upgrades:

1. For GitHub repositories, keep `.github/workflows` aligned with applicable updates from `base_project`.
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
