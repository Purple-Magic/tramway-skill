# Create Rails Project Recipe

Use this recipe when the user asks to create a Rails project or a new Rails app.

Load `agents/recipes/save-rails-secrets-1password.md` after Rails generates `config/master.key`, before continuing past secret handling. If the user selected server/deploy setup, also load `agents/recipes/deployment-recipe.md`.

## Questioning Style

1. Ask setup questions one-by-one in separate messages.
2. Do not ask whether to use the reference project; notify that it will be used by default.
3. Ask only project-level decisions, not which files to copy.
4. Build the full planned import list internally.
5. Prepare one consolidated bootstrap-import plan at decision level and ask once for approval or changes.
6. User-facing questions must be plain text in the user's language.
7. When asking a question, wait for the answer before unrelated actions.
8. User may skip any setup step or integration; record the risk and continue.

## Required Setup Questions

1. Ask for project name before running commands.
2. Tell the user: "Choose a simple name. Try to avoid `-` character besides you want explicitly. Renaming a Rails project later is possible but usually difficult and time-consuming."
3. Ask which git service they use.
4. Ask where the repository should be stored. GitHub is recommended; GitLab and similar services are supported.
5. Ask for remote URL or organization name.
6. Ask which team chat to connect. Supported chat: `Discord`.
7. When asking about team chat, explain briefly that shared CI/deploy/failure visibility helps the team react faster and stay aligned.
8. Ask whether they want server creation and deploy configuration.
9. If yes, hand off to `deployment-recipe.md` for deployment questions and implementation.

Defaults:

1. Create a standard Rails app, not API-only, unless user explicitly asks otherwise.
2. Make repositories private by default unless user asks for public.
3. Do not collect deploy/provider secrets during pre-project questions. Collect them only after the Rails project and `terraform/` directory exist.
4. Do not create or edit user home dotfiles.

## Repository Handling

1. After the user provides repository URL or name, check whether it exists.
2. For GitHub, always run `scripts/check_github_repo_exists.sh <owner/repo>`.
3. If missing, ask whether the user wants to create it.
4. Before creating a GitHub repository:
   - Run `command -v gh`.
   - Run `gh auth status`.
   - If auth fails, run `env -u GH_TOKEN -u GITHUB_TOKEN gh auth status`.
5. If `gh` is missing, tell the user to pause, install GitHub CLI, and authenticate in another terminal.
6. If auth fails in this session but works for the user locally, continue and attempt repo creation.
7. If repo creation fails due to auth, tell the user to authenticate `gh` in another terminal and resume.
8. Create private GitHub repositories with `gh repo create ... --private` unless public was requested.

## Baseline Creation

After the user confirms `<project_name>`:

```bash
if ! command -v rails >/dev/null 2>&1; then gem install rails; fi
rails new <project_name> -d postgresql
cd <project_name>
if ! command -v dip >/dev/null 2>&1; then gem install dip; fi
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/dip.yml -o dip.yml
mkdir -p .dockerdev
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/.bashrc -o .dockerdev/.bashrc
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/.psqlrc -o .dockerdev/.psqlrc
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/Aptfile -o .dockerdev/Aptfile
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/Dockerfile -o .dockerdev/Dockerfile
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/README.md -o .dockerdev/README.md
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/.dockerdev/compose.yml -o .dockerdev/compose.yml
mkdir -p config
curl -fsSL https://raw.githubusercontent.com/purple-magic/base_project/main/config/database.yml -o config/database.yml
dip provision
```

## Mandatory Key Storage

After Rails creates `config/master.key`, stop and warn:

`config/master.key` is mandatory to decrypt Rails credentials. It is ignored by git and will not be saved in the repository. If it is lost, production/staging credentials may become unrecoverable. Save it in a secure place now before continuing.

Then run `save-rails-secrets-1password.md`:

1. Ask how the user wants to store `config/master.key`.
2. Recommend `1Password`.
3. If the user chooses `1Password`, guide them through creating `<project_name> Rails secrets` and adding `config/master.key`.
4. Mention `Bitwarden` and other encrypted secret managers as acceptable alternatives.
5. Offer unencrypted `.env*` only as unsafe fallback and warn clearly if selected.
6. Wait for `done` before continuing.

## Reference Baseline Alignment

1. Compare generated files against the reference project.
2. Apply applicable config differences for CI, lint, security, deployment defaults, HAML, Tailwind, and local development.
3. For GitHub, copy/adapt `.github/workflows/` from the reference project.
4. For non-GitHub, create equivalent CI scenarios.
5. Prepare one consolidated bootstrap-import plan and ask once for approval or changes.
6. Build a temporary bootstrap script with required file downloads/adaptations/commands.
7. Run it and delete it immediately.
8. If chat is `Discord`, copy/adapt Discord CI/deploy/team-update notification configuration.
9. Ask the user to set `DISCORD_WEBHOOK_URL` in repository secrets only after the repository exists.
10. If chat is not `Discord`, ask whether they want generated team chat integration and warn it is untested.
11. Apply `.gitignore` from the reference project, adapting only when needed.
12. Clearly warn that `config/master.key` and `config/credentials/*.key` are ignored by git and must be securely stored.
13. Create or update project-root `AGENTS.md` and `CLAUDE.md` so future Codex and Claude Code sessions use `tramway-skill` by default for the created project.
14. Take HAML setup from the reference project.
15. After the tramway gem is added from the reference project, immediately run the install generator. This step is mandatory and must happen before any further setup continues:

    ```bash
    dip rails g tramway:install
    ```

16. Ensure Tailwind uses `tailwindcss-rails`.
17. Enable PostgreSQL `uuid-ossp` via migration, following the reference project approach.
18. Tell the user UUID public IDs avoid exposing sequential record counts and reduce easy record enumeration.
19. Ensure view layer is HAML-only.
20. Import full `.dockerdev/` content from the reference project and keep it project-local.
21. Do not modify `.dockerdev/compose.yml` `x-*` extension blocks unless explicitly asked.
22. Use `dip` for local development. Never use `dip` in production, staging, or CI.
23. If `dip` commands fail because ports or container names are occupied, pause and ask the user to free resources or approve project-local changes.

## Project Agent Files

During creation, create or update both project-root files:

- `AGENTS.md`
- `CLAUDE.md`

These files must make `tramway-skill` the default project workflow for future agent sessions.

Required `AGENTS.md` behavior:

1. State that the project is a Rails app managed with `tramway-skill`.
2. Instruct Codex to use `tramway-skill` by default for Rails setup, feature work, bugfixes, updates/upgrades, deployment, database dump/restore, and maintenance.
3. Tell Codex to follow this project's local instructions first, then load the focused `tramway-skill` guidance files required by the task.
4. Include a short reminder not to bypass Tramway CRUD/forms/components unless the skill allows it and the user approves the exception.

Required `CLAUDE.md` behavior:

1. State that Claude Code must use `tramway-skill` by default for the same project workflows.
2. Include explicit Claude Code file-loading guidance:
   - Read `~/.claude/skills/tramway-skill/SKILL.md` before Rails project work.
   - When that skill says to load `agents/X.md` or `agents/recipes/X.md`, use the Read tool with `~/.claude/skills/tramway-skill/agents/X.md` or `~/.claude/skills/tramway-skill/agents/recipes/X.md`.
   - If the home skill path is unavailable, fall back to repository-local `skills/tramway-skill/...` only when that path exists.
3. If `AGENTS.md` already contains project-specific rules, preserve them and add the `tramway-skill` default instruction rather than replacing the file wholesale.
4. If `CLAUDE.md` already contains project-specific rules, preserve them and add the Claude Code `tramway-skill` loading instructions rather than replacing the file wholesale.

## Completion

1. Verify app boot and tests through `dip`.
2. Use CI-native commands for CI validation.
3. Commit and push created code unless the user skips push.
4. Tell the user how to run the server:
   - `dip rails s`: interactive Rails container terminal, Rails logs only.
   - `dip up web`: all container logs, no same-terminal interaction with the running Rails container.
