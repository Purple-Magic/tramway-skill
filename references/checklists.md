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
3. Run `dip rails zeitwerk:check`, targeted tests, then full suite.
4. Address deprecations and autoloading warnings.
5. Validate asset pipeline / JS / CSS integration.
6. Record follow-up cleanup tasks.

## Reference Project Upgrade (`base_project`)

1. Read latest `https://github.com/purple-magic/base_project` remotely (do not clone locally).
2. Do not ask whether to use `base_project`; apply it by default and notify user.
3. Diff current project with reference, starting from `config/`, `Gemfile*`, CI, and tooling files.
4. Confirm repository service (GitHub, GitLab, etc.) and apply CI rules:
   - GitHub: sync applicable updates from `.github/workflows` in reference project.
   - Non-GitHub: keep equivalent CI scenarios on chosen platform.
5. Confirm CI notification chat choice (supported: `Discord`) and apply notification rules:
   - Discord: sync Discord notification workflow config and require `DISCORD_WEBHOOK_URL`.
   - Not Discord: ask if generated notifications are needed, and warn they are fully generated and not tested.
   - Not Discord + no explicit confirmation: do not sync Discord-specific workflow notifications.
6. Confirm repository hosting target and creation details:
   - Ask where repository should be stored (GitHub, GitLab, etc.).
   - Ask for remote URL or organization name.
   - Use private visibility by default.
   - Check whether provided repository URL/name exists.
   - If missing, ask user whether to create repository.
7. Before running `dip provision`, fetch `dip.yml` and `config/database.yml` from reference project remotely.
8. Mark each reference change as:
   - Applicable as-is
   - Applicable with adaptation
   - Not applicable
9. For every downloaded reference file/snippet, verify applicability and adapt current project values:
   - Replace `base_project` names/identifiers with current project/repository names.
   - Update env keys/values and service-specific placeholders.
10. Before applying bootstrap imports, present one combined plan (files, applicability, adaptations) and ask once for `yes` or changes.
11. Exclude models, business logic, and feature-specific behavior from sync scope.
12. Apply changes in small thematic batches.
13. Preserve HAML-only views and avoid introducing new `.erb` files.
14. Run `dip rails db:prepare`, boot check, and tests after each batch.
15. Summarize applied/skipped updates with reasons.

## Migration Safety

1. Confirm lock/latency risk for schema changes.
2. Prefer additive changes first; avoid destructive change in same deploy.
3. Add indexes concurrently where supported.
4. Split data backfills from schema migration when large.
5. Test migrate, rollback, migrate locally/CI.
6. Define rollback plan before release.

## Release Readiness

1. Confirm tests and lint are green.
2. Confirm env vars/credentials changes are present.
3. Confirm migration order is deploy-safe.
4. Confirm job workers and queues are healthy.
5. Monitor error rate, latency, and key business flow post-release.
