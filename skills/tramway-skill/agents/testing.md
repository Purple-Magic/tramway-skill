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
