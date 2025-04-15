# Command: Process Release-Specific Backlog (lets-spec-from-release-backlog)

## Goal
Process notes, ideas, or draft tasks captured in the internal `backlog/` subdirectory of the *current* release (or a specified target release in `docs-dev/project/backlog/`) and transform them into structured tasks *within that same release's* `tasks/` directory. This helps manage emergent scope identified during active development.

## Process Steps

1.  **Identify Target Release and Source Backlog:**
    *   Determine the target release directory. By default, this is the directory currently located in `docs-dev/project/current/`.
    *   If instructed otherwise (e.g., "process the backlog for release v1.3.0 in the main project backlog"), identify the specified target release directory within `docs-dev/project/backlog/`.
    *   Verify the existence of the target release directory and its internal `backlog/` subdirectory (e.g., `docs-dev/project/current/{release_dir}/backlog/`).

2.  **Review Backlog Items:**
    *   List the files/notes within the source `backlog/` directory.
    *   Present each item (e.g., a simple `.md` note) to the user/agent for review.

3.  **(Step Removed)** The target release directory already exists (either in `current/` or `backlog/`). No new release directory is created by this command.

4.  **Generate Structured Tasks:**
    *   For each item reviewed from the source `backlog/` subdirectory:
        *   Guide the user/agent to transform the note/idea into a fully structured task file (`.md`) using the standard format (see `guides/project-management.md`).
        *   Save the new task file into the `tasks/` subdirectory of the *target* release directory (e.g., `docs-dev/project/current/{release_dir}/tasks/NN-implement-idea-x.md`). Ensure tasks get appropriate sequence numbers.
        *   Determine dependencies between the newly created tasks and existing tasks within the target release.

5.  **Update Target Release Overview:**
    *   Update the `README.md` file within the *target* release directory to include the newly generated tasks in its overview or task list.

6.  **Communicate Results:**
    *   Report the number of backlog items processed.
    *   Report the number of new tasks created within the target release.
    *   Show the path to the target release directory where tasks were added.
    *   Suggest next steps (review the newly added tasks within the target release).

## Success Criteria

*   Target release directory (in `current/` or `backlog/`) identified.
*   Items from the target release's internal `backlog/` subdirectory reviewed.
*   Reviewed backlog items successfully transformed into structured task files (`.md`) within the *target* release's `tasks/` directory.
*   Task dependencies identified (relative to other tasks in the target release).
*   Target release `README.md` updated with new tasks.

## Prerequisites

*   A target release directory exists in `docs-dev/project/current/` or `docs-dev/project/backlog/`.
*   The target release directory contains a `backlog/` subdirectory with items (notes, draft tasks) to process.
*   Understanding of the [Project Management Guide](../guides/project-management.md) and standard task format.

## Agent Instruction Examples

**Example 1: Process backlog for the CURRENT release**

> "Run the `lets-spec-from-release-backlog` command to process items added to the current release's internal backlog."

*(Agent identifies the release in `docs-dev/project/current/`, reads items from its `backlog/` subdirectory, guides creation of tasks within its `tasks/` subdirectory, updates its `README.md`, and reports results.)*

**Example 2: Process backlog for a specific release in the main project backlog**

> "Use the `lets-spec-from-release-backlog` command, targeting release `v1.3.0-Enhancements` located in the main project backlog."

*(Agent identifies `docs-dev/project/backlog/v1.3.0-Enhancements/`, reads items from its `backlog/` subdirectory, guides creation of tasks within its `tasks/` subdirectory, updates its `README.md`, and reports results.)*
