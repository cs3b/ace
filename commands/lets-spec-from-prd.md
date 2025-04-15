# Product Requirements to Specification Command (lets-spec-from-prd)

This command processes a high-level Product Requirement Document (PRD) to establish the initial project structure, potentially spanning multiple releases, and generate foundational tasks within the unified task management system.

## Goal
Translate a broad product vision into a structured project plan, potentially involving multiple Major and Feature releases, setting the stage for iterative development.

## Process Steps

1.  **Input PRD**:
    *   Provide the path to the PRD file (e.g., `.md`, `.txt`, `.pdf`).
    *   Alternatively, paste the content directly.

2.  **Analyze PRD & High-Level Planning**:
    *   Parse the PRD to identify core product goals, key features, target audience, and high-level architecture concepts.
    *   **Propose Release Strategy**: Based on the scope, suggest a potential breakdown into major milestones or releases (e.g., v1.0.0 for MVP, v1.1.0 for Feature X, v1.2.0 for Feature Y). Allow user confirmation or modification.
    *   **Identify Foundational Elements**: Determine core architectural components, initial setup tasks, and essential documentation needed.

3.  **Create Initial Release Structures**:
    *   For each proposed release (starting with the first, e.g., v1.0.0), create the corresponding release directory structure in `docs-dev/project/backlog/`:
        ```
        docs-dev/project/backlog/v{version}-{codename}/
        ├── docs/
        ├── decisions/
        ├── tasks/
        ├── test-cases/
        ├── user-experience/
        ├── researches/
        ├── codemods/ # Likely for major versions involving migrations
        └── README.md   # Release overview (v.X.Y.Z-Codename.md format)
        ```
    *   Copy standard templates into relevant subdirectories.

4.  **Generate Foundational Tasks & Documentation**:
    *   For the *initial* release (e.g., v1.0.0):
        *   **Create Setup Tasks**: Generate structured task files (`.md`) in `{release_path}/tasks/` for initial project setup, core architecture implementation, basic tooling, etc. Use the standard format.
        *   **Create Initial ADRs**: Identify critical early architectural decisions prompted by the PRD and create placeholder ADR files in `decisions/`.
        *   **Generate `what-do-we-build.md`**: Populate `docs-dev/project/what-do-we-build.md` based on the PRD's vision and goals.
        *   **Generate `architecture.md`**: Create an initial `docs-dev/project/architecture.md` outlining the high-level components identified.
    *   For subsequent planned releases identified in Step 2, create their directories in `backlog/` with a basic `README.md` outlining their high-level goal, deferring detailed task generation.

5.  **Generate Overall Project Overview**:
    *   Update the main `docs-dev/project/README.md` (if it exists) or create one to summarize the multi-release plan derived from the PRD.

6.  **Communicate Results**:
    *   Report the proposed release plan.
    *   Report the number of initial tasks and documents created for the first release.
    *   Show the generated directory structure using `tree`.
    *   Indicate the location of the new release directories in `backlog/`.
    *   Suggest next steps (review initial tasks, refine architecture, start implementation of the first release).

## Success Criteria

*   Project overview documents (`what-do-we-build.md`, `architecture.md`) created/updated.
*   Initial release directory (e.g., v1.0.0) created in `docs-dev/project/backlog/` with standard subdirectories.
*   Directories for subsequent planned releases created in `backlog/` with basic READMEs.
*   Foundational tasks for the initial release generated as structured `.md` files in `tasks/`.
*   Placeholder ADRs created for key initial decisions.
*   Overall release strategy communicated.

## Prerequisites

*   A Product Requirement Document (PRD) available as a file or text.
*   Understanding of the [Project Management Guide](../guides/project-management.md).
*   Potentially requires `init-project` to have been run previously, or this command might incorporate parts of its functionality.

## Usage Example

```bash
# Example command invocation (conceptual)
lets-spec-from-prd --prd-path path/to/product-spec.md --initial-version v1.0.0 --name PhoenixProject

# Agent analyzes PRD, proposes release plan (e.g., v1.0, v1.1).
# Creates docs-dev/project/what-do-we-build.md, architecture.md.
# Creates docs-dev/project/backlog/v1.0.0-PhoenixProject/ with setup tasks, ADR placeholders.
# Creates docs-dev/project/backlog/v1.1.0-PhoenixProject-FeatureX/ with basic README.
# Reports results and locations.
```

## Notes
- This command initiates the project structure based on a high-level vision. Significant refinement of tasks and plans within each release will be necessary.
- It integrates principles from `guides/prepare-release/prepare-release-documentation.md` regarding artifacts needed for Major releases (like `codemods`, comprehensive docs).
- Consider if this command should *replace* or *complement* the `init-project` command. It seems more comprehensive for starting from a PRD.