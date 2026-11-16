# Save Rails Secrets And Keys

Use this recipe when the user asks how to save `config/master.key`, `config/credentials/*.key`, Rails credentials content, staging/production secrets, deployment secrets, or provider tokens. Also use it from new-project, update/upgrade, and deployment workflows whenever those secrets are created, changed, or requested.

## Safety Rules

1. Never ask the user to paste secret values in chat.
2. `config/master.key` and `config/credentials/*.key` are mandatory recovery material. Warn clearly that they are ignored by git, are not stored in repository history, and must be saved in a secure place before the workflow continues.
3. Recommend `1Password` first. It is the preferred option for this skill because deployment guidance already assumes tested password-manager storage patterns.
4. `Bitwarden`, another encrypted password manager, or a company secret manager is acceptable if the user prefers it.
5. Unencrypted `.env*`, notes files, screenshots, chat messages, or local-only plaintext are fallback-only and unsafe. If the user chooses them, warn that losing the machine or files can permanently lose access to the app credentials.
6. Ask the user to reply `done` after each secret is saved. Do not request the secret value.

## Default Storage: Rails Credentials (Then Ask About a Secret Store)

1. **Default:** every secret that is not a key (API/provider tokens, webhook URLs, passwords, third-party secrets) goes into Rails credentials (`rails credentials:edit`, per-environment files when the project uses them) by default. Do not invent another store for them.
2. **Always ask** the user, once per workflow, before storing: "Rails credentials are the default for app secrets. Do you also want to keep operator copies and the master keys in 1Password (recommended, tested with this skill), or in an alternative such as Bitwarden or a company secret manager?" Wait for the answer.
   - Rails credentials only: proceed; the `config/master.key` / `config/credentials/*.key` recovery warning still applies and they still need a secure backup somewhere.
   - 1Password or an alternative: follow the matching flow below for the keys and for any secret the user wants mirrored or that cannot live in Rails credentials (for example `KAMAL_REGISTRY_PASSWORD`, CI/SSH secrets, provider CLI tokens).
3. Never pick the secret store silently, and never move secrets from Rails credentials to a password manager unless the user chose that.
4. Non-secret values are excluded from both: see "Secret vs Non-Secret".
5. Remember the user's answer in the project's `AGENTS.md`/`CLAUDE.md` (store name only, never values) so later workflows do not re-ask unless the user wants to change it.

## When To Run

Run this recipe if the user says anything like:

- "save `config/master.key`"
- "store Rails credentials"
- "where should I put production secrets"
- "use 1Password for secrets"
- "setup deployment secrets"
- "save staging and production credentials"

Also run it automatically during:

1. New Rails project creation after Rails generates `config/master.key`.
2. Project update/upgrade when existing key storage is missing, unsafe, or unknown.
3. Deployment implementation before requesting `RAILS_MASTER_KEY`, Rails credential keys, staging secrets, production secrets, provider tokens, or repository secrets.

## Secret vs Non-Secret (Never Store Plain Config in 1Password)

1Password holds only real secrets. Before adding any field to the item, classify it:

- **Secret (store in 1Password):** anything that grants access or must stay private: `config/master.key`, `config/credentials/*.key`, `RAILS_MASTER_KEY`, passwords, API/provider tokens, `KAMAL_REGISTRY_PASSWORD`, webhook URLs with embedded tokens, `TELEGRAM_BOT_TOKEN`, SSH private keys.
- **Non-secret (do NOT store in 1Password, never ask the user to save or copy it there):** public or descriptive configuration such as `APP_NAME`, `KAMAL_REGISTRY_USERNAME`, `TELEGRAM_BOT_USERNAME`, hostnames/domains, region/size/image names, image repository names, SSH key fingerprints, SSH user names, ports, `RAILS_ENV`, feature flags. Put these in `config/deploy*.yml` (`env.clear`, `registry.username`), the code, or the README, and read them from there.

Rules:

1. When building the list of fields for the item, include only secrets. If the user explicitly asks to also store a non-secret value, you may, but never suggest it.
2. `.kamal/secrets` must not fetch non-secret values through `op`/`$(...)`; non-secret values belong in `env.clear` or `registry.username` in the deploy config.
3. When a username and its token are a pair (for example `TELEGRAM_BOT_USERNAME` and `TELEGRAM_BOT_TOKEN`), save only the token; the username goes into plain config.
4. If an existing project reads a non-secret value from 1Password, flag it during `update deployment` and offer to move it to the deploy config; do not remove it without approval.
5. Do not run `op item create/edit` for non-secret fields, and do not list them in any "save this in 1Password" instruction to the user.

## Recommended 1Password Flow

Guide the user through the app UI unless they explicitly ask for CLI commands:

1. Open `1Password`.
2. Choose the team/shared vault that should hold this project's operational secrets.
3. Create a new item named `<project_name> Rails secrets`.
4. Add fields for each key or secret that exists:
   - `config/master.key`
   - `config/credentials/staging.key`, if present
   - `config/credentials/production.key`, if present
   - `RAILS_MASTER_KEY`, if deployment expects that name
   - `POSTGRES_PASSWORD`, if the current deployment design stores database values outside Rails credentials (`POSTGRES_DB` and `POSTGRES_USER` are non-secret: keep them in the deploy config)
   - Auth0, API, webhook, and provider secrets (secrets only, per the section above) used by staging or production
   - `DISCORD_WEBHOOK_URL`, if Discord integration is enabled
   - `SSH_PRIVATE_KEY` and `SSH_USER`, if repository CI/deploy needs them
   - DigitalOcean and Cloudflare tokens only if the user wants them stored in 1Password in addition to the provider CLI login or local environment variables used by `lib/server_provider.rb`
5. Copy each secret from the local file or provider UI into the matching 1Password field without posting it in chat.
6. Save the item.
7. Ask the user to confirm with `done`.

For `config/master.key`, tell the user exactly what to save:

1. Open the local project file `config/master.key`.
2. Copy the whole value.
3. Paste it into the `config/master.key` field in the `<project_name> Rails secrets` 1Password item.
4. Save and reply `done`.

If environment-specific credentials keys exist, repeat the same steps for each `config/credentials/<environment>.key` file.

## 1Password CLI Option

Use CLI guidance only if the user asks for it or the project already uses `op` in deployment scripts.

1. Check `op` availability with `command -v op`.
2. If missing, tell the user to install and sign in to 1Password CLI before continuing.
3. Prefer creating or updating one item per project, with stable field names matching the filenames or environment variable names.
4. Do not run commands that print secret values into chat or logs.
5. If a command needs the secret value as stdin, instruct the user to run it locally and confirm `done`.

## Deployment Integration

When deployment is involved:

1. Keep Rails app secrets in Rails credentials when the reference-project approach does so.
2. Use 1Password as backup/operator storage for keys and provider tokens, not as a reason to move secrets out of Rails credentials.
3. Repository secrets still belong in repository/CI secret storage when CI requires them.
4. `RAILS_MASTER_KEY` must come from `config/master.key` or the relevant environment key, but the user should save that key in 1Password before adding it to repository secrets.
5. Do not ask the user to create or fill `MAIN_HOST` in 1Password. `bin/setup -d <environment>` records the server IP in the gitignored `.kamal/servers.yml` itself.
6. Walk the user through repository secrets one-by-one and wait for `done` after each.
7. If `.kamal/secrets` resolves any value by running Rails/Ruby locally (`rails runner`, `rails credentials:...`, etc.), that command must go through the project's local command runner (`dip rails runner ...` for `dip`-based projects), never bare `rails`/`bin/rails`, and its output must be verified non-empty before deploying. See `agents/recipes/deployment-recipe.md` "`.kamal/secrets` Local Secret Resolution" for the full rule and the reason it fails silently otherwise.
