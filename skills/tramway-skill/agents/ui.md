# UI Rules

Load this file when the task touches pages, views, components, Tailwind, Haml markup, buttons, tables, flashes, titles, or layout containers.

## Stack And Templates

- Prefer Haml for views unless a component template already uses ERB.
- Keep JavaScript minimal. Use Stimulus if needed and avoid SPA patterns unless explicitly requested.
- Reusable UI should be implemented as ViewComponents.
- Components should inherit from `Tramway::BaseComponent`.

## Tramway UI Helpers

- Use Tramway Navbar for navigation. Include at least Login and Logout links when relevant.
- Use Tramway Flash for notifications.
- Use Tramway Table for tabular data.
- Use `tramway_row href:` for row links instead of placing a link inside a table cell.
- Keep `preview: true` on rows unless the request explicitly needs it disabled.
- Use Tramway Button for buttons and always specify `color:` or `type:`.
- Use `tramway_title` for the main page title.
- Use `tramway_container` for page containers.
- Use `tramway_main_container` in layouts instead of custom wrapper divs when a standard container is needed.

Flash example:

```haml
= tramway_flash text: flash[:notice], type: :hope
= tramway_flash text: 'Double check your data', type: :greed, class: 'mt-2', data: { turbo: 'false' }
```

## Forms In Views

- Use `tramway_form_for`.
- Supported helpers include `text_field`, `email_field`, `number_field`, `text_area`, `password_field`, `file_field`, `check_box`, `select`, `date_field`, `datetime_field`, `time_field`, `tramway_select`, and `submit`.
- Use `autocomplete: true` when autocomplete behavior is needed.
- Do not combine `autocomplete: true` and `multiselect: true` on the same select.
- `tramway_form_for` supports `horizontal: true`.

## Tailwind And Haml

- Keep `config/tailwind.config.js` managed by the generator.
- If dynamic classes are introduced, update the safelist instead of rewriting the config structure.
- Add imports to `app/assets/tailwind/application.css`.
- Avoid inline `<style>` blocks.
- For Tailwind classes with arbitrary values in Haml, pass them through hash syntax.

Example:

```haml
= content_tag :div, 'Example', { class: 'w-[42rem] bg-slate-100/80' }
```
