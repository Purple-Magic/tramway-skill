# Save Rails Secrets And Keys

Use this recipe when the user asks how to save `config/master.key`, `config/credentials/*.key`, Rails credentials content, staging/production secrets, deployment secrets, or provider tokens. Also use it from new-project, update/upgrade, and deployment workflows whenever those secrets are created, changed, or requested.

## Safety Rules

1. Never ask the user to paste secret values in chat.
2. `config/master.key` and `config/credentials/*.key` are mandatory recovery material. Warn clearly that they are ignored by git, are not stored in repository history, and must be saved in a secure place before the workflow continues.
3. Recommend `1Password` first. It is the preferred option for this skill because deployment guidance already assumes tested password-manager storage patterns.
4. `Bitwarden`, another encrypted password manager, or a company secret manager is acceptable if the user prefers it.
5. Unencrypted `.env*`, notes files, screenshots, chat messages, or local-only plaintext are fallback-only and unsafe. If the user chooses them, warn that losing the machine or files can permanently lose access to the app credentials.
6. Ask the user to reply `done` after each secret is saved. Do not request the secret value.

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
   - `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, if the current deployment design stores database values outside Rails credentials
   - Auth0, API, webhook, and provider secrets used by staging or production
   - `DISCORD_WEBHOOK_URL`, if Discord integration is enabled
   - `SSH_PRIVATE_KEY` and `SSH_USER`, if repository CI/deploy needs them
   - DigitalOcean and Cloudflare tokens only if the user wants them stored in 1Password in addition to local Terraform secret files
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
5. Do not ask the user to create or fill `MAIN_HOST` in 1Password before Terraform apply. Terraform derives and syncs it in the reference-project flow.
6. Walk the user through repository secrets one-by-one and wait for `done` after each.
