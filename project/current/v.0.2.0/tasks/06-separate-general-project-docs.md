---
id: 06
status: pending
priority: medium
dependencies: []
---

# Task Title: Separate General and Project-Specific docs-dev Content

## Description
Refactor the `docs-dev` structure and content to clearly distinguish between general development process documentation (applicable to any project using this system) and documentation specific to the `ai-ruby-agent-sdk` project itself. Ensure context-loading mechanisms handle both.

## Implementation Details / Notes
- **Audit:** Review `docs-dev/guides/`, `docs-dev/commands/`, and `docs-dev/tools/` for content tightly coupled to `ai-ruby-agent-sdk` specifics (e.g., file paths like `lib/aira/version.rb`, tool names, SDK architectural details).
- **Refactor Structure:** Decide on a structure for separating general vs. project-specific docs (e.g., parallel dirs like `docs-dev/project-guides/` or integration within `docs-dev/project/`).
- **Move/Generalize:** Relocate project-specific docs and generalize content in main `guides/` and `commands/`.
- **Introduce Project Blueprint:**
    - Define a standard location for a dynamically generated project overview, e.g., `docs-dev/project/blueprint.md`.
    - This blueprint should summarize the project's structure (key directories/files) and potentially link to core project documents (`what-do-we-build.md`, `architecture.md`).
    - Define a new command/utility (e.g., `generate-blueprint`) responsible for creating or refreshing this `blueprint.md` file based on the current project state.
    - Determine the refresh strategy for the blueprint (e.g., run manually, after each release, triggered by `load-env` if changed).
- **Update Context Loading:** Modify context loading commands (like `load-env`) to incorporate the `blueprint.md` file, alongside general and project-specific guides/commands based on the chosen structure.

## Acceptance Criteria / Test Strategy
- `docs-dev` structure clearly separates general vs. project-specific content.
- A `generate-blueprint` command/utility documentation exists, explaining how to refresh `docs-dev/project/blueprint.md`.
- `load-env` (or equivalent) documentation outlines loading of general docs, project-specific docs, and the project `blueprint.md`.
- General guides/commands are free of hardcoded project specifics.
- Project-specific documentation exists in its designated location.
