# Let's Start Command

**Goal:** Initiate the workflow for implementing a specific task after the environment context has been loaded using `load-env`.

**Prerequisites:**
- Run the [`load-env`](./load-env.md) command first to load project context, general guides, project specifics, and identify the current release/tasks.

## Process Steps

1.  **Review Release Context & Select Task:**
    *   Identify the current release directory path (from `load-env`).
    *   Read the release overview: `cat docs-dev/project/current/{release_dir}/README.md` (or equivalent main file).
    *   List available tasks: `ls -1 docs-dev/project/current/{release_dir}/tasks/*.md`
    *   Review task details as needed (e.g., `cat docs-dev/project/current/{release_dir}/tasks/NN-*.md`). Check `status`, `priority`, and `dependencies`.
    *   **User Action:** Choose the specific task `.md` file to work on (typically `status: pending` with met `dependencies`).

2.  **Understand Task & Plan:**
    *   Load the selected task's `.md` file content.
    *   Review thoroughly:
        *   `# Task Title`
        *   `## Description`
        *   `## Implementation Details / Notes`
        *   `## Acceptance Criteria / Test Strategy` (including checklists)
    *   **Clarify:** Ensure the goal, implementation steps, and verification methods are clear. Ask questions if needed.
    *   **Plan (TDD):** Outline tests based on Acceptance Criteria. Plan implementation steps based on Details/Notes. Identify relevant code files.

3.  **Initiate Implementation Cycle:**
    *   Begin the standard task cycle (refer to `guides/project-management.md`):
        *   Write Tests (`lets-tests`)
        *   Implement Code
        *   Verify Tests (`bin/rspec`, `lets-fix-tests` if needed)
        *   Commit Changes (`lets-commit`)
        *   Reflect (`self-reflect`)
        *   Update task status in its `.md` file.

## Success Criteria

1.  **Task Selected:** A specific task `.md` file from `docs-dev/project/current/*/tasks/` is chosen by the user.
2.  **Task Understood:** The selected task's description, implementation notes, and acceptance criteria are loaded and clear.
3.  **Dependencies Confirmed:** Dependencies listed in the task's frontmatter are verified as met (status: done).
4.  **Plan Formulated:** A basic plan for testing and implementation is outlined.
5.  **Ready to Implement:** The user is ready to begin the TDD cycle for the selected task.
