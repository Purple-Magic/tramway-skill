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
- generators such as `bin/rails g tramway:install`
- ViewComponents for reusable UI
- Tailwind safelist utilities for dynamic classes

## Quick Start Workflow

Prefer installing Tramway defaults before hand-rolling setup:

```bash
bin/rails g tramway:install
```

The install generator appends missing gems, copies Tailwind safelist config, ensures `app/assets/tailwind/application.css` imports Tailwind, and writes an `AGENTS.md` guide in the project root.

## Technology Stack And Gems

- Expect Rails 7+ with `kaminari`, `view_component`, `haml-rails`, `dry-initializer`, and `tailwindcss-rails`.
- Prefer Haml for views unless the existing component or file uses ERB.
- Keep JavaScript minimal. Use Stimulus if needed and avoid SPA patterns unless explicitly requested.
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

- If CRUD or default actions like `index`, `show`, `create`, `update`, or `destroy` are requested, use Tramway Entities by default unless custom behavior is required.
- Configure entities in `config/initializers/tramway.rb`.
- Do not manually create controllers, views, and routes for CRUD if Tramway Entities can handle the feature.
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

- Use Tramway Navbar for navigation.
- Put basic authentication links such as Login and Logout in the navbar when applicable.
- Use Tramway Flash for notifications.
- Use Tramway Table for tabular data.
- Keep `preview: true` as the default for `tramway_row` unless preview is explicitly unwanted.
- Use Tramway Button for buttons.
- Always set a button color via `color:` or `type:`.
- `color:` accepts direct colors like `red`, `yellow`, and `blue`.
- `type:` accepts lantern colors like `will`, `hope`, and `rage`.

Flash examples:

```haml
= tramway_flash text: flash[:notice], type: :hope
= tramway_flash text: 'Double check your data', type: :greed, class: 'mt-2', data: { turbo: 'false' }
```

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
