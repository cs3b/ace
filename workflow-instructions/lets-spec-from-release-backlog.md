# Workflow Instruction: Process Release-Specific Backlog (lets-spec-from-release-backlog)

## Goal
Process notes, ideas, or draft tasks captured in the internal `backlog/` subdirectory of the *current* release (or a specified target release in `docs-project/backlog/`) and transform them into structured tasks *within that same release's* `tasks/` directory. This helps manage emergent scope identified during active development.

## Process Steps

1.  **Identify Target Release and Source Backlog:**
    *   Determine the target release directory. By default, this is the directory currently located in `docs-project/current/`.
    *   If instructed otherwise (e.g., "process the backlog for release v1.3.0 in the main project backlog"), identify the specified target release directory within `docs-project/backlog/`.
    *   Verify the existence of the target release directory and its internal `backlog/` subdirectory (e.g., `docs-project/current/{release_dir}-workflow-instruction/backlog/`).

## Input
- Target release directory path (defaults to the single directory in `docs-project/current/`, otherwise requires explicit path like `docs-project/backlog/v1.3.0-Enhancements/`).
- Items (notes, draft tasks as `.md` files) within the `{target_release_path}/backlog/` directory.
2.  **Review Backlog Items:**
    *   List the files/notes within the source `backlog/` directory.
    *   Present each item (e.g., a simple `.md` note) to the user/agent for review.

No new release directory is created by this workflow instruction.

4.  **Generate Structured Tasks:**
    *   For each item reviewed from the source `backlog/` subdirectory:
    (see `docs-dev/guides/project-management.md`).
        *   Save the new task file into the `tasks/` subdirectory of the *target* release directory (e.g., `docs-project/current/{release_dir}/tasks/NN-implement-idea-x.md`). Ensure tasks get appropriate sequence numbers.
        *   Determine dependencies between the newly created tasks and existing tasks within the target release.

5.  **Update Target Release Overview:**
    *   Update the `README.md` file within the *target* release directory to include the newly generated tasks in its overview or task list.

6.  **Communicate Results:**
    *   Report the number of backlog items processed.
    *   Report the number of new tasks created within the target release.
    *   Show the path to the target release directory where tasks were added.
    *   Suggest next steps (review the newly added tasks within the target release).

## Output / Success Criteria

**Output:**
- Structured task files (`.md`) created or updated in the *target* release's `tasks/` directory.
- Task dependencies (relative to other tasks in the target release) identified and populated.
- The *target* release's `README.md` file updated with the newly added tasks.
- Confirmation message summarizing items processed, tasks created, and target release location.

**Success Criteria:**

*   Target release directory (in `current/` or `backlog/`) identified.
*   Items from the target release's internal `backlog/` subdirectory reviewed.
*   Reviewed backlog items successfully transformed into structured task files (`.md`) within the *target* release's `tasks/` directory.
*   Task dependencies identified (relative to other tasks in the target release).
*   Target release `README.md` updated with new tasks.

## Prerequisites

*   A target release directory exists in `docs-project/current/` or `docs-project/backlog/`.
*   The target release directory contains a `backlog/` subdirectory with items (notes, draft tasks) to process.
Understanding of the [Project Management Guide](docs-dev/guides/project-management.md) and standard task format.

## Agent Instruction Examples

**Example 1: Process backlog for the CURRENT release**

> "Run the `lets-spec-from-release-backlog` command to process items added to the current release's internal backlog."

*(Agent identifies the release in `docs-project/current/`, reads items from its `backlog/` subdirectory, guides creation of tasks within its `tasks/` subdirectory, updates its `README.md`, and reports results.)*

**Example 2: Process backlog for a specific release in the main project backlog**

> "Use the `lets-spec-from-release-backlog` command, targeting release `v1.3.0-Enhancements` located in the main project backlog."

*(Agent identifies `docs-project/backlog/v1.3.0-Enhancements/`, reads items from its `backlog/` subdirectory, guides creation of tasks within its `tasks/` subdirectory, updates its `README.md`, and reports results.)*
## Reference Documentation
- [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
- [Project Management Guide](docs-dev/guides/project-management.md) (Standard task format, release structure)
