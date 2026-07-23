# Deployment Recipe

Use this recipe for `Implement deployment`, `update deployment`, or deployment setup requested during new Rails project creation.

Before secret handling, load `agents/recipes/save-rails-secrets-1password.md` and follow it for `config/master.key`, Rails credentials keys, staging/production secrets, provider tokens, and repository secrets.

Load `agents/rails.md` for deployment command and configuration conventions. Also load `agents/integrations.md` if deployment touches third-party providers, background delivery, or external service setup.

## Deployment Management Scripts (`bin/`)

Deploy/infra management commands (setup, deploy, logs, console, remove) are Ruby scripts under `bin/`, not `Makefile` targets. Each script is a thin proxy for the matching Kamal command: it preloads the environment Kamal needs for the target destination, then hands off to `kamal` with the original arguments intact, the same way the reference project's `Makefile` + `terraform/run_kamal_*.sh` helpers resolve `MAIN_HOST`/`DB_HOST`/`HOST`/`RAILS_ENV` before invoking Kamal.

Keep `Makefile` only for Terraform provisioning targets that are not one of these five commands (for example `terraform_init`, `create_new_production`, `destroy_staging`), when the project already has them. Do not keep duplicate `Makefile` targets for `setup`/`deploy`/`logs`/`console`/`remove` once the `bin/` scripts exist.

Required scripts:

- `bin/setup` — with no `-d`/`--destination` flag, keep Rails' own local-development bootstrap behavior (bundle install, `db:prepare`, clear logs/tmp, boot `bin/dev`) unchanged. With `-d staging` or `-d production`, resolve the Terraform outputs for that destination, wait for SSH, export the environment, then `exec kamal setup` with the original arguments.
- `bin/deploy` — resolve the Terraform outputs/environment for the given `-d`/`--destination`, then `exec kamal deploy` with the original arguments.
- `bin/logs` — resolve the same environment, then `exec kamal app logs` with the original arguments.
- `bin/console` — resolve the same environment, then `exec kamal app exec --interactive` with the original arguments plus the Rails console command.
- `bin/remove` — resolve the same environment, require the operator to type the destination name to confirm (matching this skill's other destructive-operation confirmations), then `exec kamal remove` with the original arguments. `kamal remove` tears down the app, containers, and networks on that server, so it must not run without an explicit typed confirmation.

Shared logic (Terraform workspace selection, output resolution, required-command checks) belongs in `lib/kamal_cli.rb` and is `require_relative`d from each `bin/` script, not copy-pasted per script.

`lib/kamal_cli.rb`:

```ruby
require "open3"

module KamalCli
  module_function

  def destination_from(args)
    args.each_cons(2) { |flag, value| return value if %w[-d --destination].include?(flag) }
    nil
  end

  def require_commands!(*names)
    names.each do |name|
      next if system("command -v #{name} > /dev/null 2>&1")

      abort "Missing required command: #{name}"
    end
  end

  def terraform_output(name)
    stdout, status = Open3.capture2("terraform", "-chdir=terraform", "output", "-raw", name)
    abort "Terraform output '#{name}' is unavailable. Run terraform apply first." unless status.success?

    stdout.strip
  end

  def select_workspace!(destination)
    return if system("terraform", "-chdir=terraform", "workspace", "select", destination, out: File::NULL, err: File::NULL)

    abort "Terraform workspace '#{destination}' does not exist. Provision it before running Kamal commands."
  end

  # Resolves MAIN_HOST/DB_HOST/HOST/RAILS_ENV for `destination` from Terraform
  # outputs and exports them, mirroring terraform/run_kamal_*.sh in the reference project.
  def load_environment!(destination)
    require_commands!("terraform", "kamal")
    select_workspace!(destination)

    main_host = terraform_output("main_host_ip")
    host = terraform_output("subdomain_url")
    abort "Terraform output 'main_host_ip' is empty for workspace '#{destination}'." if main_host.empty?
    abort "Terraform output 'subdomain_url' is empty for workspace '#{destination}'." if host.empty?

    ENV["MAIN_HOST"] = main_host
    ENV["DB_HOST"] = main_host
    ENV["HOST"] = host
    ENV["RAILS_ENV"] = destination

    { main_host: main_host, host: host }
  end
end
```

`bin/setup`:

```ruby
#!/usr/bin/env ruby
require "fileutils"
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV)

if destination.nil?
  # No -d/--destination given: local development bootstrap, unchanged from Rails' default bin/setup.
  FileUtils.chdir(File.expand_path("..", __dir__)) do
    puts "== Installing dependencies =="
    system("bundle check") || system("bundle", "install", exception: true)

    puts "\n== Preparing database =="
    system("bin/rails", "db:prepare", exception: true)
    system("bin/rails", "db:reset", exception: true) if ARGV.include?("--reset")

    puts "\n== Removing old logs and tempfiles =="
    system("bin/rails", "log:clear", "tmp:clear", exception: true)

    unless ARGV.include?("--skip-server")
      puts "\n== Starting development server =="
      STDOUT.flush
      exec "bin/dev"
    end
  end
  exit
end

info = KamalCli.load_environment!(destination)
puts "Running Kamal setup for '#{destination}' with MAIN_HOST=#{info[:main_host]} and HOST=#{info[:host]}"

if File.executable?("terraform/wait_for_ssh.sh")
  droplet_id = KamalCli.terraform_output("droplet_id")
  system("./terraform/wait_for_ssh.sh", info[:main_host], "22", droplet_id, exception: true)
end

exec("kamal", "setup", *ARGV)
```

`bin/deploy`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/deploy -d <staging|production> [kamal deploy options]"
info = KamalCli.load_environment!(destination)
puts "Deploying '#{destination}' with MAIN_HOST=#{info[:main_host]} and HOST=#{info[:host]}"

exec("kamal", "deploy", *ARGV)
```

`bin/logs`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/logs -d <staging|production> [kamal app logs options]"
KamalCli.load_environment!(destination)

exec("kamal", "app", "logs", *ARGV)
```

`bin/console`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/console -d <staging|production>"
KamalCli.load_environment!(destination)

exec("kamal", "app", "exec", "--interactive", *ARGV, "bin/rails console")
```

`bin/remove`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/remove -d <staging|production> [kamal remove options]"
KamalCli.load_environment!(destination)

print "Type '#{destination}' to confirm removing the app from that server: "
confirmation = $stdin.gets&.strip
abort "Confirmation did not match '#{destination}'. Aborting." unless confirmation == destination

exec("kamal", "remove", *ARGV)
```

Rules:

1. `chmod +x bin/setup bin/deploy bin/logs bin/console bin/remove` and keep `#!/usr/bin/env ruby` as the shebang on each.
2. Pass the original `ARGV` straight through to `kamal` (including `-d <destination>`) so every native Kamal flag keeps working exactly as `kamal <subcommand> ...` would; do not reimplement or restrict Kamal's own CLI surface.
3. Do not duplicate the Terraform-output/env-var resolution logic per script; keep it in `lib/kamal_cli.rb`.
4. If the project uses 1Password for host sync (see `terraform/sync_1password_hosts.sh` in the reference project), call that sync from `KamalCli.load_environment!` before exporting `MAIN_HOST`/`HOST`, instead of duplicating the sync per script.
5. `exec` the final `kamal ...` call (not `system`) so exit codes and signals propagate normally.
6. When implementing or updating deployment, replace any existing `Makefile` targets named `setup_<env>`, `deploy_<env>`, `logs_<env>`, `remove_<env>`, or similar with these five `bin/` scripts; do not keep both.
7. Update the target project `README` with `bin/setup -d <environment>`, `bin/deploy -d <environment>`, `bin/logs -d <environment>`, `bin/console -d <environment>`, and `bin/remove -d <environment>` usage whenever these scripts are added or changed.
8. Never run `bin/remove` unsupervised or as part of an automated flow; only run it when the user explicitly confirms they want that environment's app removed.
9. Whenever `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, or `bin/remove` are created or updated, update the target project's `AGENTS.md` (and `CLAUDE.md` if it does not simply delegate to `AGENTS.md`) so future Codex/Claude Code sessions in that project use these scripts instead of raw `kamal` commands for staging/production operations. Preserve existing `AGENTS.md`/`CLAUDE.md` content and add or refresh only the deployment-command guidance; do not replace the file wholesale. Use wording equivalent to:

   > For Kamal/deploy operations against `staging` or `production`, use `bin/setup -d <environment>`, `bin/deploy -d <environment>`, `bin/logs -d <environment>`, `bin/console -d <environment>`, and `bin/remove -d <environment>` instead of running `kamal` directly. These scripts preload the environment (`MAIN_HOST`/`DB_HOST`/`HOST`/`RAILS_ENV`) that Kamal needs for that destination.
10. After any successful `bin/setup -d <environment>` or `bin/deploy -d <environment>` (Kamal itself reports success), run an HTTP smoke check against the deployed host's real URL — not just Kamal's own container health check — for example:

    ```bash
    curl -skL -o /dev/null -w '%{http_code}' https://<host>/
    ```

    A container passing its health check only proves the process is up; it does not prove a real page renders. Treat any response that isn't a terminal 2xx (following redirects) as a deploy failure and investigate with `bin/logs -d <environment>` before telling the user the deploy succeeded.

## `.kamal/secrets` Local Secret Resolution

`.kamal/secrets` is evaluated by the local Kamal process on the host machine, not inside any project container. This is a common source of deploys that look successful (Kamal reports success, the container passes its health check) but 500 on the actual page, because the failure only surfaces in an accessory's container logs, not in Kamal's own web-role deploy output.

1. Any `$(...)` command inside `.kamal/secrets` that needs to run Rails/Ruby locally to resolve a secret (`rails runner`, `rails credentials:...`, etc.) must go through the project's configured local command runner — `dip rails runner ...` for `dip`-based projects — never bare `bin/rails`, `rails`, or `bundle exec rails`. Bare Rails commands only work when the project's gems are installed on the host Ruby, which `dip`-based projects intentionally do not do; the command fails with something like `Bundler::GemNotFound` on the host, and Kamal never sees that failure directly.
2. Redirect stderr on these substitutions (`2>/dev/null`). `dip`'s own container-startup/compose status lines print to stderr and would otherwise leak into the captured secret value.
3. A failed or empty local secret resolution does not raise a loud error at the point of failure: `$(...)` simply captures an empty string, and Kamal boots the affected accessory (for example Postgres) with that empty value (for example an empty `POSTGRES_PASSWORD`), which then crash-loops with an error like "Database is uninitialized and superuser password is not specified" in the accessory's own logs, not in Kamal's web-role deploy output. Treat an empty resolved secret as equivalent to a hard deployment failure, not a warning.
4. Before running `bin/setup`/`bin/deploy` against a real server, resolve every `$(...)` command from `.kamal/secrets` locally using the same local command runner and confirm each one returns a non-empty value, for example:

   ```bash
   dip rails runner "puts Rails.application.credentials.dig(:production, :database, :username)"
   ```

   An empty result here is the actual failure mode to catch — nothing else errors loudly, so this check must run every time `.kamal/secrets` is created or changed, before the next `bin/setup`/`bin/deploy`.

## Implement Deployment

Treat `Implement deployment` as a full deployment-systems task, not a narrow single-file change.

Required scope:

1. Inspect existing deployment pieces before editing:
   - `config/deploy.yml`
   - `config/deploy.staging.yml`
   - `config/deploy.production.yml`
   - `.kamal/secrets`
   - `terraform/`
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, `lib/kamal_cli.rb`
   - `AGENTS.md`, `CLAUDE.md` (deployment-command guidance)
   - `Makefile` (Terraform provisioning targets only)
   - CI config such as `.github/workflows/` or the equivalent for the current git platform
2. Use the reference project as the primary source:
   - Kamal: `config/deploy.yml`, `config/deploy.staging.yml`, `config/deploy.production.yml`
   - Terraform: files in `terraform/`
   - Provisioning commands: `Makefile` (`terraform_init`, `create_new_*`, `destroy_*`)
   - GitHub CI/deploy workflows: `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`, `.github/workflows/deploy-production.yml`
3. Ensure Kamal deployment exists for both `staging` and `production`.
4. Ensure Terraform can create both `staging` and `production`.
5. Ensure `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, and `bin/remove` cover the deploy-management flow for both environments, per "Deployment Management Scripts (`bin/`)" above.
6. Ensure CI is implemented. For non-GitHub platforms, preserve the same gate structure as the reference project using that platform's syntax.
7. Adapt imported config to the current project: app name, repository names, environments, hostnames, provider identifiers, and secret names.
8. If deployment uses Auth0, keep Auth0 secrets in Rails credentials when the reference-project approach does so.
9. If deployment files already exist, preserve applicable project-specific values and fill gaps instead of resetting the deployment stack.
10. If creating or updating `.kamal/secrets`, it must not contain shell `if` statements. Keep conditional lookup in scripts or external secret tooling. Any local secret-resolution command in it must follow "`.kamal/secrets` Local Secret Resolution" above (project's local command runner, stderr redirected).
11. If a `.gitignore` rule was added or changed that excludes a directory except a `.keep` file (`!/path/.keep`), create and commit that `.keep` file in the same change; do not leave it as an uncommitted no-op (see `agents/rails.md` "Deployment").
12. Verify with the strongest available checks, such as:
    - `terraform -chdir=terraform validate`
    - syntax/consistency checks on Kamal config
    - `ruby -c` on `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, and `lib/kamal_cli.rb`
    - resolve every `$(...)` secret-lookup command from `.kamal/secrets` locally (e.g. `dip rails runner "puts Rails.application.credentials.dig(...)"`) and confirm each returns a non-empty value, before running `bin/setup`/`bin/deploy` against a real server
    - `git ls-files <dir>/.keep` for every directory with a `.gitignore` `.keep`-exception pattern (e.g. `git ls-files app/assets/builds/.keep`), to confirm it is actually committed and will exist in Kamal's fresh build clone
    - CI workflow validation where practical
13. If `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, or `bin/remove` were added or updated, update the target project `README` with concise deployment-management command usage, and update `AGENTS.md`/`CLAUDE.md` per rule 9 in "Deployment Management Scripts (`bin/`)" above.
14. After a real `bin/setup`/`bin/deploy` run against a server, run the HTTP smoke check from "Deployment Management Scripts (`bin/`)" rule 10 against the deployed host before reporting the deploy as done.
15. In the final summary, report what came directly from the reference project and what was adapted.

## Update Deployment

Treat `update deployment` as a deployment-sync task against the reference project.

Required scope:

1. Inspect current deployment-related files:
   - `config/deploy.yml`
   - `config/deploy.staging.yml`
   - `config/deploy.production.yml`
   - `.kamal/secrets`
   - `terraform/`
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, `lib/kamal_cli.rb`
   - `AGENTS.md`, `CLAUDE.md` (deployment-command guidance)
   - `Makefile` (Terraform provisioning targets only)
   - CI deploy workflows/config
2. Read matching deployment files from the reference project.
3. Apply all applicable deployment-related changes.
4. Explicitly include:
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, and `lib/kamal_cli.rb` updates, per "Deployment Management Scripts (`bin/`)" above
   - Terraform configuration updates
   - Terraform usage patterns and helper scripts
   - deployment configuration updates
   - `.kamal/secrets` updates, when applicable, with no shell `if` statements and following "`.kamal/secrets` Local Secret Resolution" above
   - If a project still has `Makefile` targets for `setup`/`deploy`/`logs`/`console`/`remove`, replace them with the `bin/` scripts and remove the old targets
   - Any `.gitignore` `.keep`-exception directory (e.g. `app/assets/builds`) actually has its `.keep` file created and committed, not just declared in `.gitignore`
5. If a reference project deployment file is not directly applicable, preserve the reference behavior and adapt it to the current hosting/provider/platform.
6. Keep project-specific identifiers adapted correctly.
7. If `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, or `bin/remove` were added or updated, tell the user how to use the commands, update the target project `README`, and update `AGENTS.md`/`CLAUDE.md` per rule 9 in "Deployment Management Scripts (`bin/`)" above.
8. Before confirming the update is done, resolve every `$(...)` secret-lookup command from `.kamal/secrets` locally (non-empty check), run `git ls-files <dir>/.keep` for every `.gitignore` `.keep`-exception directory, and, after the next real `bin/setup`/`bin/deploy`, run the HTTP smoke check from "Deployment Management Scripts (`bin/`)" rule 10.
9. In the final summary, separate direct updates, adapted updates, and unapplied items with reasons.

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
