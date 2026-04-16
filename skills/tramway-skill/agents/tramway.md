# Tramway Rules

Load this file when the task touches Tramway entities, forms, decorators, components, controller patterns around Tramway, or default CRUD behavior.

## Core Principle

- Prefer Tramway defaults and generators over hand-rolled Rails setup.
- Use domain language instead of generic names.
- Keep logic in the correct layer: models for data, controllers for HTTP, components for reusable UI, views for straightforward rendering.

## Entities And CRUD

- If CRUD or default actions like `index`, `show`, `create`, `update`, `destroy` are requested, use Tramway Entities by default unless custom behavior is required.
- Configure entities in `config/initializers/tramway.rb`.
- Do not manually create controllers, views, and routes for CRUD if Tramway Entities can handle the feature.
- If a namespace is requested, configure it in the entity definition.
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
- Otherwise Tramway falls back to `Model.tramway_search`, which should be treated as a temporary fallback.

## Forms

- Use Tramway Form pattern when `create` or `update` pages are configured for an entity.
- Use Tramway Form validation for form-only rules.
- Keep data-integrity validation in the model unless form-only behavior is explicitly needed.
- Do not use strong parameters in controllers.
- Do not define `#{model_name}_params` methods.
- Use `tramway_form` to instantiate forms.
- Use `tramway_form_for` instead of `form_with` or `form_for`.
- Use `tramway_form_for(remote: true)` only for truly asynchronous partial-page updates.
- Keep normal create/update flows synchronous.
- For enumerized attributes, use `collection: Model.attribute.values` in field definitions.
- For API work, use `api` namespaces for forms and decorators.

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

## Components And Views

- Inherit components from `Tramway::BaseComponent`.
- Use `tramway_decorate` and `tramway_form`; do not instantiate decorator/form classes directly.

## Chat UI

- Use `tramway_chat` for chat interfaces.
- Pass `chat_id`, `messages`, `message_form`, and `send_message_path`.
- Each message must include `:id` and `:type` with `:sent` or `:received`.
- Use `message_form: nil` for read-only chat rendering.
- Control availability with `send_messages_enabled:`.
- For live updates, use `tramway_chat_append_message`.

## Controller Pattern

- Keep controller actions short and explicit.
- Use guard clauses where useful.
- Render components for complex UI instead of logic-heavy partials.
- Do not add business logic private methods to controllers.

## State Management On Existing Entities

- If a model already has Tramway entity `index` and `show` pages and the request is about explicit state management, do not add a new controller.
- Add a component for the state buttons.
- Render it via `show_header_content` for the show page and an actions column for the index page.
