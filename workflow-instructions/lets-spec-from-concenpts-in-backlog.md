# Refine Concepts in Backlog Workflow Instruction (lets-spec-from-concepts-in-backlog)

## Goal
Transform vague concept notes (files starting with `xx-` within a specific release's `backlog/` directory) into well-defined, actionable backlog items (standard `.md` files) in the *same* `backlog/` directory. This is achieved by analyzing the concepts, project context, and related research, then asking clarifying questions to the user before generating the concrete items. This workflow prepares items for the `lets-spec-from-release-backlog.md` workflow.

## Prerequisites
*   A target release directory exists (e.g., `docs-project/backlog/vX.Y.Z-some-feature/`).
*   The release directory contains a `backlog/` subfolder.
*   One or more vague concept files exist within `{release_path}/backlog/` with names matching the pattern `xx-*.md` (e.g., `xx-better-error-handling.md`).
*   Optionally, a `{release_path}/researches/` subfolder containing relevant research documents exists.
*   The project context should be loaded, ideally by running `docs-dev/workflow-instructions/load-env.md` first or ensuring equivalent information is available.
*   Familiarity with the standard task/backlog item format defined in `docs-dev/guides/project-management.md`.

## Input
*   Path to the target release directory containing the `backlog/` folder with `xx-*.md` concept files (e.g., `docs-project/backlog/v0.5.0-new-reporting-feature/`).

## Process Steps

1.  **Load Context & Identify Target:**
    *   Ensure project context is available (files, structure, standards - see `docs-dev/workflow-instructions/load-env.md`).
    *   Confirm the target `release_path` provided by the user (e.g., `docs-project/backlog/v0.5.0-new-reporting-feature/`). Verify the existence of the `backlog/` subdirectory.

2.  **Identify Concept Files:**
    *   Scan the `{release_path}/backlog/` directory.
    *   List all files matching the pattern `xx-*.md`. If none are found, inform the user and stop.

3.  **Gather Information:**
    *   For each identified `xx-*.md` file, read its content.
    *   If a `{release_path}/researches/` directory exists, read the content of all files within it.

4.  **Generate Clarification Questions:**
    *   For each `xx-*.md` concept file:
        *   Analyze its content in conjunction with the project context and any information from the `researches/` directory.
        *   Generate a set of specific, targeted questions designed to eliminate ambiguity. Focus on:
            *   **Concrete Goal:** What is the primary, measurable objective?
            *   **Key Requirements:** What must the solution do? What are the essential features?
            *   **Acceptance Criteria:** How will we know this is done and successful?
            *   **Scope:** What is explicitly in or out of scope?
            *   **Dependencies:** Does this rely on other work? Will other work rely on this?
            *   **Value/Motivation:** Why is this concept important? What problem does it solve?
    *   Present these questions clearly grouped by the source `xx-*.md` file.

5.  **Elicit User Feedback:**
    *   Present the generated questions to the user.
    *   Wait for and record the user's answers, ensuring they provide sufficient detail to make the concept concrete.

6.  **Generate Concrete Backlog Items:**
    *   For each original `xx-*.md` concept file, use its content, the gathered research, the project context, and crucially, the user's answers to the clarification questions to create a *new* backlog item file.
    *   **Naming:** Create the new file in `{release_path}/backlog/` using the standard naming convention (e.g., `{scope}-{action}-{target}.md`). Avoid using the `xx-` prefix. Consult `docs-dev/guides/project-management.md` for naming conventions suitable for backlog items (they might not need sequence numbers at this stage).
    *   **Content:** Structure the new `.md` file according to the standard task/backlog item format defined in `docs-dev/guides/project-management.md`:
        *   Include appropriate Frontmatter (e.g., `status: backlog`, `priority: medium`, `dependencies: []`).
        *   Write a clear, action-oriented title (`# Backlog Item: ...`).
        *   Provide a detailed `## Description` based on the clarified understanding.
        *   Add initial thoughts on `## Implementation Details / Notes`, potentially including constraints or ideas discussed during clarification.
        *   Define specific `## Acceptance Criteria / Test Strategy` based on the user's feedback.
        *   Include a note referencing the original `xx-*.md` file for traceability (e.g., "Refines concept from `xx-original-concept-name.md`").

7.  **Handle Original Concept Files (User Confirmation Required):**
    *   **Do not delete automatically.**
    *   After successfully creating the new concrete backlog item(s) derived from an `xx-*.md` file, ask the user if the original `xx-*.md` file should be:
        *   Deleted.
        *   Moved to an archive subfolder (e.g., `{release_path}/backlog/archive/`).
        *   Left as is.
    *   Perform the action only upon explicit user confirmation.

8.  **Communicate Results:**
    *   Report the number of vague concepts processed (`xx-*.md` files found).
    *   Report the number of concrete backlog items created (new `.md` files).
    *   List the full paths of the newly created backlog item files.
    *   Confirm the action taken regarding the original `xx-*.md` files (deleted, archived, or kept).
    *   Suggest the next step, which might be running `docs-dev/workflow-instructions/lets-spec-from-release-backlog.md` on the release backlog.

## Output / Success Criteria

**Output:**
*   New, well-defined backlog item files (`.md`) are created in the `{release_path}/backlog/` directory.
*   These new files follow the standard project format and naming conventions for backlog items.
*   The content of the new files reflects the clarified understanding derived from user feedback.
*   Original `xx-*.md` files are handled according to user confirmation (deleted, archived, or kept).
*   A summary message reports the actions taken and lists the new files.

**Success Criteria:**
*   All `xx-*.md` files in the specified directory were identified and processed.
*   Relevant project context and research materials were considered.
*   Generated clarification questions were pertinent and effectively addressed ambiguities.
*   User feedback was successfully incorporated into the new backlog items.
*   New backlog items are created in the correct location, follow the standard format, and contain concrete goals, requirements, and acceptance criteria.
*   Original concept files are handled exactly as confirmed by the user.
*   The process prepares the backlog items for potential further refinement or inclusion in a release plan via `lets-spec-from-release-backlog.md`.

## Reference Documentation
*   [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
*   [Project Management Guide](docs-dev/guides/project-management.md) (Defines standard task/backlog item format and naming)
*   [Load Environment Workflow Instruction](docs-dev/workflow-instructions/load-env.md) (For context gathering)
*   [Specification from Release Backlog Workflow Instruction](docs-dev/workflow-instructions/lets-spec-from-release-backlog.md) (Likely the next step after this workflow)

## Usage Example

**User:** "Please refine the vague concepts in `docs-project/backlog/v0.5.0-new-reporting-feature/` using the `lets-spec-from-concepts-in-backlog` workflow instruction."

**(Agent performs steps 1-4: Loads context, identifies `xx-*.md` files, reads research, generates questions)**

**Agent:** "Okay, I've found two concept files: `xx-better-reporting.md` and `xx-data-export.md`. I've also reviewed the research notes in `researches/`. To refine these, I need some clarification:

**For `xx-better-reporting.md`:**
*   What specific metrics should the 'better' report include?
*   What's the target audience for this report?
*   How will we measure if the report is 'better' (e.g., faster load time, specific data points included)?
*   Is visualizing the data part of this scope?

**For `xx-data-export.md`:**
*   What specific data needs to be exported?
*   What format(s) should the export support (e.g., CSV, JSON)?
*   Are there any security or privacy considerations for the exported data?
*   Who should be able to trigger this export?"

**User:** (Provides detailed answers to the agent's questions)

**(Agent performs steps 6-7: Generates new files based on answers, asks about original files)**

**Agent:** "Thanks! Based on your answers, I've created the following concrete backlog items:
*   `docs-project/backlog/v0.5.0-new-reporting-feature/backlog/reporting-add-kpi-dashboard.md`
*   `docs-project/backlog/v0.5.0-new-reporting-feature/backlog/export-add-csv-user-data.md`

Should I delete the original `xx-better-reporting.md` and `xx-data-export.md` files now?"

**User:** "Yes, please delete them."

**(Agent performs step 7 action and step 8)**

**Agent:**
```
✅ Processed 2 concepts, created 2 concrete backlog items.
✅ New items:
   - docs-project/backlog/v0.5.0-new-reporting-feature/backlog/reporting-add-kpi-dashboard.md
   - docs-project/backlog/v0.5.0-new-reporting-feature/backlog/export-add-csv-user-data.md
✅ Original concept files (xx-*.md) have been deleted as requested.
Consider running 'lets-spec-from-release-backlog' on this directory next to further detail these items.
```
