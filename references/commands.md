# Rails Command Cookbook

Use `dip` for all Rails/Ruby project commands, except `rails new` during initial project creation.
Assume Ruby is already installed. If Rails is missing, install it first.

## Environment bootstrap

```bash
dip bundle install
dip rails db:prepare
```

## Create Rails project

```bash
rails -v || gem install rails
rails new my_app -d postgresql
cd my_app
dip bundle install
dip rails db:prepare
```

## App lifecycle

```bash
dip up
dip rails server
dip rails console
dip rails runner 'puts Rails.version'
```

## Testing

```bash
dip rspec
dip rspec path/to/spec.rb:42
dip rails test
dip rails test test/models/user_test.rb:10
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
