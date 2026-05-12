# Create Feature Recipe

Load this file when the task asks to add a user-visible CRUD create flow for a resource.

## Approach 1: Default Tramway CRUD

- Implement create flows through Tramway Entity pages, Tramway Forms, and Tramway Decorators.
- Do not add a custom Rails controller `create` action, strong params method, plain Rails route, `form_with`, or `form_for` for standard CRUD create.
- Configure the entity create page in `config/initializers/tramway.rb`.
- Add a `Tramway::BaseForm` subclass under `app/forms/`.
- Add or update a decorator under `app/decorators/`.
- Add a feature spec for the create page.

## Standard Shape

Example for adding create support to `Participant`:

```ruby
# config/initializers/tramway.rb
Tramway.configure do |config|
  config.entities = [
    {
      name: :participant,
      pages: [
        { action: :index },
        { action: :show },
        { action: :create }
      ]
    }
  ]
end
```

```ruby
# app/forms/participant_form.rb
class ParticipantForm < Tramway::BaseForm
  properties :name, :email

  fields name: :text,
    email: :email
end
```

```ruby
# app/decorators/participant_decorator.rb
class ParticipantDecorator < Tramway::BaseDecorator
  def self.index_attributes
    %i[name email created_at]
  end
end
```

## Checklist

1. Add or update the model and migration only if the resource does not already exist.
2. Configure `{ action: :create }` on the Tramway entity.
3. Define the form with `properties` and `fields`.
4. Use Tramway form helpers only.
5. Use decorated objects for presented data.
6. Add `spec/features/#{pluralized_model_name}/create_spec.rb`.
7. Verify with local development commands from the main skill.

## Approach 2: Custom Create Flow

Use this approach only when the default Tramway CRUD implementation is not applicable.
Use it only after explaining why default Tramway CRUD is not applicable and receiving explicit user approval.

Example for adding create support to `Participant`:

```ruby
# app/controllers/participants_controller.rb
class ParticipantsController < ApplicationController
  before_action :set_form

  def new
    @participant = @form.new(Participant.new)
  end

  def create
    @participant = @form.new(Participant.new)

    if @participant.submit params[:participant]
      redirect_to @participant, notice: 'Participant was successfully created.'
    else
      render :new
    end 
  end

  private

  def set_form
    @form = ParticipantForm.form_name(params[:event])
  end
end
```

```ruby
# app/forms/participant_form.rb
class ParticipantForm < Tramway::BaseForm
  class << self
    def available_forms = [
      "create"
    ]

    def form_name(event)
      unless event.in?(available_forms)
        raise "Unknown event for new action: #{event}"
      end

      "Participants::#{event.camelize}Form".constantize
    end
  end
end
```

```ruby
# app/forms/participants/create_form.rb
class Participants::CreateForm < Tramway::BaseForm
  properties :name, :email

  fields name: :text,
    email: :email
end
```

```ruby
# app/decorators/participant_decorator.rb
class ParticipantDecorator < Tramway::BaseDecorator
  def self.index_attributes
    %i[name email created_at]
  end
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :participants, only: %i[new create]
end
```

```ruby
# app/components/action_form_component.rb
class ActionFormComponent < Tramway::BaseComponent
  option :object
  option :event
  option :create_path
  option :update_path
  option :back_path

  def action
    data[:action]
  end

  def method
    data[:method]
  end

  private

  def data
    if object.new_record?
      {
        action: create_path.call(event:),
        method: :post
      }
    else
      {
        action: update_path.call(object, event:),
        method: :patch
      }
    end
  end
end
```

```haml
# app/components/action_form_component.html.haml
= tramway_form_for object, local: true, url: action, method:, size: :large do |f|
  - if object.errors.any?
    .alert.alert-danger
      %h4= "#{pluralize(object.errors.count, 'error')} prohibited this object from being saved:"
      %ul
        - object.errors.full_messages.each do |message|
          %li= message

  - object.class.fields.each do |(attribute, field_type)|
    = f.tramway_field field_type, attribute

  .form-actions
    = f.submit object.submit_button_text
    = tramway_button text: "Cancel", path: back_path, type: :inverse, link: true, size: :large
```

```haml
# app/views/participants/new.html.haml
= tramway_container do
  = tramway_title class: 'mb-8' do
    New Participant

  = render 'form'
```

```haml
# app/views/participants/_form.html.haml
= component 'action_form',
  object: @participant,
  event: params[:event],
  create_path: lambda { |event:| participants_path(event:) },
  update_path: lambda { |object, event:| participant_path(object, event: params[:event].presence || :update) },
  back_path: participants_path
```

## Checklist

1. Add or update the model and migration only if the resource does not already exist.
2. Define the form with `properties` and `fields`.
3. Use Tramway form helpers only.
4. Use decorated objects for presented data.
5. Add `spec/features/#{pluralized_model_name}/create_spec.rb`.
6. Verify with local development commands from the main skill.
