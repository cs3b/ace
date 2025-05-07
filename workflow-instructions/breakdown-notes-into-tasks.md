# Workflow Instruction: Breakdown Notes into Tasks

## Goal
To process unstructured notes or miscellaneous information, identify actionable items, and structure them into a format suitable for creating formal task files.

## Input
*   One or more sources of unstructured notes (e.g., `notes.txt`, meeting minutes, feedback).

## Process Steps

1.  **Consolidate Notes:** Gather information from various sources into a single, temporary notes document if necessary.
2.  **Review and Identify Actionable Items:** Read through the notes, highlighting or extracting distinct points that represent potential tasks, decisions, or documentation updates.
3.  **Group Related Information:** Cluster related notes or items together to form logical task units.
4.  **Extract Key Information:** For each potential task unit, identify the core objective, brief description, and any relevant context or details mentioned in the notes.
5.  **Structure for Task Creation:** Format the extracted information clearly, perhaps as a simple list, where each item represents a potential task with its core elements (objective, key details, source reference). This structured output will serve as input for the `write-actionable-task` workflow.

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
    *   Report the number of tasks created and their location(s).
    *   List any new release directories created.
    *   Mention any core project documents updated.
    *   Suggest next steps (e.g., review created tasks, begin implementation).

## Output / Success Criteria

**Output:**
*   Structured task files (`.md`) created in the appropriate release `tasks/` directories.
*   Release directory structures created or updated in `docs-project/backlog/` or `docs-project/current/`.
*   Release `README.md` files updated.
*   Potentially updated core project documents (`what-do-we-build.md`, `architecture.md`, `docs-project/README.md`).
*   Placeholder ADR files created if needed.
*   Confirmation message summarizing actions taken.

**Success Criteria:**
*   All requirements from the input analysis are transformed into tasks or artifacts.
*   Tasks are correctly formatted and placed in the designated release directories.
*   Directory structures are created according to standards.
*   Relevant documentation is updated accurately.

## Reference Documentation
*   [Project Management Guide](docs-dev/guides/project-management.md)
*   [Strategic Planning Guide](docs-dev/guides/strategic-planning-guide.md)
*   [Roadmap](docs-project/roadmap.md)
*   [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md)
*   Individual analysis workflows linked in Phase 1 above.
