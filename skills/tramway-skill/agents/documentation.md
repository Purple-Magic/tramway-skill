# Documentation Rules

Load this file when the task changes a user-facing feature or introduces a new user-visible workflow.

## User Documentation

- Document user-facing functionality in `docs/users/`.
- Write docs only for features users can see and use.
- Do not document internal code structure, codebase implementation details, or admin-only engineering details in these files unless the user explicitly asks for that audience.
- Write these docs in English.
- Treat these files as onboarding material for end users, not engineers.
- Describe functionality, user flows, expectations, and visible outcomes.
- Avoid deep technical implementation details.

## Update Policy

- When a user-facing feature changes, update the corresponding file in `docs/users/`.
- When a new user-facing feature is added, create a matching file under `docs/users/`.

Example:

- Orders feature: `docs/users/orders.md`
- Authentication flow: `docs/users/authentication.md`
