---
id: 06
status: done
priority: medium
dependencies: []
---

# Task Title: Separate General and Project-Specific docs-dev Content

## Description
Refactor the `docs-dev` structure and content to clearly distinguish between general development process documentation (applicable to any project using this system) and documentation specific to the `ai-ruby-agent-sdk` project itself. Ensure context-loading mechanisms handle both.

## Implementation Details / Notes
- **Audit:** Reviewed `docs-dev/guides/`, `docs-dev/commands/`. Identified project-specific paths and examples (e.g., `lib/aira/version.rb`, `spec/aira/`, gem-specific examples).
- **Refactor Structure:** Project-specific documentation (`what-do-we-build.md`, `architecture.md`, `decisions/`) remains within `docs-dev/project/`. General guides and commands remain in `docs-dev/guides/` and `docs-dev/commands/`.
- **Move/Generalize:** Generalized content in main `guides/` (`coding-standards.md`, `testing.md`) and `commands/` (`load-env.md`, `lets-start.md`, `lets-commit.md`, `lets-fix-tests.md`, `lets-release.md`) by removing specific paths/examples.
- **Introduce Project Blueprint:**
    - Created `docs-dev/project/blueprint.md` to hold project structure overview and key file list.
    - Created `docs-dev/commands/generate-blueprint.md` documenting the manual process for updating the blueprint. Refresh strategy is manual for now.
- **Update Context Loading:** Modified `docs-dev/commands/load-env.md` to load general guides/commands, project-specific docs from `docs-dev/project/`, and the new `docs-dev/project/blueprint.md`.

## Acceptance Criteria / Test Strategy
- `docs-dev` structure clearly separates general vs. project-specific content (Project-specific in `docs-dev/project/`, General in `docs-dev/guides/` & `docs-dev/commands/`).
- `docs-dev/commands/generate-blueprint.md` exists, explaining how to refresh `docs-dev/project/blueprint.md`.
- `docs-dev/commands/load-env.md` documentation outlines loading of general docs, project-specific docs (`what-do-we-build.md`, `architecture.md`), and the project `blueprint.md`.
- General guides/commands (`coding-standards`, `testing`, `load-env`, `lets-start`, etc.) are free of hardcoded project specifics.
- Project-specific documentation (`what-do-we-build.md`, `architecture.md`, `decisions/`) exists in `docs-dev/project/`.
