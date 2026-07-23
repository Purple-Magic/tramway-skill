# Deployment Recipe

Use this recipe for `Implement deployment`, `update deployment`, or deployment setup requested during new Rails project creation.

Before secret handling, load `agents/recipes/save-rails-secrets-1password.md` and follow it for `config/master.key`, Rails credentials keys, staging/production secrets, provider tokens, and repository secrets.

Load `agents/rails.md` for deployment command and configuration conventions. Also load `agents/integrations.md` if deployment touches third-party providers, background delivery, or external service setup.

## Implement Deployment

Treat `Implement deployment` as a full deployment-systems task, not a narrow single-file change.

Required scope:

1. Inspect existing deployment pieces before editing:
   - `config/deploy.yml`
   - `config/deploy.staging.yml`
   - `config/deploy.production.yml`
   - `.kamal/secrets`
   - `terraform/`
   - `Makefile`
   - CI config such as `.github/workflows/` or the equivalent for the current git platform
2. Use the reference project as the primary source:
   - Kamal: `config/deploy.yml`, `config/deploy.staging.yml`, `config/deploy.production.yml`
   - Terraform: files in `terraform/`
   - Management commands: `Makefile`
   - GitHub CI/deploy workflows: `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`, `.github/workflows/deploy-production.yml`
3. Ensure Kamal deployment exists for both `staging` and `production`.
4. Ensure Terraform can create both `staging` and `production`.
5. Ensure `Makefile` covers the deployment management flow for both environments.
6. Ensure CI is implemented. For non-GitHub platforms, preserve the same gate structure as the reference project using that platform's syntax.
7. Adapt imported config to the current project: app name, repository names, environments, hostnames, provider identifiers, and secret names.
8. If deployment uses Auth0, keep Auth0 secrets in Rails credentials when the reference-project approach does so.
9. If deployment files already exist, preserve applicable project-specific values and fill gaps instead of resetting the deployment stack.
10. If creating or updating `.kamal/secrets`, it must not contain shell `if` statements. Keep conditional lookup in scripts or external secret tooling.
11. Verify with the strongest available checks, such as:
    - `terraform -chdir=terraform validate`
    - syntax/consistency checks on Kamal config
    - CI workflow validation where practical
12. If `Makefile` was added or updated, update the target project `README` with concise deployment-management command usage.
13. In the final summary, report what came directly from the reference project and what was adapted.

## Update Deployment

Treat `update deployment` as a deployment-sync task against the reference project.

Required scope:

1. Inspect current deployment-related files:
   - `config/deploy.yml`
   - `config/deploy.staging.yml`
   - `config/deploy.production.yml`
   - `.kamal/secrets`
   - `terraform/`
   - `Makefile`
   - CI deploy workflows/config
2. Read matching deployment files from the reference project.
3. Apply all applicable deployment-related changes.
4. Explicitly include:
   - `Makefile` updates
   - Terraform configuration updates
   - Terraform usage patterns and helper scripts
   - deployment configuration updates
   - `.kamal/secrets` updates, when applicable, with no shell `if` statements
5. If a reference project deployment file is not directly applicable, preserve the reference behavior and adapt it to the current hosting/provider/platform.
6. Keep project-specific identifiers adapted correctly.
7. If `Makefile` was added or updated, tell the user how to use the commands and update the target project `README`.
8. In the final summary, separate direct updates, adapted updates, and unapplied items with reasons.

## New-Project Deployment Add-On

If a new Rails project setup includes server/deploy setup, run this recipe after repository setup and before final bootstrap verification.

1. Ask whether the user already has a server.
2. If not, ask hosting provider. Recommend `DigitalOcean` because this skill has complete setup guidance.
3. If hosting is `DigitalOcean`, import and adapt reference Terraform files:
   - `terraform/main.tf`
   - `terraform/variables.tf`
   - `terraform/update_env_hosts.sh`
   - `terraform/wait_for_ssh.sh`
4. If hosting is not `DigitalOcean`, build Terraform server/deploy configuration for the selected provider.
5. Ask DNS provider. Recommend `Cloudflare` because this skill has complete setup guidance.
6. If DNS is `Cloudflare`, use/adapt Cloudflare Terraform from the reference project.
7. If DNS is not `Cloudflare`, build domain/DNS configuration for the selected provider.
8. Ask the user to choose an SSL/TLS termination variant. There is no default; the user must pick one:
   - `Cloudflare SSL`: Cloudflare terminates TLS at its edge (proxy/orange-cloud on the DNS record). Requires an SSL/TLS encryption mode in Cloudflare (`Full` or `Full (strict)` recommended over `Flexible`) and, when using `Full (strict)`, either a Cloudflare Origin Certificate installed on the server or a publicly trusted cert. Only viable when DNS is `Cloudflare`.
   - `Kamal-based SSL`: `kamal-proxy` issues and renews certificates automatically via Let's Encrypt for the hosts in `config/deploy*.yml` (`proxy.ssl: true` / host-based ACME), with no Cloudflare proxying (DNS record must be un-proxied/"grey-cloud" so ACME HTTP-01 challenges reach the server).
   - If the user's choice does not match one of these two variants, ask them to describe their own SSL setup and adapt the deployment config to it.
9. Apply the chosen SSL variant consistently across `config/deploy.yml`, `config/deploy.staging.yml`, `config/deploy.production.yml`, and, for `Cloudflare SSL`, the Cloudflare Terraform/DNS proxy settings.
10. Keep Terraform files in `terraform/` and ensure scripts are executable when present.
11. Default database secret handling must follow the reference project:
    - Store deploy database values in Rails credentials by default.
    - Include `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` or equivalent values used by the current project.
12. Collect deploy variables only after the project and `terraform/` directory exist.
13. For DigitalOcean, collect `do_token`, `ssh_fingerprint`, `region`, `size`, and `app_name`.
14. For Cloudflare, collect `domain`, `cloudflare_email`, and `cloudflare_api_key`.
15. Keep `terraform/secrets.auto.tfvars` gitignored.
16. Do not ask the user to set `MAIN_HOST` in 1Password before Terraform apply.
17. Validate:
    - `if ! command -v terraform >/dev/null 2>&1; then bash scripts/install_terraform.sh; fi`
    - `terraform -version`
    - `doctl version` only when using the DigitalOcean reference wait script
    - `command -v nc` only when using `wait_for_ssh.sh`
    - `terraform -chdir=terraform init`
    - `terraform -chdir=terraform validate`
    - `terraform -chdir=terraform plan`
18. Apply only after explicit user confirmation with `terraform -chdir=terraform apply`.
19. After apply, if `.env` exists and `update_env_hosts.sh` is present, run `bash terraform/update_env_hosts.sh`.
20. Explain key outputs to the user, including which SSL variant was configured and any manual step it still requires (e.g., setting Cloudflare's SSL/TLS mode in the dashboard).

## Repository Secrets

When requesting deploy/repository secrets, use `save-rails-secrets-1password.md` first, then guide repository setup:

1. Set secrets in repository secrets storage, never in chat.
2. GitHub: Settings -> Secrets and variables -> Actions -> New repository secret.
3. GitLab: Settings -> CI/CD -> Variables -> Add variable.
4. Walk through secrets one-by-one and wait for `done` after each:
   - `RAILS_MASTER_KEY`
   - `SSH_PRIVATE_KEY`
   - `SSH_USER`
   - `DISCORD_WEBHOOK_URL`, if Discord enabled
   - `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD`, only if the user chose an external registry
5. Use `config/master.key` or the relevant environment key as the source for `RAILS_MASTER_KEY`.
6. With localhost Kamal registry, do not request registry credentials.
