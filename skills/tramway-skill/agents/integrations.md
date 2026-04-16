# Integrations Rules

Load this file when the task touches third-party services, background jobs, service objects, controller orchestration, or external API integrations.

## Third-Party Services

- Use an official gem for the service when one exists.
- Do not implement direct raw API calls when the official gem covers the need.
- Do not place integration logic directly in controllers or models.

## Service Objects

- Name service objects by business domain.
- Keep controllers as orchestration layers only.
- Prefer placing shared service behavior under `BaseService`.
- Use dry-monads for service return values.

Example:

```ruby
class NotifyAdmin < BaseService
  option :user

  def call
    # stuff
  end
end
```

Pattern match on results:

```ruby
case SomeService.call(args)
in Success(result)
  # use result
in Failure(reason_or_error)
  # handle failure
end
```

- Success and Failure branches should represent the real outcomes of the service.

## Async Execution

- Do not call third-party services synchronously from controllers.
- Put external work in background jobs.
- Let controllers enqueue work and handle user-facing flow only.
