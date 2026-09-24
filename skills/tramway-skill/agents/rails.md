# Rails Rules

Load this file when the task touches models, routes, seeds, migrations, services, configuration, deployment commands, or general Rails conventions.

## Data And Routing

- Never make `uuid` the ActiveRecord primary key. `record.id` is always a `bigint` primary key — keep Rails defaults (`create_table :things` without `id: :uuid`) and never configure generators or migrations to produce UUID primary keys.
- `uuid` is a separate, additional column used only for external exposure: URLs, params, API payloads, broadcast targets, and any identifier a client can see. Internal code, associations, foreign keys, and joins keep using `id`.
- Do not use `id` as a parameter outside `admin` namespace. Use `uuid`.
- If a page must expose a record identifier and it does not have `uuid`, add a migration to provide it.
- Do not add ActiveRecord validations to `uuid`.
- Use this migration pattern for UUID columns:

```ruby
add_column table_name, :uuid, :uuid, default: -> { "uuid_generate_v4()" }
```

- Look records up by `uuid` for external requests, and never change the primary key to do it:

```ruby
# good
Chat.find_by!(uuid: params[:chat_id])

# bad — turns uuid into the primary key
class Chat < ApplicationRecord
  self.primary_key = :uuid
end
```

- Foreign keys reference the `bigint` `id` (`t.references :chat, foreign_key: true`), never the `uuid` column.
- If a task requires writing a `.sql` file for a one-off data migration (backfills, data fixes run directly against the database), never commit that file. Create it, let the user run it, and leave it untracked/out of the change — do not `git add` it, and delete it once it has served its purpose if it is no longer needed.

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
- When using `aasm`, name the default state column `aasm_state`. If a model needs a context-specific state column, use the process name in the form `#{process_name}_state`.
- When using `aasm`, use its generated scopes instead of querying the state column directly, such as `Habit.active` rather than `Habit.where(aasm_state: :active)`.
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
