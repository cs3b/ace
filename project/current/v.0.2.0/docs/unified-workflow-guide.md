# Unified Development Workflow Guide

## Overview
This guide outlines the streamlined development workflow using the unified task management system within `docs-dev/project/`. This replaces previous disparate systems.

## Task Management Structure
- **`/backlog`**: Contains directories for future planned work/releases (e.g., `v.0.3.0-feature-x/`). Tasks are planned here.
- **`/current`**: Contains directories for the active release being worked on (e.g., `v.0.2.0-streamline-workflow/`). This is where active development happens. Task files within this directory represent work items.
- **`/done`**: Contains directories for completed and released work, serving as an archive.

## Task File Structure
Tasks within `/current` (and potentially planned in `/backlog`) should be `.md` files following this structure:

```markdown
---
id: <unique_task_id> # e.g., 01, 02-subtask-a, etc.
status: [pending | in-progress | done | blocked]
priority: [high | medium | low]
dependencies: [<task_id_1>, <task_id_2>] # List of IDs this task depends on
comment_ids: [<github_comment_id_1>] # Optional: Links to PR comments
---

# Task Title: A clear, concise title

## Description
Briefly describe the goal of this task.

## Implementation Details / Notes
- Specific steps required.
- Code pointers or files involved.
- Design considerations or constraints.
- Links to relevant documentation or ADRs.

## Acceptance Criteria / Test Strategy
- How to verify the task is complete.
- Specific tests to write or run.
- Expected outcomes.
- Use Markdown checklists for sub-tasks:
  - [ ] Sub-task 1
  - [ ] Sub-task 2
```

## Core Workflow Phases & Commands

The development process involves several distinct phases, often looping as needed:

**Phase 1: Task Implementation** (Repeats for each task)
1.  **Load Environment (`load-env`)**: *Start here.* Understand project context, architecture, and identify current work in `docs-dev/project/current/`.
2.  **Start Task (`lets-start`)**: Select a task from `docs-dev/project/current/`, review its details (using the structured format above), and prepare the environment.
3.  **Implement &amp; Test (`lets-tests`, `lets-fix-tests`)**: Follow TDD. Write tests, implement code, ensure tests pass.
4.  **Commit Changes (`lets-commit`)**: Create well-formed, atomic commits following the version control guide.
5.  **Self-Reflect (`self-reflect`)**: *End of task implementation.* Review session progress, update documentation (guides, ADRs), and capture learnings. (Update task status in its `.md` file).

**Phase 2: PR Feedback Integration** (Occurs after submitting code changes for review)
1.  **Load Environment (`load-env`)**: Refresh context.
2.  **Fetch PR Feedback (`fetch-comments-by-api` or `fetch-comments-by-mcp`)**:
    - Fetch comments for a specific PR (e.g., `fetch-comments-by-api https://github.com/org/repo/pull/123`). This stores feedback in `docs-dev/project/current/{release_dir}/docs/{pr_path}`.
3.  **Generate Tasks from Feedback (`lets-spec-from-pr-comments`)**:
    - Run `lets-spec-from-pr-comments {release_path}`. This analyzes the fetched feedback and **creates or updates** structured task files (`.md`) directly within `docs-dev/project/current/{release_dir}/tasks/`, linking them via `comment_ids`. Dependencies between generated tasks should be determined. Task files should be sequence-prefixed.
4.  **Review Progress (`_review-kanban-board`)**: Check the newly created/updated tasks within `docs-dev/project/current/`. Identify blockers or next steps.
5.  **Self-Reflect (`self-reflect`)**: Review the feedback processing, plan next steps.
6.  **-> Return to Phase 1** for each new task generated from feedback.

**Phase 3: Release Preparation** (Occurs when all tasks for the release in `/current` are done)
1.  **Load Environment (`load-env`)**: Refresh context.
2.  **Review Progress (`_review-kanban-board`)**: *Confirm all tasks are 'done'.* Check the status of tasks within `docs-dev/project/current/` by examining the task files.
3.  **Prepare Release Artifacts (`lets-release`)**: Follow the release process, using the `prepare-release` structure. Refer to the updated release guides for guidance on required artifacts based on release type (Patch, Feature, Major). Consider running complexity analysis if needed.
4.  **Self-Reflect (`self-reflect`)**: Review the release preparation process.
5.  **Final Release Actions**: Tagging, publishing, etc. (as per `guides/ship-release.md`).

*(Note: Specification from PRD/FRD will involve similar steps but use different `lets-spec-*` commands, likely leading to Feature or Major releases.)*

**General Commands Used Across Phases:**
- **Commands for generating documentation:** `generate-adr`, `generate-api-docs`, etc.
- **Logging:** `log-session` (defined in Task 04) should be used after significant interactions to capture context.

1.  **Load Environment (`load-env`)**: Start here. Understand project context, architecture, and identify current work in `docs-dev/project/current/`.
2.  **Start Task (`lets-start`)**: Select a task from `docs-dev/project/current/`, review its details (using the structured format above), and prepare the environment.
3.  **Implement &amp; Test (`lets-tests`, `lets-fix-tests`)**: Follow TDD. Write tests, implement code, ensure tests pass.
4.  **Commit Changes (`lets-commit`)**: Create well-formed, atomic commits following the version control guide.
5.  **Process PR Feedback (`lets-spec-from-pr`, `lets-spec-from-pr-comments`)**:
    - Fetch comments for a PR using `fetch-comments-by-api` (or `fetch-comments-by-mcp`). This stores feedback in `docs-dev/project/current/{release_dir}/docs/{pr_path}`.
    - Run `lets-spec-from-pr-comments {release_path}`. This command analyzes the fetched feedback and **creates or updates** structured task files (`.md`) directly within `docs-dev/project/current/{release_dir}/tasks/`, linking them via `comment_ids` in the frontmatter. Dependencies between generated tasks should be determined and added to the `dependencies` frontmatter key. Task files should be sequence-prefixed (e.g., `01-fix-thing.md`).
6.  **Review Progress (`_review-kanban-board`)**: Check the status of tasks within `docs-dev/project/current/` by examining the task files. Identify blockers or completed items.
7.  **Self-Reflect (`self-reflect`)**: Review session progress, update documentation (guides, ADRs), and capture learnings.
8.  **Prepare Release (`lets-release`)**: Follow the release process, using the `prepare-release` structure. Refer to the updated `prepare-release-documentation.md` for guidance on required artifacts based on release type.

## Release Documentation
- The structure in `docs-dev/guides/prepare-release/v.x.x.x/` remains, but its usage is clarified in `docs-dev/guides/prepare-release/prepare-release-documentation.md`. Not all directories are required for every release type (e.g., `codemods` likely only for major releases).

## Consistency
- Use `backlog`, `current`, `done` consistently.
- Commands should reference the single task system and point to relevant guides for detailed standards.
