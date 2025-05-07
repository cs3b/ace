# Workflow Instruction: Breakdown Notes into Tasks

## Goal
To orchestrate the processing of various raw inputs (like PRDs, git diffs, backlog notes) by guiding the selection of an appropriate sub-workflow, and then to take the structured output from that sub-workflow, refine it further, and prepare it for formal task creation.

## Input
*   The initial raw input material (e.g., a PRD file, git diff output, PR comments, unstructured backlog notes).
*   The type of this input, to help select the correct sub-workflow.

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

4.  **Finalize Structure for Task Creation:**
    *   Organize the refined units into a clear, itemized list.
    *   Ensure each item in the list represents a potential task and includes its core elements (objective, key details, source references from the sub-workflow's output or original input).
    *   This final structured list will serve as the direct input for the `write-actionable-task` workflow to create formal task files.

## Output / Success Criteria

**Output:**
*   A structured representation of potential tasks derived from unstructured notes, ready to be used as input for the `write-actionable-task` workflow.

**Success Criteria:**
*   All relevant actionable items from the notes are identified.
*   Information is grouped logically.
*   Key details for each potential task are extracted.
*   The output is clearly structured for easy task file creation.

## Reference Documentation
*   [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md)
