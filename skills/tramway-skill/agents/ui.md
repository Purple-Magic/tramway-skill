# UI Rules

Load this file when the task touches pages, views, components, Tailwind, Haml markup, buttons, tables, flashes, titles, or layout containers.

## Stack And Templates

- Prefer Haml for views unless a component template already uses ERB.
- Keep JavaScript minimal. Use Stimulus if needed and avoid SPA patterns unless explicitly requested.
- If `config/importmap.rb` exists, use importmap for JavaScript. Do **not** introduce `package.json`, `node_modules`, or any npm/yarn/bun toolchain.
- Reusable UI should be implemented as ViewComponents.
- Components should inherit from `Tramway::BaseComponent`.
- Render components with the `component` helper, not with `render ComponentClass.new(...)`.

```haml
-# Correct
= component 'exercises/choose_exercise', word: @choose_word

-# Wrong
= render Exercises::ChooseExerciseComponent.new(word: @choose_word)
```

## Tramway UI Helpers

- Use `tramway_navbar` for every navbar or primary navigation block unless the existing Tramway component API explicitly requires another Tramway Navbar invocation form. Do not use raw `<nav>` markup, do not use `<div>`/link groups styled as navbars, and do not build custom navbar components for standard navigation. Include at least Login and Logout links when relevant.
- Use Tramway Flash for notifications.
- Use `tramway_table` for tabular data whenever a table is needed.
- Use `tramway_row href:` for row links instead of placing a link inside a table cell.
- Keep `preview: true` on rows unless the request explicitly needs it disabled.
- Use `tramway_button` for every button unless the existing Tramway component API explicitly requires another Tramway Button invocation form. Do not use `button_to`, do not use `<a>`/link markup with button classes, and do not use raw `<button>` markup for buttons. Always specify `color:` or `type:`.
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

### MANDATORY: Dot Notation For Classes

**ALWAYS use Haml dot notation (`.class1.class2.class3`) for elements with only plain CSS/Tailwind classes. NEVER use `%div{ class: 'class1 class2 class3' }` hash syntax when all classes are plain (no square brackets).**

Correct:

```haml
.flex.items-center.gap-4
  %span.text-sm.font-medium Hello
```

Wrong — NEVER use hash syntax for plain classes:

```haml
-# BAD
%div{ class: 'flex items-center gap-4' }
  %span{ class: 'text-sm font-medium' } Hello
```

### MANDATORY: Arbitrary Values In Haml

**ALWAYS use `content_tag` with a hash when any Tailwind class contains square brackets (arbitrary values like `w-[42rem]`, `top-[10px]`, `bg-[#fff]`, etc.).**

Square brackets are Haml attribute syntax. Writing them inline will produce broken markup or a parse error. This rule has NO exceptions.

Correct:

```haml
= content_tag :div, 'Example', { class: 'w-[42rem] bg-slate-100/80' }
= content_tag :span, text, { class: 'top-[10px] left-[4px] text-[#333]' }
```

Wrong — NEVER write arbitrary Tailwind values inline in Haml:

```haml
-# BROKEN — square brackets break Haml parsing
.w-[42rem].bg-slate-100 Example
%span.top-[10px] #{text}
```

When an element has a mix of plain classes and arbitrary-value classes, use `content_tag` for the whole element:

```haml
-# All classes go into content_tag when any one of them has square brackets
= content_tag :div, 'Example', { class: 'flex items-center w-[42rem] bg-slate-100' }
```

Apply both rules to every tag you write, including ViewComponent templates.
