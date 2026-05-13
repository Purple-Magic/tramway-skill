# Change State Recipe

Load this file when the task asks to add a user-visible state change flow for a resource via button clicks or other UI interactions.

- If the state machine inside the model is not implemented, use `aasm` to implement it.
- Do not create specific controllers, routes or actions for state changes. Instead, use or create `update` action.
- Add Tramway Form that only includes the state field and any other fields that are relevant to the state change.
- When implementing this approach, also load [Set Form Recipe](./set-form.md).

## Standard Shape

Example for adding a state change flow to `Order`:

```ruby
# app/models/order.rb
class Order < ApplicationRecord
  aasm do
    state :pending, initial: true
    state :calculating
    state :calculated

    event :calculate do
      transitions from: :pending, to: :calculating
    end

    event :finish_calculation do
      transitions from: :calculating, to: :calculated
    end
  end
end
```

```ruby
# app/forms/orders/calculate_form.rb
class Orders::CalculateForm < Tramway::BaseForm
  def submit(params)
    object.calculate!
  end

  def respond_with(controller)
    controller.redirect_to object, notice: 'Order is being calculated.'
  end
end
```

The controller example assumes Set Form Recipe has added `before_action :set_form`.

```ruby
# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  def update
    order = Order.find params[:id]
    @order = @form.new order

    if @order.submit params[:order]
      @order.respond_with(self)
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
```

```haml
-# app/views/orders/show.html.haml
= tramway_button text: 'Calculate', path: order_path(@order, event: :calculate), method: :patch, type: :warning
```
