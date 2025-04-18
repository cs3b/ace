# Let's Start Workflow Instruction

**Goal:** Initiate the workflow for implementing a specific task after the environment context has been loaded using `load-env`.

**Prerequisites:**
- Run the [`load-env`](./load-env.md) workflow instruction first to load project context, general guides, project specifics, and identify the current release/tasks.

## Prerequisites
- `load-env` workflow instruction has been successfully executed, loading project context.
- The current release directory (`docs-project/current/{release_dir}/`) and its tasks are identified.
- Developer is ready to select and begin working on a specific task.
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

3.  **Initiate Implementation Cycle (Guided AI Execution):**
    *   Begin the standard task cycle (refer to `guides/project-management.md`), using the plan from Step 2 to guide the AI:
        *   **Write Tests (`lets-tests`):** Provide the AI with the planned test structure and acceptance criteria. Review the generated test code carefully.
        *   **Implement Code:** Provide the AI with the detailed implementation step (e.g., pseudocode, specific function signature, relevant context). Use clear, concise instructions. Consider using prompts like "ONLY IMPLEMENT EXACTLY THIS STEP."
        *   **Verify Tests (`bin/rspec`, `lets-fix-tests` if needed):** Run tests. If they fail, provide the AI with the error message and relevant code snippets for debugging.
        *   **Commit Changes (`lets-commit`):** Ensure commits are atomic and follow project conventions. Review the commit message generated or suggested by the AI.
        *   **Reflect (`self-reflect`):** Analyze the implementation process, the AI's contribution, and capture learnings.
        *   **Update Task Status:** Update the task status in its `.md` file.
    *   **Review Rigorously:** Treat AI-generated code as if it were written by a junior developer. Review it thoroughly for correctness, adherence to standards, and potential issues before committing.
    ## Reference Documentation
    - [Writing Workflow Instructions Guide](../guides/writing-workflow-instructions.md)
    - [Project Management Guide](../guides/project-management.md) (Task format, implementation cycle)
    - [Testing Guidelines Guide](../guides/testing.md)
    - [Coding Standards Guide](../guides/coding-standards.md) (AI Collaboration Principles)
    - `load-env` Workflow Instruction
    - `lets-tests` Workflow Instruction
    - `lets-commit` Workflow Instruction
    - `self-reflect` Workflow Instruction

## Input
- User selection of a specific task `.md` file from `docs-project/current/{release_dir}/tasks/`.

## Output / Success Criteria
- Confirmation that the selected task is understood and its dependencies are met.
- A high-level plan for implementing the task (including testing strategy) is established.
- Developer is ready to begin the TDD cycle for the selected task, potentially using `lets-tests`.


