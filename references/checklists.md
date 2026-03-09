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

1. Fetch latest `https://github.com/purple-magic/base_project`.
2. Diff current project with reference, starting from `config/`, `Gemfile*`, CI, and tooling files.
3. Mark each reference change as:
   - Applicable as-is
   - Applicable with adaptation
   - Not applicable
4. Exclude models, business logic, and feature-specific behavior from sync scope.
5. Apply changes in small thematic batches.
6. Preserve HAML-only views and avoid introducing new `.erb` files.
7. Run `dip rails db:prepare`, boot check, and tests after each batch.
8. Summarize applied/skipped updates with reasons.

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
