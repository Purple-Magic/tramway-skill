# Rails Rules

Load this file when the task touches models, routes, seeds, migrations, services, configuration, deployment commands, or general Rails conventions.

## Data And Routing

- Do not use `id` as a parameter outside `admin` namespace. Use `uuid`.
- If a page must expose a record identifier and it does not have `uuid`, add a migration to provide it.
- Do not add ActiveRecord validations to `uuid`.
- Use this migration pattern for UUID columns:

```ruby
add_column table_name, :uuid, :uuid, default: -> { "uuid_generate_v4()" }
```

- Do not use `match` in routes.
- Use `resources` for standard routes and `get`, `post`, `patch`, `delete` for custom routes.

## Seeds

- Create seeds for every model that is introduced.
- Add feature-specific seeds for implemented functionality.
- Use `find_or_create_by` to avoid duplicates.
- Add comments to explain what each seed block creates.
- Print seed progress with `puts` and `colorize`.

Example:

```ruby
puts "Creating users...".colorize(:blue)
```

## Syntax And Modeling

- Use symbols directly instead of constants that only wrap symbols.
- Do not define constants just to hold a single string literal used once, such as `ACTIVE_AASM_STATE = "active"`.
- Do not create modules and classes with the same singular name.
- Use model scopes instead of private controller/model methods for object collections.
- Use `enumerize` for enumerated attributes, not `boolean` or `integer`.
- Ensure `ApplicationRecord` extends `Enumerize` when needed.
- For process states, prefer `aasm` instead of forcing the state into `enumerize`.
- When using `aasm`, use its generated scopes instead of querying `aasm_state` directly, such as `Habit.active` rather than `Habit.where(aasm_state: :active)`.
- For `enumerize`, use `scope: :shallow` instead of custom scopes for enumerated values.

Example:

```ruby
enumerize :role, in: [:admin, :default], scope: :shallow
```

## Configuration And Localization

- Use `anyway_config` for configuration.
- Use Rails localization as much as possible.
- Do not create locale-selection hashes or translated copy directly inside Ruby files.

## Prompts

- Store prompts in `.md` files, not in Ruby code.

## Deployment

- Terraform create commands must not include destroy actions unless the user explicitly asks for destroy flows.
- If destroy behavior is needed, keep it in a separate command.
- Any directory referenced only through a `.gitignore` negation exception (for example `!/app/assets/builds/.keep`) must have that `.keep` file actually created and committed in the same change that adds the `.gitignore` rule. Kamal's builder clones the repository fresh for each build; it does not use the local working tree. An uncommitted `.keep` is a silent no-op: the directory is simply absent from the build clone, which can make an asset pipeline (Propshaft, Sprockets) drop generated assets from its manifest and 500 at runtime even though the Docker build and Kamal health check both succeed.
- Any command inside `.kamal/secrets` that resolves a secret by running Rails/Ruby locally (`rails runner`, `rails credentials:...`, etc.) must go through the project's configured local command runner (`dip rails runner ...` for `dip`-based projects), never bare `bin/rails`/`rails`/`bundle exec rails`. `.kamal/secrets` runs on the host, not inside any project container, so a bare Rails command fails silently there when project gems are only installed inside the local dev container, and `$(...)` captures an empty string instead of raising.

## Controllers And Services

- Keep controllers thin.
- Do not add private controller methods for business logic.
- Move business logic into service objects.
- Create `app/services/base_service.rb` if it is missing and service work is needed.

Base service shape:

```ruby
class BaseService
  extend Dry::Initializer[undefined: false]
  include Dry::Monads[:do, :result]

  def self.call(...)
    new(...).call
  end
end
```

## Models

- Do not create models, in case the database table for the task is not needed.
