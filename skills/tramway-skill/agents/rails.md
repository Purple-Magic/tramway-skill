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
- Do not create modules and classes with the same singular name.
- Use model scopes instead of private controller/model methods for object collections.
- Use `enumerize` for enumerated attributes, not `boolean` or `integer`.
- Ensure `ApplicationRecord` extends `Enumerize` when needed.
- For process states, prefer `aasm` instead of forcing the state into `enumerize`.
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
