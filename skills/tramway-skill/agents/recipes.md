# Recipes Index

Load this file when the task asks how a feature should usually be implemented in this project.

Do not open every recipe by default. Open only the recipe that matches the requested feature.

## Available Recipes

- For creating a new Rails project, open [agents/recipes/create-rails-project.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/create-rails-project.md).
- For implementing or updating deployment, open [agents/recipes/deployment-recipe.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/deployment-recipe.md).
- For saving `config/master.key`, Rails credentials keys, staging/production secrets, or deployment secrets in 1Password or another secure store, open [agents/recipes/save-rails-secrets-1password.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/save-rails-secrets-1password.md).
- For standard CRUD create flows, open [agents/recipes/create-feature.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/create-feature.md).
- For copy or duplicate flows, open [agents/recipes/copy-feature.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/copy-feature.md).
- For adding, fixing, rendering, or standardizing flash messages and notifications, open [agents/recipes/add-flash-messages.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/add-flash-messages.md).
- For lazy loading older messages in `tramway_chat`, open [agents/recipes/tramway-chat-lazy-loading.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/tramway-chat-lazy-loading.md).
- For record state changes triggered by a button, including requests like "make a button on `<resource>#show` that calls `<event_or_method>` for the object" when that method/event advances business state, open [agents/recipes/state-change-recipe.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/state-change-recipe.md).
- For adding pagination to any list of records, open [agents/recipes/pagination.md](/home/pavel/projects/tramway-skill/skills/tramway-skill/agents/recipes/pagination.md).

## How To Use Recipes

- Treat recipes as preferred implementation approaches, not as always-on global rules.
- Start with the smallest recipe that matches the task.
- If the task spans multiple patterns, load only the relevant combination.
- If no recipe exists yet, add a new focused file in `agents/recipes/` and link it here.
