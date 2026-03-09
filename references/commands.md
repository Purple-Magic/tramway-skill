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

Before running commands, ask user for `<project_name>` explicitly and warn that project name should be simple because renaming later is difficult.

```bash
if ! command -v rails >/dev/null 2>&1; then gem install rails; fi
rails new <project_name> -d postgresql
cd <project_name>
if ! command -v dip >/dev/null 2>&1; then gem install dip; fi
dip bundle install
dip rails db:prepare
```

Set HAML as default template engine:

```bash
dip bundle add haml-rails
mkdir -p config/initializers
cat > config/initializers/generators.rb <<'RUBY'
Rails.application.config.generators do |g|
  g.template_engine :haml
end
RUBY
```

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
git remote add base_project https://github.com/purple-magic/base_project.git
git fetch base_project
git diff --name-status HEAD..base_project/main
```

Inspect config-first differences:

```bash
git diff HEAD..base_project/main -- config/ Gemfile Gemfile.lock .github/ docker-compose* Procfile* bin/
```

## Jobs and cache

```bash
dip rails runner 'puts ActiveJob::Base.queue_adapter.class'
dip rails tmp:cache:clear
```
