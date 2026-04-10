---
name: tramway-skill
description: Manage Ruby on Rails projects end-to-end with reliable workflows for creating new apps, setup, development, debugging, testing, maintenance, updates/upgrades, and releases. Use when the request includes phrases like "create rails project", "new rails app", "update application", "upgrade from reference project", or when working in a Rails codebase (Gemfile, config/, app/, db/, spec/ or test/) and the task involves bootstrapping environments, running app/test jobs, triaging failing specs or production issues, adding/changing features safely, upgrading gems or Rails versions, reviewing migrations, or preparing deployments. Treat https://github.com/purple-magic/base_project as the canonical reference project and always check for applicable updates from it during update/upgrade tasks.
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
7. If a task requires Terraform and `terraform` is missing, install it with `bash scripts/install_terraform.sh` before running Terraform commands.
8. Do not suggest direct `bundle`, `bin/rails`, or `bin/rspec` commands for project operations.

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

## Canonical Reference Project

Use `https://github.com/purple-magic/base_project` as the main reference for baseline project structure and configuration.

Rules:

1. Always compare the current project against the reference project during update/upgrade/maintenance tasks.
2. Pull only applicable updates; do not blindly overwrite app-specific code.
3. Never copy domain models, business logic, or exact product functionality from the reference project.
4. Reuse only application-level setup: framework configuration, infrastructure wiring, tooling, CI/CD, security defaults, and implementation approaches.
5. During updates/upgrades of an existing project, do not modify existing deployment configuration by default; touch deployment config only when the user explicitly asks for deployment-related changes.
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
3. Do not ask whether to use the reference project; notify that it will be used by default.
4. During bootstrap import from the reference project, do not ask about each file separately.
5. Ask only about project-level decisions that matter; do not ask the user which files to copy.
6. Collect full planned import list internally (files to download, applicability notes, planned adaptations) without asking file-by-file questions.
7. Build a temporary script with all download/apply commands, run it, and delete it right after execution.
8. Accept either `yes` (apply all) or user-requested changes to the high-level plan.
9. When asking about team chat, briefly explain value: shared visibility for CI status, deploy events, failures, and release updates helps the team react faster and stay aligned.
10. User may skip any setup step or integration; accept skip, record what was skipped, and continue.
11. User-facing question messages must be plain text only in the user's language. Never include tool-call payloads, JSON, code fences, internal command logs, metadata, or text from another language unless the user asked for that language.
12. When asking a question, do not execute unrelated actions in the same message; wait for user answer first.

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
16. At the end of create-project questioning, explicitly ask whether they want server creation and deploy configuration.
17. Before any step that gives the user app keys, credentials, or recovery material, explicitly ask how they want to store them.
18. In that question, recommend encrypted storage via password managers or another safe approach.
19. Mention `1Password` as the recommended option because it is implemented and tested in this skill; also mention `Bitwarden` and similar tools as acceptable alternatives.
20. Offer unencrypted local `.env*` files only as a fallback option.
21. If user picks unencrypted local `.env*` files, clearly warn that storing keys there is not safe and that they can lose access to those keys if the machine or files are lost.
22. If yes, ask whether they already have a server.
23. If they do not have a server, ask which hosting provider they want. Recommend `DigitalOcean` because this skill has complete setup guidance for it.
24. If hosting is `DigitalOcean`, use Terraform configuration from the reference project as baseline.
25. If hosting is not `DigitalOcean`, build server/deploy Terraform configuration for the chosen hosting yourself.
26. Ask which provider they use for domain/DNS hosting. Recommend `Cloudflare` because this skill has complete setup guidance for it.
27. If domain hosting is `Cloudflare`, use Cloudflare-related Terraform configuration from the reference project.
28. If domain hosting is not `Cloudflare`, build domain/DNS configuration for chosen provider yourself.
29. Do not collect deploy/provider secrets during pre-project questions. Collect them only in deploy setup phase after Rails project and `terraform/` directory exist.
30. Never commit deploy secrets (`*.tfvars`, `.env*`, tokens, private keys). Keep them in local env/secrets manager and repository secrets.
    - For Terraform, default secret storage is `terraform/secrets.auto.tfvars` (gitignored).
31. Do not create or edit user home dotfiles as part of setup. If host-level configuration seems necessary, stop and ask the user first.

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

1. Compare generated files against the reference project.
2. Apply applicable config differences (CI, lint, security, deployment defaults).
3. If service is GitHub, copy/adapt GitHub Actions workflows from the reference project `.github/workflows/`.
4. If service is not GitHub, create CI for the chosen service with the same scenarios covered by reference GitHub Actions (for example: lint, test, security checks, build/deploy gates).
5. Create or connect repository using provided remote URL or organization, private by default.
6. If repository was missing and user confirmed creation, Codex should run repository creation command (`gh repo create ... --private`) unless user asked for public.
7. Prepare one consolidated bootstrap-import plan at decision level (scope, integrations, risks) and ask once for approval (`yes`) or changes.
8. Build a temporary bootstrap script with all required file downloads/adaptations/commands.
9. Run the script and then delete it.
10. If chat is `Discord`, copy/adapt Discord CI/deploy/team-update notification configuration from reference GitHub workflows.
11. If chat is `Discord`, ask user to set `DISCORD_WEBHOOK_URL` in repository secrets only after repository exists; do not ask user to paste webhook URL in chat.
12. If chat is not `Discord` (for example Telegram), ask whether they still want team chat integration for CI/deploy updates and clearly warn: configuration will be fully generated and not tested.
13. If chat is not `Discord` and user does not want generated team chat integration, do not apply Discord notification configuration from reference workflows.
14. Get and apply `.gitignore` from the reference project `main` branch, adapting entries only if needed for current project specifics.
    - Clearly warn user that `config/master.key` and `config/credentials/*.key` are ignored by git and will not be stored in repository history.
    - Explicitly ask the user how they want to store these keys before moving on.
    - Recommend using an encrypted password manager or another safe encrypted approach. `1Password` is the recommended option because it is implemented and tested in this skill; `Bitwarden` and similar tools are also acceptable.
    - Offer unencrypted local `.env*` files only as a fallback option.
    - If the user chooses unencrypted local `.env*` files, clearly warn that this is not safe and that losing the machine or files can mean losing the keys.
    - Tell user to keep backup/recovery access regardless of the storage method.
15. Take HAML setup and configuration from the reference project (do not configure HAML manually in this step).
16. Ensure Tailwind is configured as the main CSS framework via `tailwindcss-rails` gem (follow the reference project approach where applicable).
17. Enable PostgreSQL `uuid-ossp` extension during bootstrap by creating a migration that enables extension (follow the approach from the reference project).
    - Tell user this supports security-minded public IDs: expose UUID-based record IDs publicly instead of sequential integer IDs, because incrementable IDs can leak approximate dataset size and make unauthorized record enumeration easier.
18. Ensure view layer is HAML-only (`app/views/**/*.haml`).
19. Ensure imported reference content is adapted to current project naming/settings.
20. When importing `.dockerdev/compose.yml` from the reference project, do not modify `x-*` extension blocks/services configuration. Preserve them exactly as provided by the reference file unless the user explicitly asks to change them.
21. Verify app boot and tests.
22. After bootstrap is complete, commit and push created code to the configured repository (unless user explicitly skips push).
23. After bootstrap is complete, tell user how to run server with both options and explain tradeoffs:
    - `dip rails s`: runs server with ability to interact with the container in the same terminal (for example, breakpoints), but shows logs only from Rails container.
    - `dip up web`: shows logs from all containers, but does not allow connecting to the running container in the same terminal.

If user selected server/deploy setup, add this step after repository setup and before final bootstrap verification:

23. Configure server/deploy Terraform:
    - If hosting is `DigitalOcean`, import and adapt reference Terraform files:
      - `terraform/main.tf`, `terraform/variables.tf`, `terraform/update_env_hosts.sh`, `terraform/wait_for_ssh.sh`
      - Replace hardcoded reference-project identifiers (droplet name, DNS record/subdomain, default app name) with current project values.
    - If hosting is not `DigitalOcean`, build Terraform server/deploy configuration for selected hosting yourself.
24. Configure domain/DNS Terraform:
    - If domain hosting is `Cloudflare`, use/adapt Cloudflare Terraform config from the reference project.
    - If domain hosting is not `Cloudflare`, build Terraform domain/DNS configuration for selected provider yourself.
25. Keep Terraform files in `terraform/` and ensure scripts are executable (`chmod +x terraform/*.sh`) when scripts are present.
26. Collect deploy variables now (after project exists and `terraform/` directory is created):
    - If hosting is `DigitalOcean`, collect:
      - `do_token` (DigitalOcean API token)
        1. Open DigitalOcean Control Panel -> API -> Tokens/Keys.
        2. In "Personal access tokens", click "Generate New Token".
        3. Give token a name, select appropriate scope (write for infra create/update), and create token.
        4. Put token into `terraform/secrets.auto.tfvars` and reply `done`.
      - `ssh_fingerprint`:
        - By default, use the system default SSH public key and its DigitalOcean fingerprint (do not ask user for custom key first).
        - Ask for custom SSH key/fingerprint only if user explicitly wants non-default key.
        - If default key is not registered in DigitalOcean, guide user to add it in DigitalOcean -> API -> Tokens/Keys -> SSH Keys, then use its fingerprint.
      - `region`, `size`, `app_name` (with reference defaults unless user changes)
    - If hosting is not `DigitalOcean`, collect provider-specific infra inputs for Terraform.
    - If domain hosting is `Cloudflare`, collect:
      - `domain`, `cloudflare_email`, `cloudflare_api_key`
      - Cloudflare Dashboard -> My Profile -> API Tokens -> Global API Key -> View
      - Put key into `terraform/secrets.auto.tfvars` and reply `done`.
    - If domain hosting is not `Cloudflare`, collect provider-specific DNS inputs for Terraform.
    - Ensure `terraform/secrets.auto.tfvars` is gitignored.
27. Validate tooling availability before apply:
    - `if ! command -v terraform >/dev/null 2>&1; then bash scripts/install_terraform.sh; fi`
    - `terraform -version`
    - `doctl version` only when using the DigitalOcean reference script (`wait_for_ssh.sh`)
    - `nc -h` or `command -v nc` only when using `wait_for_ssh.sh`
28. Initialize and validate Terraform:
    - `terraform -chdir=terraform init`
    - `terraform -chdir=terraform validate`
    - `terraform -chdir=terraform plan`
29. Apply only after explicit user confirmation:
    - `terraform -chdir=terraform apply`
30. After apply, if `.env` exists and `update_env_hosts.sh` is present, run:
    - `bash terraform/update_env_hosts.sh`
31. Explain key outputs to user (for example server IP, hostname, and env snippet values).

When requesting deploy/repository secrets, provide setup guidance for each secret:

1. Set secrets in repository secrets storage (never in chat).
2. For GitHub: Settings -> Secrets and variables -> Actions -> New repository secret.
3. For GitLab: Settings -> CI/CD -> Variables -> Add variable.
4. Required/optional secrets and how to get them:
   - `DISCORD_WEBHOOK_URL`:
     - Discord -> Server Settings -> Integrations -> Webhooks -> New Webhook -> choose channel -> copy webhook URL.
   - `MAIN_HOST`:
     - After Terraform apply: `terraform -chdir=terraform output -raw main_host_ip`.
   - `SSH_PRIVATE_KEY`:
     - Use local deploy key content (for example from `~/.ssh/id_ed25519` or chosen deploy key file).
     - If missing, generate with `ssh-keygen`, add public key to server/provider, then store private key in repo secret.
   - `SSH_USER`:
     - For DigitalOcean Ubuntu droplets, default is usually `root` unless user configured another deploy user.
   - `RAILS_MASTER_KEY`:
     - Use value from project `config/master.key` (or the relevant credentials key file for environment).
   - Kamal registry default:
     - Use localhost registry in Kamal by default.
     - With localhost registry, do not request `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD`.
     - Ask for registry credentials only if user explicitly chooses external registry (Docker Hub, GHCR, GitLab Registry, etc.).
5. Tell user to confirm with `done` after secrets are set; do not request secret values in chat.
6. In chat, walk through secrets one-by-one in this order and wait for `done` after each:
   - `RAILS_MASTER_KEY`
   - `SSH_PRIVATE_KEY`
   - `SSH_USER`
   - `MAIN_HOST`
   - `DISCORD_WEBHOOK_URL` (if Discord enabled)
   - `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD` (only if user explicitly chose external registry)

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
5. If the bumped dependency is the `tramway` gem, get the target `tramway` version first and replace the version in the project's `Gemfile` explicitly instead of leaving it implicit.
6. If the `tramway` gem version was upgraded, it is mandatory to run `dip rails g tramway:install` right after the bundle update step before broader validation.

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
3. If current key storage is unsafe or unencrypted, explicitly propose moving to a password manager or another encrypted approach before continuing secret-related update steps.
   - Recommend `1Password` first because it is implemented and tested via this skill.
   - Mention `Bitwarden` and other secure methods the user prefers as acceptable alternatives.
   - If user chooses to keep an unsafe local approach, clearly warn about the risk and continue only after that warning is acknowledged.
4. Diff current project vs reference at config/tooling layers first.
5. Classify changes:
   - Safe to apply directly.
   - Needs adaptation for local domain logic.
   - Not applicable.
6. Exclude models and feature-level behavior from sync scope; keep updates/upgrades to app/platform layers only.
7. During any project update request, inspect the target `tramway` gem version and replace the project's `Gemfile` `tramway` version with that exact version when needed.
8. If the `tramway` gem version changed to a newer version, running `dip rails g tramway:install` is mandatory and must happen before the rest of the update validation.
9. For any downloaded reference content, apply required project-specific rewrites (project name, repository path, env keys/values) before merge.
10. Apply in small commits by area (CI, linters, initializers, Docker/dev tooling, security).
11. If the project already has deployment configuration, treat it as protected during update/upgrade work and leave it unchanged unless the user explicitly requested deployment updates.
12. Keep or enforce HAML-only view setup from the reference project (no new `.erb`).
13. Run validation after each batch.
14. After update/upgrade execution, provide summary of adopted vs skipped updates with explicit reasons for every skipped item, including deployment-related items skipped by default.
15. For reference-file imports, request user approval once per import batch, not once per file.
16. Ask only decision-level update/upgrade questions, not file-level copy questions.
17. For each approved batch, build one temporary script for import/apply commands, run it, then remove it.

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
