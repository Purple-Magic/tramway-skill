# Testing Rules

Load this file when the task adds or updates specs, factories, feature tests, or any Tramway entity page test coverage.

## RSpec Conventions

- Do not use `require 'rails_helper'` in spec files.
- Do not write `RSpec.describe`; use `describe`.
- Always use FactoryBot factories for model setup and attribute hashes.
- If a factory is missing, add it to `spec/factories/`.

## Feature Specs

- Put show page feature specs in `spec/features/#{pluralized_model_name}/show_spec.rb`.
- Put index page feature specs in `spec/features/#{pluralized_model_name}/index_spec.rb`.
- Put create page feature specs in `spec/features/#{pluralized_model_name}/create_spec.rb`.
- Put update page feature specs in `spec/features/#{pluralized_model_name}/update_spec.rb`.
- Put destroy page feature specs in `spec/features/#{pluralized_model_name}/destroy_spec.rb`.

## Tramway Entity Specs

- If you create feature specs for Tramway Entity pages, ensure `spec/rails_helper.rb` includes:

```ruby
RSpec.configure do |config|
  config.include Tramway::Helpers::RoutesHelper, type: :feature
end
```

## Coverage Guidance

- Add the smallest set of specs that proves the requested behavior.
- Prefer feature specs for user-visible page flows.
- Keep assertions focused on visible behavior and persisted outcomes.

## Verifying Features

- If the project has RSpec configured with Capybara, verify every feature you build or change by running its RSpec/Capybara feature specs (via `dip rspec`, per the Testing policy in `SKILL.md`).
- Do not use Playwright or any other browser-automation/testing alternative to verify features unless the user explicitly asks for it.

## Turbo/Hotwire/Stimulus Features

- When writing feature specs for pages or interactions that use Turbo, Hotwire, or Stimulus (Turbo Drive navigation, Turbo Frames, Turbo Streams, Stimulus controllers), always assert that the page does not render `Content missing` in any case where a broken Turbo Frame target could cause it (e.g. after a Turbo Frame navigation, form submission, or Turbo Stream update).
- Add an assertion such as `expect(page).not_to have_content('Content missing')` after each interaction that triggers a Turbo Frame or Turbo Stream response.
