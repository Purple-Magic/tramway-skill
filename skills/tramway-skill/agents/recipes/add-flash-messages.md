# Add Flash Messages Recipe

Load this file when the task asks to add, fix, render, or standardize user-visible flash messages or notifications.

## Core Rule

- Use `tramway_flash` for every rendered flash message or notification. This is the canonical Tramway UI helper for flashes.
- Do not render flash messages with raw `.alert` markup, Bootstrap-style alert classes, custom toast markup, or plain Rails tag helpers when `tramway_flash` is available.
- Controller redirects may still set Rails flash values with `notice:`, `alert:`, or `flash[...]`; this recipe governs how those messages are displayed in views and layouts.

## Standard Shape

Render Rails flash messages through `tramway_flash` in the shared layout or the view that owns the notification surface:

```haml
- flash.each do |type, message|
  - flash_type = { notice: :hope, alert: :greed, error: :rage }.fetch(type.to_sym, type)
  = tramway_flash text: message, type: flash_type
```

Map Rails flash keys to Tramway visual intent explicitly. Do not replace `tramway_flash` with raw markup just to support `notice`, `alert`, or `error`.

Direct notification examples:

```haml
= tramway_flash text: flash[:notice], type: :hope
= tramway_flash text: 'Double check your data', type: :greed, class: 'mt-2', data: { turbo: 'false' }
```

## Checklist

1. Load `agents/ui.md` before editing flash markup.
2. Keep Rails flash assignment in controllers conventional unless the task requires different behavior.
3. Render every visible notification with `tramway_flash`.
4. Remove duplicate raw flash/alert markup from the same notification surface.
5. Add or update a focused feature/request spec only when behavior changes, not for a pure markup swap.
