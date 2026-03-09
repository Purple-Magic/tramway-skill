# Rails Command Cookbook

Use project wrappers first (`dip`, `bin/*`, `bundle exec`) based on repository conventions.

## Environment bootstrap

```bash
bin/setup
bundle install
bin/rails db:prepare
```

## Create Rails project

```bash
rails new my_app -d postgresql
cd my_app
bin/setup || (bundle install && bin/rails db:prepare)
```

## App lifecycle

```bash
bin/dev
bin/rails server
bin/rails console
bin/rails runner 'puts Rails.version'
```

## Testing

```bash
bin/rspec
bin/rspec path/to/spec.rb:42
bin/rails test
bin/rails test test/models/user_test.rb:10
```

## Lint and security

```bash
bundle exec rubocop
bundle exec brakeman -q
bundle audit check --update
```

## Database

```bash
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:rollback STEP=1
bin/rails db:seed
bin/rails dbconsole
```

## Code health

```bash
bin/rails zeitwerk:check
bin/rails routes
bin/rails about
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
bin/rails runner 'puts ActiveJob::Base.queue_adapter.class'
bin/rails tmp:cache:clear
```
