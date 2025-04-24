# Let's Start Workflow Instruction

**Goal:** Initiate the workflow for implementing a specific task by guiding the selection of the task, ensuring full understanding of its requirements, and preparing a plan for implementation. This prepares the developer (human or AI) to begin the standard development cycle.

**Prerequisites:**

*   Run the [`load-env`](docs-dev/workflow-instructions/load-env.md) workflow instruction first to load project context, general guides, project specifics, and identify the current release/tasks.

## Prerequisites

*   `load-env` workflow instruction has been successfully executed, loading project context.
*   The current release directory (`docs-project/current/{release_dir}/`) and its tasks are identified.
*   Developer is ready to select and begin working on a specific task.

## Process Steps

1.  **Review Release Context & Select Task:**
    *   Identify the current release directory path (from `load-env`).
    *   Read the release overview: `cat docs-project/current/{release_dir}/README.md` (or equivalent main file).
    *   List available tasks: `ls -1 docs-project/current/{release_dir}/tasks/*.md`
    *   Review task details as needed (e.g., `cat docs-project/current/{release_dir}/tasks/NN-*.md`). Check `status`, `priority`, and `dependencies`.
    *   **User Action:** Choose the specific task `.md` file to work on (typically `status: pending` with met `dependencies`).

2.  **Understand Task & Plan (Planning Before Prompting):**
    *   Load the selected task's `.md` file content.
    *   **Thorough Review:** Carefully review all sections:
        *   `# Task Title`
        *   `## Description` (Understand the *what* and *why*)
        *   `## Implementation Details / Notes` (Initial *how*)
        *   `## Acceptance Criteria / Test Strategy` (Define *done*)
    *   **Clarify:** Ensure the goal, implementation steps, and verification methods are unambiguous. Ask clarifying questions *before* proceeding.
    *   **Plan (Prepare for AI Collaboration):**
        *   **Detailed Steps:** Break down the implementation into smaller, specific steps. Consider writing pseudocode or outlining the logic flow. This plan will guide the AI.
        *   **TDD Planning:** Outline specific tests based on Acceptance Criteria. Think about inputs, outputs, and edge cases for each test.
        *   **Context Gathering:** Identify relevant existing code files, patterns, or conventions in the codebase that the AI should follow. Refer to `docs-project/blueprint.md` and `docs-project/architecture.md`.
        *   **Define AI Role (Optional but Recommended):** Briefly define the AI's objective for the *first* implementation step (e.g., "Generate the initial failing test structure for function X", "Implement the core logic for Y based on this pseudocode").

3.  **Proceed to Implementation Cycle:**
    *   With the task understood and a plan in place, proceed to the main development workflow.
    *   Follow the steps outlined in the **[Implementing the Task Cycle Guide](docs-dev/guides/implementing-task-cycle.md)** for Test-Driven Development, committing changes, and self-reflection.

## Reference Documentation

*   [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
*   [Project Management Guide](docs-dev/guides/project-management.md) (Task format, implementation cycle)
*   [Coding Standards Guide](docs-dev/guides/coding-standards.md) (AI Collaboration Principles)
*   [`load-env` Workflow Instruction](docs-dev/workflow-instructions/load-env.md)
*   **[Implementing the Task Cycle Guide](docs-dev/guides/implementing-task-cycle.md)** (The main guide for Test -> Code -> Commit -> Reflect)

## Input

*   User selection of a specific task `.md` file from `docs-project/current/{release_dir}/tasks/`.

## Output / Success Criteria

*   Confirmation that the selected task is understood and its dependencies are met.
*   A high-level plan for implementing the task (including testing strategy) is established.
*   Developer is ready to begin the implementation cycle following the **[Implementing the Task Cycle Guide](docs-dev/guides/implementing-task-cycle.md)**.
