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
- **ADR Location:** Decide and document whether ADRs in `decisions/` should be stored per-release (`project/current/{release}/decisions/`) or at the project root (`docs-dev/decisions/`). Update references accordingly.
- **`self-reflect`:** Ensure it correctly references the location for current tasks (`project/current/`) and ADRs (`decisions/` which might be per-release or project-level - clarify this).
- **`lets-release`:** Ensure it points to the updated `prepare-release-documentation.md` for guidance.
- **Command/Guide Linking:** Check that commands primarily *link* to relevant guides (e.g., `lets-commit` links to `guides/version-control.md`) rather than duplicating detailed standards. Remove redundant content from command descriptions.
- **Terminology:** Ensure consistent use of "current" for the active work directory.
- **Define New Spec Commands:** Create documentation (`.md` files) for `lets-spec-from-prd` and `lets-spec-from-frd`. These commands will parse higher-level requirement documents (Product Requirement Document, Feature Requirement Document) and generate the necessary release structure and tasks (potentially spanning multiple releases for a PRD).
*(Note: v0.2.0 scope is primarily focused on defining these commands and their associated process documentation. Implementation of underlying scripts/tooling may be deferred.)*
- **Integrate Release Doc Logic:** The logic currently outlined in `guides/prepare-release/prepare-release-documentation.md` (mapping requirements to release artifacts like docs, decisions, test cases based on complexity/type - Major, Feature) should be integrated into the process descriptions for `lets-spec-from-prd` and `lets-spec-from-frd`. The original guide file should eventually be removed.
- **Handle Reference Docs:** Ensure the new spec commands can utilize non-sequenced reference documents provided by the developer within the release directory during the specification process.

## Acceptance Criteria / Test Strategy
- All reviewed command `.md` files accurately reflect the unified task system (`project/current/`, standard task file format).
- `_review-kanban-board.md` description is consistent with the `project/{backlog,current,done}` structure.
- `lets-spec-from-pr-comments.md` accurately describes the input/output for PR feedback -> patch task generation.
- New command docs for `lets-spec-from-prd` and `lets-spec-from-frd` are created and outline the process for generating feature/major release specs.
- Commands link appropriately to guides, minimizing duplication.
- Consistent terminology is used across all command files.
