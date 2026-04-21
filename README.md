# Tramway Skill

`tramway-skill` is an AI skill for working with Ruby on Rails projects end to end.

## Installation

Install it through Codex's standard `skill-installer` flow from this GitHub path:

`https://github.com/purple-magic/tramway-skill/tree/main/skills/tramway-skill`

The skill now lives under `skills/tramway-skill/`, so Codex can install it as a normal GitHub-hosted skill instead of reading it from an arbitrary local path.

If you want to install it through the Codex CLI itself, start Codex and ask it to use the `skill-installer` skill with this GitHub path:

```bash
codex "Use the skill-installer skill to install https://github.com/purple-magic/tramway-skill/tree/main/skills/tramway-skill"
```

You can also paste the same instruction into an existing interactive Codex session.

If you are using the low-level installer script directly, the matching repo path is:

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo purple-magic/tramway-skill \
  --path skills/tramway-skill
```

After installation, restart Codex.

It is built around a simple idea: Rails is still one of the best stacks for shipping useful products, especially now that experienced engineers can use AI to remove routine friction and newcomers can build much more ambitious things with far less pain.

This skill is meant to support both groups:

- Beginners who want a practical "YOLO mode" and need the AI to keep momentum while still following solid Rails conventions.
- Experienced engineers who run many different projects and want to stay focused on product and architecture instead of repeating setup, maintenance, and release chores.

## Base Features

- Creating a new Rails project with configured:
  - Docker for development (via dip)
  - Deployment (via Kamal)
  - Production and staging server management (via Terraform)
  - Production and staging server management (via Terraform)
  - Authentication (via Rails authorization or Auth0)
  - Project structure (via Tramway)
  - Background jobs (via SolidQueue)
  - TurboRails (via SolidCable)
  - Configured css framework (via Tailwind)
- Updating an existing Rails project with all the mentioned and also:
  - New Rails features and approaches (if applicable)
  - Bug fixes (if they exist)
- Secrets management
  - 1Password integration instructions for Terraform
  - Rails credentials instructions
- Authorization
  - Auth0 integration recipe    
- Documentation instructions
- Integrations instructions
- Testing instructions
- Tramway instructions
- UI instructions
- Recipes
  - Copy Feature
  - Lazy Loading for Tramway Chat
    

## What It Does

`tramway-skill` acts like an operational Rails playbook. It helps an AI agent handle common project work with opinionated defaults and a strong bias toward safe, verifiable changes.

It is designed for tasks such as:

- Creating a new Rails project
- Bootstrapping local development
- Implementing features
- Debugging regressions and production issues
- Running and fixing tests
- Reviewing migrations and database safety
- Updating gems and Rails versions
- Pulling applicable improvements from a reference project
- Preparing CI, deployment, and release workflows

For deployment work, the skill is also expected to explain any implemented `Makefile` commands to the user and add matching usage instructions to the target project's `README` when a deployment-management `Makefile` is introduced or updated.

## Philosophy

The skill is opinionated on purpose.

It assumes that speed matters, but unstructured speed creates expensive messes. The goal is to let the AI move fast without turning the project into garbage. In practice that means:

- Prefer small, testable changes over dramatic rewrites
- Use conventions aggressively where they reduce decision fatigue
- Keep the user focused on meaningful project decisions, not repetitive setup trivia
- Default to safe workflows, but stay practical when the user wants to move fast

This is why the skill can work in two modes at once:

- A beginner-friendly mode where the AI carries more of the process and keeps things moving
- A senior-friendly mode where the AI absorbs boilerplate work and leaves the engineer with the important decisions

## Core Opinions

The current skill has several strong defaults:

- Use `dip` for Rails and Bundler commands inside a project
- Use HAML for views
- Use Tailwind via `tailwindcss-rails`
- Use RSpec by default
- Avoid unsafe secret handling in chat
- Prefer project-local configuration over touching user dotfiles
- Treat the reference project at `https://github.com/purple-magic/base_project` as the canonical baseline for updates and setup patterns

These defaults are there to reduce noise, improve consistency, and make AI-assisted Rails work more reliable across many projects.

## Who This Is For

This skill is a good fit if:

- You are new to Rails and want fewer setup mistakes
- You want an AI assistant that can push through routine Rails work with good defaults
- You maintain multiple Rails projects and want repeatable workflows
- You value conventions, release discipline, and practical automation

It is especially useful if you do not want to re-explain the same Rails setup and maintenance rules every time you start a new project or open an existing one.

## Project Goal

The goal of `tramway-skill` is not to be a generic Rails knowledge dump.

The goal is to package a working style: a way for AI to help build and maintain Rails applications that is fast, practical, and disciplined enough to be useful in real projects.
