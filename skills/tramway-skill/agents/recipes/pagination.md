# Pagination Recipe

Load this file every time the task asks to add pagination to any list of records.

## Rules

- Always use Tramway's built-in Tailwind-styled Kaminari pagination. Never add a custom pagination helper, custom CSS, or a third-party pagination gem.
- Paginate the ActiveRecord scope in the controller using Kaminari's `.page` / `.per` methods.
- Render pagination in the view with `<%= paginate @collection %>`. This outputs dark shadcn-style pagination buttons automatically — do not wrap it in extra markup or pass extra CSS classes.
- Tramway pagination does not have a light theme. Do not attempt to override its styles.

## Standard Shape

```ruby
# app/controllers/users_controller.rb
def index
  @users = User.page(params[:page]).per(25)
end
```

```erb
<%# app/views/users/index.html.erb %>
<%= paginate @users %>
```

## Checklist

1. Scope the collection with `.page(params[:page])` (and `.per(n)` if a non-default page size is needed).
2. Pass the paginated collection to the view via an instance variable.
3. Add `<%= paginate @collection %>` at the bottom of the list in the view.
4. Do not add any custom pagination CSS or helper.
5. Verify the pagination links appear and navigate correctly in the browser.
