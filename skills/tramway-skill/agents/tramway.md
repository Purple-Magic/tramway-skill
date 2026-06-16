# Tramway Rules

Load this file when the task touches Tramway entities, forms, decorators, components, controller patterns around Tramway, or default CRUD behavior.

## Core Principle

- Generated code should feel like curated documentation: simple, explicit, and aligned with Tramway defaults.
- Prefer Tramway defaults and generators over hand-rolled Rails setup.
- Use domain language instead of generic names.
- Keep logic in the correct layer: models for data and validations, controllers for HTTP, components for reusable UI, and views for straightforward rendering.
- Prefer short methods, guard clauses, and naming that does not require comments.

## Project Overview

Tramway extends Rails with:

- CRUD actions configured in `config/initializers/tramway.rb`
- generators such as `dip rails g tramway:install`
- ViewComponents for reusable UI
- Tailwind safelist utilities for dynamic classes

**MANDATORY: Before writing or modifying any of the following, fetch and read the upstream Tramway README:**

- Any call to a `tramway_*` helper (e.g. `tramway_form_for`, `tramway_table`, `tramway_button`, `tramway_tooltip`, etc.)
- Any class that inherits from a class in the `Tramway::` namespace (e.g. `Tramway::BaseForm`, `Tramway::BaseDecorator`, or any other `Tramway::Base*`)

```text
https://raw.githubusercontent.com/Purple-Magic/tramway/refs/heads/main/README.md
```

Do not rely on memory or prior knowledge of the Tramway API for these cases — always fetch the README first.

**NEVER read installed gem source files** (e.g. files under `/usr/local/bundle/gems/tramway-*/`, `$(bundle show tramway)/`, or any gem path) to understand how Tramway works. Gem source inspection is prohibited. If the README does not answer the question, ask the user — do not fall back to reading gem files.

## Quick Start Workflow

Prefer installing Tramway defaults before hand-rolling setup:

```bash
dip rails g tramway:install
```

The install generator appends missing gems, copies Tailwind safelist config, ensures `app/assets/tailwind/application.css` imports Tailwind, and writes an `AGENTS.md` guide in the project root.

**MANDATORY: Any time the tramway gem is added or upgraded, run `dip rails g tramway:install` immediately after the bundle step, before any other validation.**

## Technology Stack And Gems

- Expect Rails 7+ with `kaminari`, `view_component`, `haml-rails`, `dry-initializer`, and `tailwindcss-rails`.
- Prefer Haml for views unless the existing component or file uses ERB.
- Keep JavaScript minimal. Use Stimulus if needed and avoid SPA patterns unless explicitly requested.
- Do not add JavaScript or CSS code to Ruby helper files under `app/helpers/`. Put UI markup in views or ViewComponents, JavaScript in Stimulus or separate `.js` files, and CSS in Tailwind or separate `.css` files.
- Do not introduce alternative architectures such as operation/context gems unless the request requires them.

## File Structure And Organization

- Follow Rails defaults.
- When extracting logic, namespace it under the owning model, feature, or component.
- Typical Tramway structure:

```text
app/
  components/
  controllers/
  decorators/
  forms/
  models/
  views/
config/
  initializers/tramway.rb
tailwind.config.js
```

## Entities And CRUD

- CRUD must be implemented through Tramway. This applies to `index`, `show`, `new`, `edit`, `create`, `update`, and `destroy`. If default Tramway CRUD is not applicable for a specific action, use the matching custom-flow recipe only after explicit user approval:
  - For `create` - create feature recipe
  - For `update` - update feature recipe
  - etc.
- When a task asks to add creation of a model/resource, a `new` page, a `create` action, or wording like "Event creation", load `agents/recipes/create-feature.md` before implementation.
- Configure CRUD through Tramway Entities in `config/initializers/tramway.rb`.
- Do not implement CRUD by hand with custom Rails controllers, routes, views, strong params, or plain Rails forms.
- Do not add a custom `create`, `update`, or `destroy` action for a resource when Tramway Entity pages can handle the operation.
- If a CRUD request appears to need custom behavior, first implement the standard CRUD surface with Tramway Entities, Tramway Forms, and Tramway Decorators, then add only the smallest custom extension needed around that surface.
- Do not decide on your own to bypass Tramway for CRUD. If Tramway cannot express a required CRUD behavior, stop before implementing that part, explain the limitation, and ask the user for explicit approval to bypass Tramway.
- A non-Tramway CRUD implementation is allowed only after explicit user approval for that specific bypass. When taking this approved exception, state in the final response why Tramway could not be used and which files intentionally bypass Tramway.
- If a namespace is requested, configure it in the entity definition.
- If an admin panel is requested, prefer the same entity configuration with `namespace: :admin`.
- If the app has web authentication, set `config.application_controller = 'ApplicationController'`.

Example:

```ruby
Tramway.configure do |config|
  config.application_controller = 'ApplicationController'
  config.entities = [
    {
      name: :participant,
      pages: [
        { action: :index },
        { action: :show },
        { action: :create },
        { action: :update },
        { action: :destroy }
      ]
    }
  ]
end
```

## Search

- Search is disabled by default on entity index pages.
- Enable it with `search: true` on the `:index` page.
- If `Model.search` exists, Tramway uses it.
- Otherwise Tramway falls back to `Model.tramway_search`. Treat that as a temporary fallback because it is generic and may not scale well.

Example:

```ruby
Tramway.configure do |config|
  config.entities = [
    {
      name: :participant,
      pages: [
        { action: :index, search: true }
      ]
    }
  ]
end
```

## Normalization And Validation

- Normalize input with Tramway `normalizes` for attributes like email or phone when the request calls for it.
- Do not add `normalizes` to the model unless that behavior is explicitly requested.
- Use Tramway Form validation for form-only rules.
- Keep data-integrity validation in the model unless form-only behavior is explicitly needed.

## Forms

- Create and update flows must use Tramway Forms. Do not build CRUD create/update flows without a `Tramway::BaseForm` subclass.
- Use Tramway Form pattern when `create` or `update` pages are configured for an entity.
- Visible fields are configured with `fields`.
- Each field should map to a Tramway form helper, or use a hash with `type:` plus helper options.
- Do not use strong parameters in controllers.
- Do not define `#{model_name}_params` methods.
- Use `tramway_form` to instantiate forms.
- Use `tramway_form_for` instead of `form_with` or `form_for`.
- Use `autocomplete: true` only when an autocomplete select is needed.
- Do not combine `autocomplete: true` with `multiselect: true` on the same field.
- Use `tramway_form_for(remote: true)` only for asynchronous partial-page updates such as modals or inline edits.
- Keep normal create and update flows synchronous.
- For enumerized attributes, use `collection: Model.attribute.values` in field definitions.
- For API work, use `api` namespaces for forms and decorators.

Available `tramway_form_for` helpers:

- `text_field`
- `email_field`
- `number_field`
- `text_area`
- `password_field`
- `file_field`
- `check_box`
- `select`
- `date_field`
- `datetime_field`
- `time_field`
- `tramway_select`
- `submit`

Example:

```ruby
class UserForm < Tramway::BaseForm
  properties :email, :about_me, :user_type, :score

  fields email: :email,
    name: :text,
    about_me: {
      type: :text_area,
      rows: 5
    },
    user_type: {
      type: :select,
      collection: ['regular', 'user']
    },
    score: {
      type: :number,
      value: ->(object) { Score.find_by(user_id: object.id).value }
    }

  def score=(value)
    Score.find_by(user_id: object.id).update(value:)
  end
end
```

## Decorators

- CRUD pages must use Tramway decorators for presented data.
- Always use decorated objects in views.
- Always instantiate decorators with `tramway_decorate`.
- In Tramway decorators, use `delegate_attributes` instead of `delegate ... to: :object`.
- If an entity has an index page, define `index_attributes` in its decorator.

Example:

```ruby
class ParticipantDecorator < Tramway::BaseDecorator
  def self.index_attributes
    %i[id name email created_at]
  end
end
```

## Components And Views

- Inherit components from `Tramway::BaseComponent`.
- Use `tramway_decorate` and `tramway_form`; do not instantiate decorator or form classes directly.
- Prefer ViewComponents for repeatable UI.
- Render components with the `component` helper, not with `render ComponentClass.new(...)`.

```haml
-# Correct
= component 'exercises/choose_exercise', word: @choose_word

-# Wrong
= render Exercises::ChooseExerciseComponent.new(word: @choose_word)
```
- Use `tramway_title` for the main page title.

Examples:

```ruby
tramway_title text: 'Title'
```

```haml
- tramway_title do
  More complicated title with HTML tags
```

## UI Primitives

- Use `tramway_navbar` for every navbar or primary navigation block unless the existing Tramway component API explicitly requires another Tramway Navbar invocation form. Do not use raw `<nav>` markup, do not use `<div>`/link groups styled as navbars, and do not build custom navbar components for standard navigation.
- Put basic authentication links such as Login and Logout in the navbar when applicable.
- Use Tramway Flash for notifications.
- Use Tramway Table for tabular data.
- Keep `preview: true` as the default for `tramway_row` unless preview is explicitly unwanted.
- Use `tramway_button` for every button unless the existing Tramway component API explicitly requires another Tramway Button invocation form. Do not use `button_to`, do not use `<a>`/link markup with button classes, and do not use raw `<button>` markup for buttons.
- Always set a button color via `color:` or `type:`.
- `color:` accepts direct colors like `red`, `yellow`, and `blue`.
- `type:` accepts lantern colors like `will`, `hope`, and `rage`.
- Use `tramway_tooltip` for every tooltip unless the existing Tramway component API explicitly requires another invocation form. Do not use raw `title=` attributes, do not use custom CSS tooltip markup, and do not build custom tooltip components for standard tooltips.
- Before using `tramway_tooltip`, fetch the Tramway README and search for `tramway_tooltip` to find the correct signature, required options, and examples. Do not rely on memory or prior knowledge.

Flash examples:

```haml
= tramway_flash text: flash[:notice], type: :hope
= tramway_flash text: 'Double check your data', type: :greed, class: 'mt-2', data: { turbo: 'false' }
```

## JS Setup For Tramway Components

- `tramway_select`, `tramway_tooltip`, checkbox fields, and `tramway_row preview: true` are backed by Stimulus controllers shipped in the `@tramway/tramway` JS package. Wire the package once per project instead of pinning/importing controllers one at a time as each helper is introduced.
- Add the importmap pin in `config/importmap.rb`:

  ```ruby
  pin "@tramway/tramway", to: "tramway/tramway.js"
  ```

- Import every controller the package provides together in `app/javascript/controllers/index.js`:

  ```js
  import { TramwaySelect, TableRowPreview, UiCheckbox, Tooltip } from "@tramway/tramway"
  ```

- Fetch the upstream Tramway README before finalizing the `application.register` identifiers for these controllers; do not guess controller names from memory.

## Chat UI

- Use `tramway_chat` for chat interfaces.
- Pass `chat_id`, `messages`, `message_form`, and `send_message_path`.
- Each message must include `:id` and `:type` with `:sent` or `:received`.
- Other keys such as `:text`, `:data`, and `:sent_at` are forwarded to the message component.
- Use `message_form: nil` for read-only chat rendering.
- Control availability with `send_messages_enabled:`.
- For live updates, use `tramway_chat_append_message`.
- Use `tramway_chat_prepend_message` to insert one message at the beginning of the stream.
- Use `tramway_chat_append_messages` to append multiple messages at once.
- Use `tramway_chat_prepend_messages` to prepend multiple messages at once.
- For single-message helpers, pass `chat_id:`, `type:`, `text:`, and `sent_at:`.
- `chat_id:` must match the value used in `tramway_chat`.
- `type:` must be `:sent` or `:received`.
- For multi-message helpers, pass `chat_id:` and `messages:`.
- `messages:` must be an array of hashes with `type:`, `text:`, and `sent_at:`.
- `message_form` must be a `Tramway::BaseForm` or subclass instance with a `text` attribute.
- `send_message_path` must point to a `POST` route.

Example:

```haml
= tramway_chat chat_id: @chat.id,
  messages: @chat.messages_for_chat,
  message_form: @message_form,
  send_message_path: chats_messages_path
```

```ruby
class ChatDecorator < Tramway::BaseDecorator
  def messages_for_chat
    object.messages.map do |message|
      {
        id: message.id,
        type: :sent,
        text: message.text,
        sent_at: message.created_at
      }
    end
  end
end
```

```ruby
class Chats::MessageForm < Tramway::BaseForm
  properties :text, :chat_id
end
```

Single-message live update examples:

```ruby
tramway_chat_append_message(
  chat_id: 'support-chat',
  type: :received,
  text: 'New incoming message',
  sent_at: Time.current
)
```

```ruby
tramway_chat_prepend_message(
  chat_id: 'support-chat',
  type: :received,
  text: 'Earlier message from history',
  sent_at: 5.minutes.ago
)
```

Multi-message live update examples:

```ruby
tramway_chat_append_messages(
  chat_id: 'support-chat',
  messages: [
    { type: :received, text: 'First update', sent_at: 2.minutes.ago },
    { type: :sent, text: 'Thanks, checking now', sent_at: 1.minute.ago }
  ]
)
```

```ruby
tramway_chat_prepend_messages(
  chat_id: 'support-chat',
  messages: [
    { type: :received, text: 'Older history item', sent_at: 10.minutes.ago },
    { type: :sent, text: 'Reply from earlier', sent_at: 9.minutes.ago }
  ]
)
```

## Controller Pattern

- Keep controller actions short and explicit.
- Use guard clauses where useful.
- Render components for complex UI instead of logic-heavy partials.
- Do not add business-logic private methods to controllers.
- Use Tramway Form pattern for parameter whitelisting.

## Services

- Use service objects for business logic that does not belong in controllers, models, or components.
- Create `app/services/base_service.rb` if it does not exist.
- Use `dry-monads` and pattern matching for service results.

Example:

```ruby
class BaseService
  extend Dry::Initializer[undefined: false]
  include Dry::Monads[:do, :result]

  def self.call(...)
    new(...).call
  end
end
```

Prefer:

```ruby
case SomeService.call(args)
in Success(result)
  result
in Failure(reason_or_error)
  reason_or_error
end
```

Instead of symbolic status handling.

## State Management On Existing Entities

- If a model already has Tramway entity `index` and `show` pages and the request is about explicit state management, do not add a new controller.
- Treat a request like "make a button on `<resource>#show` that calls `<event_or_method>` for the object" as state management when the method/event advances the record through a business state.
- For that shape, load `agents/recipes/state-change-recipe.md` before deciding whether to add routes or controller actions.
- Add a component for the state buttons.
- Render it via `show_header_content` for the show page and an actions column for the index page.

## Testing

- Create feature specs for Tramway Entity pages when the task requires tests.
- Put show specs in `spec/features/#{pluralized_model_name}/show_spec.rb`.
- Put index specs in `spec/features/#{pluralized_model_name}/index_spec.rb`.
- Put create specs in `spec/features/#{pluralized_model_name}/create_spec.rb`.
- Put update specs in `spec/features/#{pluralized_model_name}/update_spec.rb`.
- Put destroy specs in `spec/features/#{pluralized_model_name}/destroy_spec.rb`.
- Always use factories with FactoryBot for models and attribute hashes.
- If a factory is missing, create it in `spec/factories/#{pluralized_model_name}.rb`.
- If feature specs cover Tramway Entities pages, include `Tramway::Helpers::RoutesHelper` in `spec/rails_helper.rb`.

Example:

```ruby
RSpec.configure do |config|
  config.include Tramway::Helpers::RoutesHelper, type: :feature
end
```

## Enumerations And State

- Use `enumerize` for enumerated model attributes.
- Do not use `boolean` or `integer` columns for enumerations.
- Ensure `ApplicationRecord` extends `Enumerize`.
- Do not create scopes for enumerized values manually. Use `scope: :shallow`.
- If the requirement is really a process state machine, use `aasm` instead.

## Querying And Modeling

- Use model scopes for reusable object collections instead of private controller methods.

Example:

```ruby
class User < ApplicationRecord
  scope :this_month_registered_users, -> { where(created_at: Time.current.all_month) }
end
```
