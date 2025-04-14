---
id: 02
status: pending
priority: high
dependencies: [01] # Depends on task system consolidation
---

# Task Title: Update Commands for Unified Workflow

## Description
Modify existing command documentation (`.md` files in `docs-dev/commands/`) to align with the unified task management system and ensure consistency.

## Implementation Details / Notes
- **Audit Commands:** Review all files in `docs-dev/commands/` and its subdirectories.
- **`load-env`:** Ensure it correctly identifies work in `project/current/` based on the unified structure.
- **`lets-start`:** Ensure it references selecting tasks from `project/current/` using the standard task file format.
- **`lets-spec-from-pr-comments`:** Update description to match the new output (structured `.md` files in `project/current/{release_dir}/tasks/`). Ensure prerequisites (running `fetch-comments-by-api`) are clear. Update success criteria.
- **`_review-kanban-board`:** Align description with the `project/{backlog,current,done}` structure. Remove inconsistencies identified in analysis (references to `in-progress`, `next`, or `_dev/kanban/`). Ensure it describes checking task files within `project/current/`.
- **`self-reflect`:** Ensure it correctly references the location for current tasks (`project/current/`) and ADRs (`decisions/` which might be per-release or project-level - clarify this).
- **`lets-release`:** Ensure it points to the updated `prepare-release-documentation.md` for guidance.
- **Command/Guide Linking:** Check that commands primarily *link* to relevant guides (e.g., `lets-commit` links to `guides/version-control.md`) rather than duplicating detailed standards. Remove redundant content from command descriptions.
- **Terminology:** Ensure consistent use of "current" for the active work directory.

## Acceptance Criteria / Test Strategy
- All reviewed command `.md` files accurately reflect the unified task system (`project/current/`, standard task file format).
- `_review-kanban-board.md` description is consistent with the `project/{backlog,current,done}` structure.
- `lets-spec-from-pr-comments.md` accurately describes the input/output of the updated feedback processing workflow.
- Commands link appropriately to guides, minimizing duplication.
- Consistent terminology is used across all command files.