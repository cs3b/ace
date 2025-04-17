## Review Project State Workflow Instruction

This workflow instruction helps review the overall state of project tasks across backlog, current work, and completed items.

**Process:**

1.  **Check Backlog (`docs-project/backlog/`)**:
    *   List directories: `ls -1 docs-project/backlog/`
    *   Review planned releases and their task files (`.md`) if defined.
    *   Identify potential next releases to move to `current/`.

2.  **Check Current Work (`docs-project/current/`)**:
    *   Identify the active release directory: `ls -1 docs-project/current/`
    *   List tasks within the active release: `ls -1 docs-project/current/*/tasks/*.md`
    *   **Review Task Statuses**: Check the `status:` field in the frontmatter of each task `.md` file. Use tools like `grep` or manually inspect files:
        ```bash
        # Example: Find pending tasks in the current release
        grep -l 'status: pending' docs-project/current/*/tasks/*.md
        # Example: Count tasks by status
        grep 'status:' docs-project/current/*/tasks/*.md | sort | uniq -c
        ```
    *   Identify tasks that are `in-progress`, `blocked`, or `done`.
    *   Check for dependencies between tasks using the `dependencies:` field.

3.  **Check Done (`docs-project/done/`)**:
docs-dev/workflow instructions/review-kanban-board.md

**Goal:**

*   Understand overall project progress.
*   Prioritize tasks within the `current/` release.
*   Identify completed tasks and potential blockers or unmet dependencies.
*   Plan the transition of releases between `backlog/`, `current/`, and `done/`.
