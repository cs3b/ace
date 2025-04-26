# Work on Task Workflow Instruction

**Goal:** Initiate and guide the step-by-step implementation of a specific task, using the detailed plan embedded directly within the task's definition file (`NN-task-name.md`).

**Prerequisites:**

*   Run the [`load-env`](docs-dev/workflow-instructions/load-env.md) workflow instruction first to load project context, general guides, project specifics, and identify the current release/tasks.
*   Task definition files (`docs-project/current/{release_dir}/tasks/NN-task-name.md`) contain a dedicated section (e.g., `## Implementation Plan`) with a detailed, step-by-step checklist using Markdown (`- [ ] Action description...`). *(Note: The exact structure is defined in `write-actionable-task.md`)*.

## Process Steps

1.  **Select Task File:**
    *   Identify the current release directory path (from `load-env`).
    *   List available tasks: `ls -1 docs-project/current/{release_dir}/tasks/*.md`
    *   Review task details as needed (`cat ...`). Check `status`, `priority`, and `dependencies`.
    *   **User Action:** Choose the specific task `.md` file to work on (typically `status: pending` with met `dependencies`). Provide the full path to this file.

2.  **Load Task & Validate Plan:**
    *   Load the content of the selected task `.md` file.
    *   **Verify Embedded Plan:**
        *   Confirm the presence of the required implementation plan section (e.g., `## Implementation Plan`).
        *   Check that this section contains a list of actionable steps formatted as Markdown checklist items (`- [ ] ...`).
        *   If the plan is missing or incorrectly formatted, STOP and report the issue. The task file needs correction according to `write-actionable-task.md`.
    *   **Review High-Level Goal:** Briefly review the task's main Objective/Description to ensure alignment before execution.

3.  **Load Context:**
    *   Identify relevant project context needed for execution:
        *   **General Guides:** (e.g., `coding-standards.md`, `testing.md`, `architecture.md`). These might be standard context or explicitly mentioned in the task file.
        *   **Specific Code Files:** Identify key files/modules likely to be modified based on the embedded plan (if listed in the task file or inferable).
    *   **AI Action:** Ensure this context (guides, relevant code snippets) is loaded and considered during execution.

4.  **Execute Task Plan Step-by-Step:**
    *   Focus on the checklist items (`- [ ] ...`) within the task file's `## Implementation Plan` section.
    *   **Iterate through Checklist:** Address each `- [ ]` item sequentially.
    *   **Follow Task Cycle Principles:** For each item involving code changes, generally follow the [Implementing the Task Cycle Guide](docs-dev/guides/task-cycle.md) principles (Test -> Code -> Refactor -> Verify).
    *   **Update Checklist:** After successfully completing the action for a checklist item, update its status in the task file: `- [x] Action description...`
    *   **Commit Appropriately:** Decide on commit frequency. Commit after each logical step (checklist item) or group of related items, following [`lets-commit.md`](docs-dev/workflow-instructions/lets-commit.md) (or renamed equivalent).
    *   Continue until all checklist items in the plan are marked `- [x]`.

5.  **Final Review & Status Update:**
    *   Review the completed work against the task's `## Acceptance Criteria`.
    *   Run final checks or tests as defined.
    *   Once satisfied, update the task file's `status:` field (e.g., to `done`).
    *   Perform a final commit.

## Reference Documentation

*   [Writing Actionable Task Guide](docs-dev/guides/write-actionable-task.md) (Defines the required embedded plan structure)
*   [Implementing the Task Cycle Guide](docs-dev/guides/task-cycle.md) (Core TDD loop)
*   [Let's Commit Workflow](docs-dev/workflow-instructions/lets-commit.md) (or renamed equivalent - Git workflow)
*   [`load-env` Workflow Instruction](docs-dev/workflow-instructions/load-env.md)
*   Project-specific guides (Coding Standards, Architecture, etc.) as identified in Step 3.

## Input

*   Full path to the selected task `.md` file containing an embedded implementation plan.

## Output / Success Criteria

*   All checklist items (`- [ ]`) in the task file's implementation plan are completed and marked (`- [x]`).
*   The work passes the task's Acceptance Criteria.
*   The task file's status is updated (e.g., to `done`).
*   All changes are committed according to project standards.
