# Rails Command Cookbook

Use `dip` for all Rails/Ruby project commands, except `rails new` during initial project creation.
Inside a Rails project, all Bundler commands must be run via `dip`.
Assume Ruby is already installed. If Rails is missing, run `gem install rails`.
If `dip` is missing, offer installing it via `gem install dip`.
If a task requires Terraform and `terraform` is missing, install it with `bash scripts/install_terraform.sh` before running Terraform commands.

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
- If hosting is `DigitalOcean`, use Terraform configuration from the reference project.
- If hosting is not `DigitalOcean`, build Terraform server/deploy configuration yourself for that hosting.
- Ask what provider they use for domain/DNS hosting. Recommend `Cloudflare` because this skill has complete setup guidance for it.
- If domain hosting is `Cloudflare`, use/adapt Cloudflare Terraform configuration from the reference project.
- If domain hosting is not `Cloudflare`, build Terraform domain/DNS configuration yourself for that provider.
- Do not collect deploy/provider secrets yet. Collect them in deploy setup phase after Rails project and `terraform/` directory exist.
- Do not create or modify user home dotfiles such as `.bashrc`, `.zshrc`, `.psqlrc`, or similar host-level config files unless the user explicitly asked for that.

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

## Server/Deploy Terraform setup

Use this only when user confirms server/deploy configuration should be configured during bootstrap.

When hosting is `DigitalOcean`, import and adapt Terraform files from reference project:

```bash
mkdir -p terraform
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/terraform/main.tf -o terraform/main.tf
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/terraform/variables.tf -o terraform/variables.tf
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/terraform/update_env_hosts.sh -o terraform/update_env_hosts.sh
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/terraform/wait_for_ssh.sh -o terraform/wait_for_ssh.sh
chmod +x terraform/update_env_hosts.sh terraform/wait_for_ssh.sh
```

After import, adapt reference project defaults to current project:
- Replace droplet/resource naming and default `app_name` values.
- If using Cloudflare from reference Terraform, replace subdomain record name and domain values.
- Keep provider versions unless user asks to upgrade.

When hosting is not `DigitalOcean`:
- Build Terraform server/deploy configuration yourself for selected hosting provider.
- Define required providers/resources/variables for selected hosting and current project.

Domain/DNS branch:
- If domain hosting is `Cloudflare`, use/adapt Cloudflare Terraform resources from reference Terraform.
- If domain hosting is not `Cloudflare`, build Terraform DNS configuration yourself for selected provider.

Collect deploy/provider variables now (after project + `terraform/` directory exist):
- If hosting is `DigitalOcean`, collect: `do_token`, `ssh_fingerprint`, `region`, `size`, `app_name`.
  - For `ssh_fingerprint`, default to the system default SSH key; ask custom only on explicit request.
  - If default key is missing in DigitalOcean, add it in DigitalOcean -> API -> Tokens/Keys -> SSH Keys and use its fingerprint.
  - `do_token` retrieval: DigitalOcean -> API -> Tokens/Keys -> Personal access tokens -> Generate New Token.
  - Put token into `terraform/secrets.auto.tfvars` and reply `done` without posting secret value in chat.
- If hosting is not `DigitalOcean`, collect provider-specific server/deploy Terraform inputs.
- If domain hosting is `Cloudflare`, collect: `domain`, `cloudflare_email`, `cloudflare_api_key`.
  - `cloudflare_api_key` retrieval: Cloudflare -> My Profile -> API Tokens -> Global API Key -> View.
  - Put key into `terraform/secrets.auto.tfvars` and reply `done` without posting secret value in chat.
- If domain hosting is not `Cloudflare`, collect provider-specific DNS Terraform inputs.
- Store all Terraform variables/secrets in `terraform/secrets.auto.tfvars` and keep it gitignored.

Tooling checks required by the reference Terraform flow:

```bash
if ! command -v terraform >/dev/null 2>&1; then bash scripts/install_terraform.sh; fi
terraform -version
# only when using DigitalOcean reference wait script:
doctl version
command -v nc
```

Terraform execution flow:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
# run apply only after explicit user confirmation
terraform -chdir=terraform apply
```

After successful apply:

```bash
# optional: if project .env exists and script is present
bash terraform/update_env_hosts.sh
terraform -chdir=terraform output
```

Important safety notes:
- Do not commit secrets (`*.tfvars`, `.env*`, tokens, private keys, state secrets).
- Keep Terraform credentials in local environment/secrets manager and CI/repository secrets.
- For Terraform local secret storage, default to `terraform/secrets.auto.tfvars` (gitignored).

Repository secrets setup guide (never in chat):
- Where to set:
  - GitHub: Settings -> Secrets and variables -> Actions -> New repository secret.
  - GitLab: Settings -> CI/CD -> Variables -> Add variable.
- Secret-by-secret source:
  - `DISCORD_WEBHOOK_URL`: Discord -> Server Settings -> Integrations -> Webhooks -> New Webhook -> copy URL.
  - `MAIN_HOST`: `terraform -chdir=terraform output -raw main_host_ip` (after apply).
  - `SSH_PRIVATE_KEY`: content of local deploy private key file (for example `~/.ssh/id_ed25519`); generate with `ssh-keygen` if needed.
  - `SSH_USER`: `root` by default on DigitalOcean Ubuntu unless custom deploy user is configured.
  - `RAILS_MASTER_KEY`: project `config/master.key` (or relevant environment credentials key).
  - Kamal registry default: localhost registry.
    - Do not require `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD` for localhost registry.
    - Request registry credentials only if user explicitly chooses external registry.
- Ask user to reply `done` after secrets are set, without posting secret values.
- After project creation, guide secret setup in chat one-by-one (wait for `done` after each), not by creating in-app instruction pages.
- Recommended order:
  - `RAILS_MASTER_KEY`
  - `SSH_PRIVATE_KEY`
  - `SSH_USER`
  - `MAIN_HOST`
  - `DISCORD_WEBHOOK_URL` (if Discord enabled)
  - `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD` (only if user explicitly chose external registry)

## App lifecycle

```bash
dip up
dip rails server
dip rails console
dip rails runner 'puts Rails.version'
```

## Testing

Default policy:
- Use RSpec for feature generation unless user explicitly asks for another framework.
- Do not generate model tests unless user explicitly requests model tests.

```bash
dip rspec
dip rspec path/to/spec.rb:42
```

## Lint and security

```bash
dip rubocop
dip brakeman -q
dip bundle audit check --update
```

## Database

```bash
dip rails db:prepare
dip rails db:migrate
dip rails db:rollback STEP=1
dip rails db:seed
dip rails dbconsole
```

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
- For project update/upgrade requests, always inspect the reference project for applicable updates to `Makefile`, deployment configuration, and Terraform configuration.
- If those `Makefile`, deployment, or Terraform updates are applicable, update/adapt them instead of skipping them by default.
- For `update deployment` requests, apply all applicable deployment-related setup from the reference project, including `Makefile`, Terraform configuration, and Terraform usage/helper-script patterns.
- Report what was updated and what was not updated, including reason for each non-updated item.

## Jobs and cache

```bash
dip rails runner 'puts ActiveJob::Base.queue_adapter.class'
dip rails tmp:cache:clear
```
