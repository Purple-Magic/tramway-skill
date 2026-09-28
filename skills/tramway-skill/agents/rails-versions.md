# Rails Version Guidance

Load this file whenever a task needs Rails-version-specific best practices: new project creation, update/upgrade work, dependency/Rails upgrades, or when the user asks what to change for their Rails version.

## Coverage Policy

1. This file only has guidance starting at Rails **8.1.4**. Earlier versions are not covered.
2. Detect the project's Rails version from `Gemfile.lock` (the `rails (X.Y.Z)` line under `GEM` specs) or `Gemfile` if `Gemfile.lock` is absent.
3. If the detected Rails version is lower than `8.1.4`, tell the user directly: best-practice guidance in this skill currently only covers Rails `8.1.4` and higher, so no version-specific suggestions apply to their current version. Do not invent guidance for unsupported versions.
4. If the project is not on Rails yet (new project creation), treat the newly generated version as the one to check against this file once `rails new` has run.
5. When a new Rails release is reviewed and added here, keep the lowest covered version in this policy section in sync with the lowest version heading below.

## Rails 8.1.4

Source: https://github.com/rails/rails/releases/tag/v8.1.4

Reviewed and no project-facing best-practice changes apply. `8.1.4` is a patch release consolidating internal bug fixes (Active Support, Active Model, Active Record, Action Pack, Action View, Active Job, Action Cable, Action Mailer) and does not introduce new conventions, deprecations, or config defaults that require changing application code generated or maintained by this skill.

Do not propose changes to a project on `8.1.4+` solely because of this release; only apply guidance from this file if a later section for a newer version explicitly calls out an action.
