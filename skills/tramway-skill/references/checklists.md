# Rails Checklists

## Incident Triage

1. Confirm impact scope (who, what endpoint/job, since when).
2. Capture exact error, request/job ID, and top backtrace frame.
3. Reproduce in smallest possible environment.
4. Ship mitigation first if needed (flag, rollback, guard clause).
5. Add regression test before permanent fix.
6. Verify fix in logs/metrics after deploy.

## Rails/Gem Upgrade

1. Read release notes and breaking changes.
2. Upgrade smallest unit (patch -> minor -> major).
3. In local development, run `dip rails zeitwerk:check`, targeted tests, then full suite. In CI, use CI-native commands and services; do not use `dip`.
4. Address deprecations and autoloading warnings.
5. Validate asset pipeline / JS / CSS integration.
6. Record follow-up cleanup tasks.

## Reference Project Update/Upgrade

1. Read latest `https://github.com/purple-magic/base_project` remotely (do not clone locally).
2. Do not ask whether to use the reference project; apply it by default and notify user.
3. Diff current project with reference, starting from `config/`, `Gemfile*`, CI, and tooling files.
4. If the user asked for project updating/upgrading, explicitly inspect the reference project for applicable updates to:
   - `.gitignore`
   - `AGENTS.md`
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, `lib/kamal_cli.rb`
   - deployment configuration
   - Terraform configuration
5. Apply/adapt those `.gitignore`, `AGENTS.md`, `bin/setup`/`bin/deploy`/`bin/logs`/`bin/console`/`bin/remove`, deployment, and Terraform updates when they are applicable to the current project.
6. If the user asked to `update deployment`, apply all applicable deployment-related setup from the reference project, including:
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove` (Ruby Kamal proxies, see `agents/recipes/deployment-recipe.md`)
   - `AGENTS.md`/`CLAUDE.md` deployment-command guidance pointing agents at those `bin/` scripts instead of raw `kamal` commands
   - deployment configuration
   - `.kamal/secrets`, when applicable; it must not contain shell `if` statements
   - Terraform configuration
   - Terraform helper/usage scripts and patterns
7. Confirm repository service (GitHub, GitLab, etc.) and apply CI rules:
   - GitHub: sync applicable updates from `.github/workflows` in reference project.
   - Non-GitHub: keep equivalent CI scenarios on chosen platform.
8. Confirm CI notification chat choice (supported: `Discord`) and apply notification rules:
   - Discord: sync Discord notification workflow config and require `DISCORD_WEBHOOK_URL`.
   - Not Discord: ask if generated notifications are needed, and warn they are fully generated and not tested.
   - Not Discord + no explicit confirmation: do not sync Discord-specific workflow notifications.
9. Confirm repository hosting target and creation details:
   - Ask where repository should be stored (GitHub, GitLab, etc.).
   - Ask for remote URL or organization name.
   - Use private visibility by default.
   - Check whether provided repository URL/name exists.
   - If missing, ask user whether to create repository.
10. Before running `dip provision`, fetch `dip.yml`, `config/database.yml`, and the full `.dockerdev/` folder from the reference project remotely.
    - Import `.dockerdev/.bashrc`, `.dockerdev/.psqlrc`, `.dockerdev/Aptfile`, `.dockerdev/Dockerfile`, `.dockerdev/README.md`, and `.dockerdev/compose.yml`.
    - Preserve `.dockerdev/compose.yml` `x-*` extension blocks exactly unless the user explicitly asks to change them.
    - Keep `.dockerdev/` files project-local and do not edit host-level dotfiles.
    - Use `dip` only for local development containers and services. Do not use direct `docker`/`docker-compose` commands or host-installed PostgreSQL, Redis, Node/Yarn, or other project services.
    - Never use `dip` in production, staging, or CI. Those environments must use their native command runner, service configuration, and deployment workflow.
    - If `dip` fails because required ports are occupied or container names already exist, pause and ask the user to free the resources, or explain the project-local `.dockerdev`/`dip.yml` changes needed and wait for confirmation.
11. Mark each reference change as:
   - Applicable as-is
   - Applicable with adaptation
   - Not applicable
12. For every downloaded reference file/snippet, verify applicability and adapt current project values:
   - Replace reference-project names/identifiers with current project/repository names.
   - Update env keys/values and service-specific placeholders.
13. Before applying bootstrap imports, present one combined plan (files, applicability, adaptations) and ask once for `yes` or changes.
14. Exclude models, business logic, and feature-specific behavior from sync scope.
15. Apply changes in small thematic batches.
16. Preserve HAML-only views and avoid introducing new `.erb` files.
17. In local development, run `dip rails db:prepare`, boot check, and tests after each batch. In CI, use CI-native commands and services; do not use `dip`.
18. Summarize applied/skipped updates with reasons for every skipped item, including `.gitignore`, `AGENTS.md`, `bin/setup`/`bin/deploy`/`bin/logs`/`bin/console`/`bin/remove`, deployment, and Terraform decisions.

## Migration Safety

1. Confirm lock/latency risk for schema changes.
2. Prefer additive changes first; avoid destructive change in same deploy.
3. Add indexes concurrently where supported.
4. Split data backfills from schema migration when large.
5. Test migrate, rollback, migrate locally and in CI. Use `dip` only locally; use CI-native commands and services in CI.
6. Define rollback plan before release.

## Release Readiness

1. Confirm tests and lint are green.
2. Confirm env vars/credentials changes are present.
3. Confirm migration order is deploy-safe.
4. Confirm job workers and queues are healthy.
5. Monitor error rate, latency, and key business flow post-release.
