---
id: 01
status: pending
priority: high
dependencies: []
---

# Task Title: Solidify Unified Task Management System

## Description
Formally establish the `project/{backlog,current,done}` structure as the single source of truth for tasks, define a standard Markdown task format, and remove the experimental `project/task-manager` directory.

## Implementation Details / Notes
- **Decision:** Formalize the decision in `ADR-001-Unified-Task-Management.md`.
- **Define Standard Task Format:** Finalize the Markdown frontmatter and section structure for task files within `project/current/`. Ensure it includes fields for `id`, `status`, `priority`, `dependencies`, and optional `comment_ids`. Consider placeholders or conventions for potential future `complexity` or subtask sections. Refer to `docs/unified-workflow-guide.md`.
- **Update PR Feedback Workflow:** Modify `lets-spec-from-pr-comments` command documentation (`.md` file) to reflect that it generates/updates tasks using the new standard format within `project/current/{release_dir}/tasks/`. Ensure it specifies linking back to comment IDs and determining task dependencies.
- **Removal:** Delete the `docs-dev/project/task-manager` directory. Update the main project `.gitignore` if necessary.
- **Update Core Guides:** Modify `guides/project-management.md` to reflect the unified system and the standard task format. Remove references to `task-manager`.
- **Integrate Research Concepts:** Ensure the standard task format and updated guides incorporate relevant ideas from `task-master-ai-hlo.md` and `windsurf-tips.md` (e.g., emphasis on planning, structured task details).

## Acceptance Criteria / Test Strategy
- `docs-dev/project/task-manager` directory is removed.
- `ADR-001` is finalized and accepted.
- `guides/project-management.md` and/or `docs/unified-workflow-guide.md` accurately describe the unified system and standard task format.
- `lets-spec-from-pr-comments` command documentation reflects the updated workflow.
- Standard task format definition is clear and documented.