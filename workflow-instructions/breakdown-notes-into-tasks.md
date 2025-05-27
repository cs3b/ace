# Workflow Instruction: Breakdown Notes into Tasks

## Goal
To orchestrate the processing of various raw inputs (like PRDs, git diffs, backlog notes) by guiding the selection of an appropriate sub-workflow, and then to take the structured output from that sub-workflow, refine it, verify it with the user, and ultimately create formal, actionable task files.

## Input
*   The initial raw input material (e.g., a PRD file, git diff output, PR comments, unstructured backlog notes).
*   The type of this input, to help select the correct sub-workflow.
*   (Implicit) Current project context, including information about the current release if applicable.

## Process Steps

1.  **Select and Execute Input Processing Sub-Workflow:**
    *   Based on the nature of your initial raw input, navigate to the `breakdown-notes-into-tasks/` subdirectory.
    *   Choose and execute the appropriate sub-workflow from this directory (e.g., `from-prd.md` if your input is a Product Requirements Document, `from-diff.md` for a git diff, etc.).
    *   **Input to Sub-Workflow:** Your raw input material.
    *   **Output of Sub-Workflow:** A set of structured notes or analysis, specific to the input type.

2.  **Receive and Review Structured Input from Sub-Workflow:**
    *   Take the structured notes/analysis produced by the selected sub-workflow.
    *   Review this input to understand the items, their initial structuring, and any preliminary analysis performed by the sub-workflow.

3.  **Further Breakdown and Refinement (if necessary):**
    *   Analyze the structured input from the sub-workflow. Determine if any of the identified items need to be broken down into smaller, more distinct actionable units.
    *   For each unit (original or newly broken down), refine its objective, scope, and key details.
    *   Group related units if they logically form a single, cohesive piece of work for a task.

4.  **Finalize Structure for User Verification:**
    *   Organize the refined units into a clear, itemized list.
    *   Ensure each item in the list represents a potential task and includes its core elements (objective, key details, source references from the sub-workflow's output or original input).
    *   This initial structured list is prepared for user verification.

5.  **User Verification of Structured Tasks:**
    *   Before proceeding to formal task creation, present the structured list of potential tasks to the user for review.
    > VERIFY: Structured Task Review
    >   Type: User Feedback
    >   Prompt: Please review the following list of structured potential tasks. Do they accurately capture the actionable items from the input, are they logically grouped, and are the key details sufficient for creating formal tasks?
    >   Options: (Yes, proceed / No, needs revision)
    *   If the user indicates revisions are needed, return to step 3 (Further Breakdown and Refinement) with the user's feedback.

6.  **Formalize and Store Task(s):**
    *   Once the user approves the structured tasks, for each item:
        *   Formalize its structure according to the template and guidelines in the [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md). This includes populating sections such as Front-matter, Directory Audit, Scope of Work, Deliverables, Phases, Implementation Plan (with embedded tests where appropriate), and Acceptance Criteria.
    *   **Task Storage:**
        *   Determine the appropriate storage location for the formalized task file(s):
            *   **Current Release:** If a current release directory is identified (e.g., `docs-project/current/vX.Y.Z/`), create a `tasks/` subdirectory within it (if one doesn't already exist). Store the formalized task file(s) there.
            *   **Backlog:** If no specific current release is identified, or if the task is explicitly for the backlog, create a `tasks/` subdirectory within `docs-dev/backlog/` (e.g., `docs-dev/backlog/tasks/`) if it doesn't exist. Store the formalized task file(s) there.
        *   Ensure all necessary directories are created before attempting to save files.
    *   The output of this step is one or more formal task files, each adhering to the specified format and stored in the correct location.

## Output / Success Criteria

**Output:**
*   One or more user-verified, formalized task files, created according to the [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md).
*   Task files are stored in the appropriate project location (e.g., current release's `tasks/` folder or `docs-dev/backlog/tasks/`).

**Success Criteria:**
*   All relevant actionable items from the original input are identified, refined, and captured in formal tasks.
*   Tasks are logically grouped and broken down to an appropriate level of granularity.
*   Each created task file fully adheres to the structure, content guidelines, and formatting specified in the [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md).
*   Task files are correctly named and stored in the designated directory based on the current release context or backlog status.
*   The user has reviewed and approved the content and structure of the finalized task(s) before saving.

## Reference Documentation
*   [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md)
*   [Embedding Tests in AI Agent Workflows Guide](docs-dev/guides/embedding-tests-in-workflows.md)
*   Sub-workflow documents within the `breakdown-notes-into-tasks/` directory.