# Review Project State Workflow Instruction

## Goal
Review the overall state of project tasks across the `docs-project/backlog/`, `docs-project/current/`, and `docs-project/done/` directories to understand progress, identify blockers, prioritize current work, and plan release transitions.

## Prerequisites
- The `docs-project/` directory exists with the `backlog/`, `current/`, and `done/` subdirectories.
- Task files within `docs-project/current/*/tasks/` follow the standard Markdown format with frontmatter (including `status:` and `dependencies:` fields).

## Process Steps

1.  **Check Backlog (`docs-project/backlog/`)**:
    *   List directories/releases planned for the future: `ls -1 docs-project/backlog/`
    *   *Optional:* Briefly review the `README.md` or tasks within a specific planned release if needed for context.
    *   Identify potential next releases ready to be moved to `current/`.

2.  **Check Current Work (`docs-project/current/`)**:
    *   Identify the active release directory: `ls -1 docs-project/current/` (Should typically contain only one).
    *   List tasks within the active release: `ls -1 docs-project/current/*/tasks/*.md`
    *   **Review Task Statuses**: Check the `status:` field in the frontmatter of each task `.md` file within the current release.
        *   Use `grep 'status:' docs-project/current/*/tasks/*.md | sort | uniq -c` to get counts.
        *   Identify specific tasks that are `pending`, `in-progress`, `done`, or `blocked`.
    *   **Check Dependencies**: Review the `dependencies:` field in `pending` or `in-progress` tasks to ensure prerequisites are met (i.e., dependent tasks have `status: done`). Identify blockers.
    *   Determine overall progress towards completing the current release.

3.  **Check Done (`docs-project/done/`)**:
    *   List archived/completed release directories: `ls -1 docs-project/done/`
    *   *Optional:* Review contents of a past release if needed for historical context.

4.  **Synthesize & Plan**:
    *   Summarize the overall project status.
    *   Identify the next task(s) to work on within the `current/` release based on priority and dependencies.
    *   Determine if the `current/` release is ready for the release process (all tasks `done`).
    *   Determine if a release from `backlog/` should be moved to `current/`.

## Input
- User request to review the project state.

## Output / Success Criteria
- [x] Contents of `backlog/`, `current/`, and `done/` are listed and reviewed.
- [x] Statuses and dependencies of tasks in the `current/` release are assessed.
- [x] Blockers or unmet dependencies are identified.
- [x] Overall project progress is understood.
- [x] Next steps are identified (e.g., next task to start, readiness for release, moving a release from backlog).

## Reference Documentation
- [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
- [Project Management Guide](docs-dev/guides/project-management.md) (Describes the directory structure and task format)
- Standard Task `.md` file format.

## Usage Example
Invoke this workflow instruction:
- At the start of a work session to understand the current state.
- Periodically to check progress on the current release.
- Before deciding to start the release process for the current release.
- When planning to activate a new release from the backlog.

Example Invocation:
> "Run the `review-kanban-board` workflow instruction to check the project status."
