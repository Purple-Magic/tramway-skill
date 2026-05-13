# Set Form Recipe

Load this file only when another recipe explicitly tells you to load it.

This is a shared recipe fragment, not a standalone feature recipe. Do not use it directly from `agents/recipes.md` unless a task specifically asks for this shared pattern by name.

- Add resource form that determines the form class to be set.
- Add `set_form` method to the resource controller that sets the form class based on the event.

## Standard Shape

Example for model `Participant`:

```ruby
# app/forms/participant_form.rb
class ParticipantForm < Tramway::BaseForm
  class << self
    # Replace these values with the parent recipe's supported events.
    def available_forms = %w[create calculate finish_calculation]

    def form_name(event)
      unless event.in?(available_forms)
        raise "Unknown form event: #{event}"
      end

      "Participants::#{event.camelize}Form".constantize
    end
  end
end
```

```ruby
# app/controllers/participants_controller.rb
class ParticipantsController < ApplicationController
  before_action :set_form

  private

  def set_form
    @form = ParticipantForm.form_name(params[:event])
  end
end
```
