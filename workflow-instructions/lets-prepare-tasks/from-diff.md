# Prepare Tasks: From Git Diff

This document outlines the steps to analyze a Git diff (provided as a file, command output, or commit range) to generate structured analysis documents. This analysis serves as the foundation for creating actionable development tasks using the main `lets-prepare-tasks` workflow.

## Goal
To analyze Git diff content and produce structured analysis documents that serve as input for the `breakdown-notes-into-tasks` workflow, using an "Outside-In" approach (interfaces first, then implementation).

## Prerequisites
*   Git diff content available (file, command output, commit range).
*   A target release directory identified (e.g., `docs-project/current/vX.Y.Z/` or `docs-project/backlog/vA.B.C/`).

## Input
*   Source of the Git diff.
*   Path to the target release directory where analysis documents will be stored.

## Process Steps

1.  **Input Validation & Setup:**
    *   Confirm the source of the Git diff.
    *   Verify the target release directory exists. If not, confirm with the user if it should be created.
    *   Ensure standard subdirectories for analysis exist or create them: `{release_path}/backlog/high-level/` and `{release_path}/backlog/technical/`.

2.  **Diff Parsing and Grouping:**
    *   Parse the diff, identifying changes by file and type (add, modify, delete).
    *   Group related changes based on component, module, feature, or directory structure.

3.  **"Outside-In" Analysis:**
    *   **First Pass (Interfaces & High-Level):** Analyze changes to interfaces, public APIs, DSLs, configuration, high-level tests, and usage examples. Focus on the 'what' and 'why' of the changes.
    *   **Second Pass (Implementation Details):** Examine the internal logic, algorithms, private methods, and specific implementation choices. Focus on the 'how'.

4.  **Generate Layered Analysis Documents:**
    *   For each logical component or significant area of change identified:
        *   **Create High-Level Analysis (`{release_path}/backlog/high-level/{component}-analysis.md`):**
            *   Summarize the overall change.
            *   Detail impacts on interfaces, APIs, and user-facing aspects.
            *   Discuss design patterns, architectural considerations, and potential alternatives.
            *   Reference relevant parts of the diff.
        *   **Create Technical Analysis (`{release_path}/backlog/technical/{component}-details.md`):**
            *   Document specific code changes (using `diff` snippets).
            *   Provide observations on implementation choices, potential issues, and adherence to standards.
            *   Suggest concrete actions, potential refactorings, or improvement options (with pros/cons).
            *   Include specific file paths and line numbers.

5.  **Prepare Output for Breakdown Workflow:**
    *   With the analysis documents generated, structure the extracted information into a clear format suitable for the `breakdown-notes-into-tasks` workflow.
    *   Use the high-level and technical analysis as the primary input.

## Output
*   High-level analysis file(s) created in `{release_path}/backlog/high-level/`.
*   Technical analysis file(s) created in `{release_path}/backlog/technical/`.
*   These documents serve as structured input for the `breakdown-notes-into-tasks` workflow.
