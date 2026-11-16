# Rails Command Cookbook

Use `dip` only in the local development environment. Never use or suggest `dip` for production, staging, or CI commands, scripts, jobs, deploy hooks, or operational runbooks.
In local development, use `dip` for Rails/Ruby project commands, except `rails new` during initial project creation.
Inside a Rails project in local development, all Bundler commands must be run via `dip`.
Development services must run in containers through `dip`. Do not use host-installed PostgreSQL, Redis, Node/Yarn, or other project services for local Rails project operations unless the user explicitly asks for a non-container setup.
Do not run or suggest direct `docker` or `docker-compose` commands for project operations; any Docker Compose files are implementation details consumed through `dip`.
If `dip` reports that a required port is already in use or a container cannot be created because a name is already used, pause the task. Ask the user to free the needed resources, or explain the project-local configuration changes needed to use different ports/container names and wait for confirmation before changing them.
Assume Ruby is already installed. If Rails is missing, run `gem install rails`.
If `dip` is missing in local development, offer installing it via `gem install dip`.
For database dump/restore implementation, preserve the reference-project workflow but adapted into this project's convention of `bin/dump -d <environment>`. A direct `docker` volume reset is allowed only inside the imported/adapted `script/dump/restore` flow when needed to match the reference local restore behavior.

For production, staging, and CI, use the environment's native command runner and service definitions. Examples include CI workflow steps such as `bundle exec rspec` after the job has installed gems, or deploy-platform commands documented by the chosen hosting/deployment tool. Do not add `dip` to CI images, deploy scripts, staging consoles, or production maintenance procedures.

## Environment bootstrap

```bash
dip bundle install
dip rails db:prepare
```

## Create Rails project

Before running commands:
- Ask questions separately (one question per message), not as one large questionnaire.
- Keep user-facing questions plain text only in the user's language; do not include tool-call payloads, JSON, command logs, metadata, or text from another language unless the user asked for that language.
- Do not combine a question with unrelated command execution; wait for user answer before running next action.
- Do not ask whether to use the reference project; notify user it is used by default.
- Ask user for `<project_name>` explicitly and warn that project name should be simple because renaming later is difficult.
- Ask which git service is used (GitHub, GitLab, etc.).
- Ask which chat should receive CI notifications. Supported chats: `Discord`.
- Ask where to store repository (GitHub, GitLab, etc.).
- Ask for remote URL or organization name.
- Default repository visibility to private unless user asks for public.
- Check whether provided repository URL/name already exists on chosen service.
- If repository does not exist, ask user whether to create it.
- Do not ask about app type; create standard Rails app by default.
- For reference project imports during bootstrap, do not ask file-by-file.
- Share one combined plan of files + applicability + adaptations, then ask once for `yes` or changes.
- When importing `.dockerdev/compose.yml` from the reference project, preserve all `x-*` extension blocks exactly unless the user explicitly asks to change them.
- At the end of create-project questioning, ask whether user wants server creation and deploy configuration.
- If yes, ask whether they already have a server.
- If they do not have a server, ask which hosting they want. Recommend `DigitalOcean` because this skill has complete setup guidance for it.
- Ask what provider they use for domain/DNS hosting. Recommend `Cloudflare` because this skill describes a complete API flow for it.
- Server creation and deletion is done by `bin/setup -d <environment>` and `bin/remove_fully -d <environment>` through the chosen hosting's API or command-line utility (see `agents/recipes/deployment-recipe.md`). This skill does not use Terraform.
- Do not collect deploy/provider secrets yet. Collect provider settings in the deploy setup phase after the Rails project and `lib/server_provider.rb` exist, and never collect provider credentials in chat.
- Do not create or modify user home dotfiles such as `.bashrc`, `.zshrc`, `.psqlrc`, or similar host-level config files unless the user explicitly asked for that.

```bash
if ! command -v rails >/dev/null 2>&1; then gem install rails; fi
rails new <project_name> -d postgresql
cd <project_name>
if ! command -v dip >/dev/null 2>&1; then gem install dip; fi
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/dip.yml -o dip.yml
mkdir -p .dockerdev
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/.bashrc -o .dockerdev/.bashrc
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/.psqlrc -o .dockerdev/.psqlrc
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/Aptfile -o .dockerdev/Aptfile
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/Dockerfile -o .dockerdev/Dockerfile
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/README.md -o .dockerdev/README.md
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/compose.yml -o .dockerdev/compose.yml
mkdir -p config
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/config/database.yml -o config/database.yml
dip provision
```

Development environment setup:
- Import the full `.dockerdev/` folder from the reference project: `.bashrc`, `.psqlrc`, `Aptfile`, `Dockerfile`, `README.md`, and `compose.yml`.
- Keep `.dockerdev/` files project-local; do not create or edit host-level dotfiles.
- Use the reference container setup as the default development environment.
- Use `dip` for all local development interaction with containers and services. Do not call `docker` or `docker-compose` directly.
- Do not use host-installed PostgreSQL, Redis, Node/Yarn, or other project services for Rails project operations unless the user explicitly asks for a non-container setup.
- Never use `dip` in production, staging, or CI. Those environments must use their native command runner, service configuration, and deployment workflow.
- If `dip provision`, `dip up`, or another `dip` command fails because ports are occupied or container names already exist, stop and ask the user to free those resources, or describe the project-local `.dockerdev`/`dip.yml` changes needed to avoid the conflict. Do not change ports/container names or remove existing containers without confirmation.
- Preserve `.dockerdev/compose.yml` `x-*` extension blocks exactly unless the user explicitly asks to change them.

HAML setup:
- Take HAML gem/configuration from the reference project.
- Do not install or configure HAML manually here.
- Check applicability first, then adapt names/values to current project (for example, replace reference-project identifiers with current project/repo names).

CI setup from reference project:

```bash
# GitHub path (read remotely, no local clone)
curl -fsSL https://api.github.com/repos/purple-magic/base_project/contents/.github/workflows?ref=main
```

If service is not GitHub, implement CI for chosen service with scenario parity to reference GitHub Actions (lint, tests, security checks, deploy gates).

CI notifications:
- If chat is `Discord`, copy/adapt Discord notification steps from reference GitHub workflows and ask user to set `DISCORD_WEBHOOK_URL` in repository secrets (never in chat).
- If chat is not `Discord` (for example Telegram), ask user whether they still want CI notifications and clearly warn that this config will be fully generated and not tested.
- If chat is not `Discord` and user does not want generated notifications, do not apply Discord notification configuration from reference workflows.

## Server/Deploy provisioning setup

Use this only when user confirms server/deploy configuration should be configured during bootstrap. Follow `agents/recipes/deployment-recipe.md` ("Deployment Management Scripts (`bin/`)" and "New-Project Deployment Add-On"); this skill does not use Terraform.

Summary of the flow:
- The server for each environment is recorded in the gitignored `.kamal/servers.yml` (`main_host`, `host`, `server_id`).
- `lib/server_provider.rb` is generated for the hosting the user chose (reference implementation: DigitalOcean through `doctl`; other hostings through their CLI or REST API). It is the only file that talks to the provider.
- `bin/setup -d <environment>` asks whether to create a new server when no IP is recorded; `bin/remove_fully -d <environment>` runs `kamal remove` and deletes the server. Both require the user to type the full environment name first.
- Provider settings that are not secret (`app_name`, `region`, `size`, SSH key fingerprint, domain) are constants in `lib/server_provider.rb`.
- Provider credentials come from the provider CLI's own login (for example `doctl auth init`) or a local environment variable (for example `CLOUDFLARE_API_TOKEN`). The user sets them locally and replies `done`; never ask for them in chat and never write them into the repository.
- Keep deploy database values in Rails credentials by default, following the reference project (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`).

Tooling checks (no server is created by them):

```bash
command -v kamal || gem install kamal
# DigitalOcean reference provider only:
doctl version
doctl account get
```

Important safety notes:
- Do not commit secrets (`.env*`, tokens, private keys). `/.kamal/servers.yml` is gitignored as well.
- Never create or delete a server on the user's behalf, and never answer the typed-confirmation prompts for them.
- When creating or updating Kamal deployment configuration, `.kamal/secrets` must not contain shell `if` statements.
- Keep conditional secret resolution in project scripts or external secret tooling, and keep `.kamal/secrets` as a simple declarative secret-loading file.

Repository secrets setup guide (never in chat):
- Where to set:
  - GitHub: Settings -> Secrets and variables -> Actions -> New repository secret.
  - GitLab: Settings -> CI/CD -> Variables -> Add variable.
- Secret-by-secret source:
  - `DISCORD_WEBHOOK_URL`: Discord -> Server Settings -> Integrations -> Webhooks -> New Webhook -> copy URL.
  - `SSH_PRIVATE_KEY`: content of local deploy private key file (for example `~/.ssh/id_ed25519`); generate with `ssh-keygen` if needed.
  - `SSH_USER`: `root` by default on DigitalOcean Ubuntu unless custom deploy user is configured.
  - `RAILS_MASTER_KEY`: project `config/master.key` (or relevant environment credentials key).
  - Database deploy values: keep `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` in Rails credentials by default, following the reference project.
  - Kamal registry default: localhost registry.
    - Do not require `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD` for localhost registry.
    - Request registry credentials only if user explicitly chooses external registry.
  - `MAIN_HOST`: do not ask the user to set it manually; `bin/setup -d <environment>` records the server IP in `.kamal/servers.yml` itself.
- Ask user to reply `done` after secrets are set, without posting secret values.
- After project creation, guide secret setup in chat one-by-one (wait for `done` after each), not by creating in-app instruction pages.
- Recommended order:
  - `RAILS_MASTER_KEY`
  - `SSH_PRIVATE_KEY`
  - `SSH_USER`
  - `DISCORD_WEBHOOK_URL` (if Discord enabled)
  - `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD` (only if user explicitly chose external registry)

## Deployment management commands

Use `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, and `bin/remove_fully` (Ruby, see `agents/recipes/deployment-recipe.md` "Deployment Management Scripts") for Kamal deploy management and server lifecycle. Do not add or use `Makefile` targets for these commands.

```bash
bin/setup                    # local development bootstrap (no -d flag): bundle install, db:prepare, boot bin/dev
bin/setup -d staging         # no server IP recorded? asks whether to create one (typed "staging" to confirm); then kamal setup -d staging
bin/deploy -d production     # uses the recorded server for production, then kamal deploy -d production
bin/logs -d staging          # uses the recorded server for staging, then kamal app logs -d staging
bin/console -d production    # uses the recorded server for production, then kamal app exec --interactive -d production "bin/rails console"
bin/remove -d staging        # prompts to type "staging" to confirm, then kamal remove -d staging; the server is kept
bin/remove_fully -d staging  # prompts to type "staging" to confirm, then kamal remove AND deletes the server; irreversible, use with great care
```

Whenever these scripts are added or updated, also update the project's `AGENTS.md`/`CLAUDE.md` so future agent sessions use them instead of raw `kamal` commands for `staging`/`production` operations (see `agents/recipes/deployment-recipe.md` "Deployment Management Scripts" rule 9). Do not call `kamal` directly for these environments once the `bin/` scripts exist.

Each script passes its original arguments straight through to the underlying `kamal` command, so any native Kamal flag (`-d`, `-h`, `--version`, etc.) keeps working as it would with plain `kamal`.

Before a real `bin/setup`/`bin/deploy` run, verify every `.kamal/secrets` local secret-resolution command returns a non-empty value (see `agents/recipes/deployment-recipe.md` "`.kamal/secrets` Local Secret Resolution"):

```bash
dip rails runner "puts Rails.application.credentials.dig(:production, :database, :username)"
```

After a `bin/setup`/`bin/deploy` run that Kamal reports as successful, smoke-check the real page, not just Kamal's health check:

```bash
curl -skL -o /dev/null -w '%{http_code}' https://<host>/
```

A non-2xx result (after redirects) is a deploy failure to investigate with `bin/logs -d <environment>`, even though Kamal and the container health check both reported success.

## Local App Lifecycle

```bash
dip up
dip rails server
dip rails console
dip rails runner 'puts Rails.version'
```

## Local Testing

Default policy:
- Use RSpec for feature generation unless user explicitly asks for another framework.
- Do not generate model tests unless user explicitly requests model tests.
- Use these `dip` commands only in local development. In CI, use CI-native test commands and services.

```bash
dip rspec
dip rspec path/to/spec.rb:42
```

## Local Lint and Security

```bash
dip rubocop
dip brakeman -q
dip bundle audit check --update
```

## Local Database

```bash
dip rails db:prepare
dip rails db:migrate
dip rails db:rollback STEP=1
dip rails db:seed
dip rails dbconsole
```

## Database dump/restore from deployed environment

Use this when the user asks to implement dump/restore, dump a deployed database into local development, or add `bin/dump -d ENVIRONMENT` behavior.

Read these files remotely from the reference project `main` branch and adapt them:

```bash
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/dump
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/script/dump/prepare_secrets.rb
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/script/dump/restore
```

Required workflow:
- Top-level executable command must be `bin/dump -d <environment>` (the reference project's `dump` is relocated to `bin/dump` and takes `-d` instead of a positional argument).
- `bin/dump` calls `ruby script/dump/prepare_secrets.rb "$environment"`.
- Before adapting `prepare_secrets.rb`, inspect how the current project's Kamal setup gets secrets.
- Check `config/deploy*.yml` `env.clear`, `env.secret`, accessories, builder/registry secrets, `.kamal/secrets*`, `config/secrets*`, `bin/kamal`, and any scripts those files call.
- Secrets must come from the same source Kamal already uses in the current project: Rails credentials, `.kamal/secrets`, 1Password/`op`, dotenv, repository/env variables, or another project-local secret command.
- Use Rails credentials paths from the reference project only when the current Kamal setup already uses Rails credentials for those values.
- Environment variables may remain explicit overrides, matching the reference flow.
- Remote dump is created through `kamal app exec -d "$environment"` with `pg_dump --format=custom --encoding=UTF8 --no-owner`.
- Dump is downloaded with `scp` and restored locally with `pg_restore --clean --if-exists --no-owner`.
- Restore overwrites the local development database and then recreates/migrates the local test database as in the reference flow.
- Tell the user that dumping, downloading, and restoring a full deployed database can be very heavy for large databases.
- Ask which high-row-count tables the user wants to exclude from dumped data before writing/adapting `bin/dump`.
- Copy the reference script's `EXCLUDED_TABLES=(...)` approach. Put selected tables in that static list and keep the command shape as `bin/dump -d <environment>`.
- Each excluded table must become `--exclude-table-data=<table>` for `pg_dump`, so table schemas are restored but row data is skipped.

Adapt project-specific values:
- Kamal storage volume/path, replacing `base_project_storage`.
- Local development database name, replacing `base_project_development`.
- Static `EXCLUDED_TABLES` list based on current schema and the user's answer.
- Deploy SSH user if current deployment does not use `root@$MAIN_HOST`.
- Secret lookup inside `script/dump/prepare_secrets.rb`, matching the current project's existing Kamal secret source instead of introducing a second source.

Validation without live dump:

```bash
bash -n bin/dump
ruby -c script/dump/prepare_secrets.rb
ruby -c script/dump/restore
test -x bin/dump
```

Do not run `bin/dump -d <environment>` unless the user explicitly confirms they want to overwrite local development data.

## Code health

```bash
dip rails zeitwerk:check
dip rails routes
dip rails about
find app/views -type f \( -name "*.erb" -o -name "*.builder" \)
```

## Update/upgrade from reference project

```bash
# Read reference repository metadata remotely (no local clone)
curl -fsSL https://api.github.com/repos/purple-magic/base_project/contents?ref=main
```

Inspect config-first differences:

```bash
# Compare against remote reference files by downloading specific paths when needed
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/Gemfile
```

After downloading reference content:
- Verify it is applicable to current project setup.
- Rewrite project-specific values (project name, repository URL, CI env vars, service identifiers) before applying.
- For project update/upgrade requests, always inspect the reference project for applicable updates to `bin/setup`/`bin/deploy`/`bin/logs`/`bin/console`/`bin/remove`/`bin/remove_fully`/`lib/kamal_cli.rb`/`lib/server_provider.rb` and deployment configuration, and check for a leftover `terraform/` setup to migrate.
- If those `bin/`, deployment, or provisioning updates are applicable, update/adapt them instead of skipping them by default.
- For `update deployment` requests, apply all applicable deployment-related setup from the reference project, including `bin/setup`/`bin/deploy`/`bin/logs`/`bin/console`/`bin/remove`/`bin/remove_fully`, `AGENTS.md`/`CLAUDE.md` deployment-command guidance, and the server-provisioning flow (migrating any leftover `terraform/` setup per `agents/recipes/deployment-recipe.md` "Migrating Away From Terraform").
- Report what was updated and what was not updated, including reason for each non-updated item.

## Jobs and cache

```bash
dip rails runner 'puts ActiveJob::Base.queue_adapter.class'
dip rails tmp:cache:clear
```
