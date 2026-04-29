# Copy Feature Recipe

Load this file when the task is about duplicating an existing record or creating a "Copy" action for a user-visible resource.

## Goal

- Let the user create a new record from an existing one without mutating the source record.

## Preferred Approach

- Keep the original record unchanged.
- Create a new record with copied attributes.
- Exclude attributes that must stay unique or system-owned, such as `uuid`, timestamps, state-machine fields, or external sync identifiers.
- If the user must review the copy before saving, prefill a Tramway form with copied values.
- If the copy should happen immediately, perform it through a service object and redirect to the new record or edit screen.

## Where Logic Should Live

- Put copy business logic in a form object.
- Keep the controller thin.


## Data Rules

- Generate a fresh `uuid` for the new record through normal persistence flow.
- Do not copy identifiers or fields that would break uniqueness constraints.
- Be explicit about associations:
  - copy simple scalar attributes by default
  - copy associations only when the product requirement clearly needs that behavior
  - if nested records are copied, define which child records are duplicated and which are only referenced

## UI Guidance

- Name the action clearly, for example `Copy`, `Duplicate`, or `Create copy`.
- Show the user what happens next:
  - copy and open edit page
  - copy immediately and open show page
- Use Tramway buttons and existing page actions/components.

## Suggested Flow

Example flow for copying a `Project` record:
1. User clicks `Copy` on index or show page. It calls `create` action with `params[:event] = 'copy'`. This action must be like this:

```ruby
def create
  @project = @form.new current_user.projects.build

  if @project.submit params[:project]
    @project.respond_with(self)
  else
    render :new, status: :unprocessable_entity
  end
end

private

def set_form
  @form = ProjectForm.form_name(params[:event].presence || "#{@project.project_type.pluralize}/edit")
end
```

2. Controller calls a form object with the source record and a class `Projects::Events::CopyForm`. This class should be like this:

```ruby
class Projects::Events::CopyForm < Tramway::BaseForm
  properties :parent_id # this is the id of the record being copied, used for service lookup but not persisted on the new record

  fields # the same collection of fields as the default create unless explicitly adjusted for uniqueness or domain rules

  def submit(params)
    parent_project = Project.find_by(id: parent_id)

    return false unless parent_project

    properties_to_copy.each do |attr|
      object.public_send("#{attr}=", parent_project.public_send(attr))
    end

    super
  end
  
  def respond_with(controller)
    controller.redirect_to controller.edit_project_path(object)
  end

  private

  def properties_to_copy
    # define which attributes to copy from the parent record, excluding unique identifiers and system fields
    %i[name description other_attributes]
  end
end
```
