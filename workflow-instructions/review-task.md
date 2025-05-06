# Review Task Workflow Instruction

## Goal
Review and refine a task definition, potentially proposing an implementation approach or solution, ensuring it aligns with project goals, architecture, and recent changes. Identify areas requiring user feedback or further clarification.

## Prerequisites
- The project environment has been loaded using the `load-env` workflow instruction to provide necessary context (guides, architecture, blueprint), including a review of recent code changes.
- The task to be reviewed exists as a Markdown file, ideally following the structure defined in the [Write Actionable Task Guide](../guides/write-actionable-task.md).
- The task file is located within the `docs-project/{backlog|current}/{release_dir}/tasks/` directory.

## Input
- The full path to the task `.md` file to be reviewed.

## Process Steps

1.  **Load Task Content:**
    *   Read the content of the provided task `.md` file.
    *   Parse the frontmatter (id, status, priority, dependencies) and sections (Objective, Description, Scope, Deliverables, Implementation Plan, Acceptance Criteria, Out of Scope, References).

2.  **Review Task Against Context:**
    *   Compare the task's Objective and Description against the project's overall goals as defined in [What We Build](docs-project/what-do-we-build.md).
    *   Evaluate the proposed Implementation Details, Scope, and Deliverables in light of the project [Architecture](docs-project/architecture.md) and [Blueprint](docs-project/blueprint.md). Identify any potential architectural conflicts or structural challenges.
    *   **Review Recent Git History:** Explicitly consider recent code changes as identified during the `load-env` workflow (e.g., by reviewing recent commits and file changes) to see if they impact the task's assumptions, requirements, or implementation plan. Look for changes in related code areas or foundational parts of the project.
    *   Review the task's dependencies against the current project status (as understood from `review-kanban-board` or `load-env`) to confirm they are met or identify blockers.

3.  **Identify Needs for Update:**
    *   Based on the review, determine if the task file needs updates due to:
        *   Ambiguity in description or requirements.
        *   Inconsistencies with project standards ([Coding Standards](../guides/coding-standards.md), [Documentation Standards](../guides/documentation.md), etc.).
        *   Impact from recent code changes or architectural decisions ([ADRs](docs-dev/decisions/)).
        *   Missing or unclear Implementation Plan steps.
        *   Inadequate or unverifiable Acceptance Criteria.
    *   Note down specific areas requiring refinement.

4.  **Think and Propose Solution/Refinement:**
    *   Use the `thinking` tool to analyze the task requirements, existing plan, and project context, incorporating the understanding of recent changes.
    *   Brainstorm potential implementation approaches or refinements to the existing plan, ensuring compatibility with recent work.
    *   If the task is complex or underspecified, propose a high-level solution structure or a more detailed implementation plan checklist.
    *   Consider alternative approaches and their trade-offs (align with [Architecture Guide](docs-project/architecture.md) principles).
    *   Identify specific code files or guides that will be relevant during implementation, noting if recent changes in those files need particular attention.

5.  **Formulate User Feedback / Clarification Points:**
    *   Clearly articulate any questions, ambiguities, or decisions that require user input before proceeding with implementation.
    *   This might include:
        *   Confirming a proposed solution approach, especially if influenced by recent changes.
        *   Clarifying ambiguous requirements.
        *   Seeking guidance on design choices.
        *   Confirming if recent changes impact the task as identified in Step 3, and discussing how to proceed.

6.  **Present Findings and Next Steps:**
    *   Summarize the task review findings, highlighting any impacts from recent Git history and areas for improvement or clarification.
    *   Present the proposed solution approach or refined implementation plan (if generated).
    *   Explicitly list the points requiring user feedback.
    *   Suggest the next logical step, which might be:
        *   User provides feedback/clarification.
        *   Updating the task file based on identified needs (if simple or authorized).
        *   Proceeding to `work-on-task` if the task is clear and ready.

## Output / Success Criteria

**Output:**
*   A summary of the task review, highlighting inconsistencies or areas for improvement, particularly in light of recent code changes.
*   A proposed solution approach or refined implementation plan for the task (if applicable), potentially adjusted based on recent work.
*   A clear list of questions or points requiring user feedback.
*   A suggestion for the next step in the workflow.

**Success Criteria:**
*   The task definition has been thoroughly reviewed against project context and recent changes in Git history.
*   Potential issues or ambiguities in the task definition, especially those arising from or impacted by recent work, are identified.
*   A viable approach to implementing the task is considered and potentially proposed, taking recent changes into account.
*   All points requiring user decision or clarification are explicitly stated.
*   The path forward for the task is clearly defined (e.g., requires feedback, ready for implementation).

## Reference Documentation

*   [Writing Effective Workflow Instructions Guide](../guides/writing-workflow-instructions.md) (How to structure workflows)
*   [Write Actionable Task Guide](../guides/write-actionable-task.md) (Format for task files)
*   [Project Management Guide](../guides/project-management.md) (Task status, dependencies, overall workflow)
*   [Load Environment Workflow Instruction](./load-env.md) (Provides necessary context including recent changes)
*   [What We Build](docs-project/what-do-we-build.md)
*   [Architecture](docs-project/architecture.md)
*   [Blueprint](docs-project/blueprint.md)
*   [Self-Reflect Workflow Instruction](./self-reflect.md) (Process analysis and identifying improvements)
*   [Version Control Guide](../guides/version-control.md) (For understanding Git history review)
