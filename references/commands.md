# Rails Command Cookbook

Use `dip` for all Rails/Ruby project commands, except `rails new` during initial project creation.
Inside a Rails project, all Bundler commands must be run via `dip`.
Assume Ruby is already installed. If Rails is missing, run `gem install rails`.
If `dip` is missing, offer installing it via `gem install dip`.

## Environment bootstrap

```bash
dip bundle install
dip rails db:prepare
```

## Create Rails project

Before running commands:
- Ask questions separately (one question per message), not as one large questionnaire.
- Do not ask whether to use `base_project`; notify user it is used by default.
- Ask user for `<project_name>` explicitly and warn that project name should be simple because renaming later is difficult.
- Ask which git service is used (GitHub, GitLab, etc.).
- Ask which chat should receive CI notifications. Supported chats: `Discord`.
- Ask where to store repository (GitHub, GitLab, etc.).
- Ask for remote URL or organization name.
- Default repository visibility to private unless user asks for public.
- Check whether provided repository URL/name already exists on chosen service.
- If repository does not exist, ask user whether to create it.
- Do not ask about app type; create standard Rails app by default.

```bash
if ! command -v rails >/dev/null 2>&1; then gem install rails; fi
rails new <project_name> -d postgresql
cd <project_name>
if ! command -v dip >/dev/null 2>&1; then gem install dip; fi
dip provision
```

HAML setup:
- Take HAML gem/configuration from `base_project`.
- Do not install or configure HAML manually here.

CI setup from reference project:

```bash
# GitHub path (read remotely, no local clone)
curl -fsSL https://api.github.com/repos/purple-magic/base_project/contents/.github/workflows?ref=main
```

If service is not GitHub, implement CI for chosen service with scenario parity to reference GitHub Actions (lint, tests, security checks, deploy gates).

CI notifications:
- If chat is `Discord`, copy/adapt Discord notification steps from reference GitHub workflows and ask user for `DISCORD_WEBHOOK_URL`.
- If chat is not `Discord` (for example Telegram), ask user whether they still want CI notifications and clearly warn that this config will be fully generated and not tested.
- If chat is not `Discord` and user does not want generated notifications, do not apply Discord notification configuration from reference workflows.

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

## Upgrade from reference project

```bash
# Read reference repository metadata remotely (no local clone)
curl -fsSL https://api.github.com/repos/purple-magic/base_project/contents?ref=main
```

Inspect config-first differences:

```bash
# Compare against remote reference files by downloading specific paths when needed
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/Gemfile
```

## Jobs and cache

```bash
dip rails runner 'puts ActiveJob::Base.queue_adapter.class'
dip rails tmp:cache:clear
```
