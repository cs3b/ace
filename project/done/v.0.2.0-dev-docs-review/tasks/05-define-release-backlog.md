---
id: 05
status: done
priority: medium
dependencies: [] # May depend on v0.2.0 completion, review later
---

# Task Title: Define Release-Specific Backlog Process

## Description
Add a mechanism to manage feedback or emergent tasks that arise *during* an active release cycle but are intended for a *future* release, preventing scope creep in the current one.

## Implementation Details / Notes
- Define a `backlog/` subdirectory within the standard release directory structure (e.g., `docs-dev/project/current/v.X.Y.Z-codename/backlog/`). This directory will hold simple notes or draft task files.
- Define a new command, `lets-spec-from-release-backlog`. This command, when executed by the AI agent, processes items from the internal `backlog/` subdirectory of the target release (defaulting to the `current` release, or a specific release if instructed).
- The agent executing this command guides the conversion of these backlog items into structured tasks within the *same target release's* `tasks/` directory.
- Update relevant guides (`project-management.md`, `unified-workflow-guide.md`) to explain this sub-backlog concept and the associated command.

## Acceptance Criteria / Test Strategy
- Standard release directory structure documentation includes the optional `backlog/` subdirectory.
- A new command file `docs-dev/commands/lets-spec-from-release-backlog.md` is created, outlining its purpose and process.
- `guides/project-management.md` and/or `docs/unified-workflow-guide.md` explain the purpose and workflow for the release-specific backlog.