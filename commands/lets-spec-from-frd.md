# Feature Requirements to Specification Command (lets-spec-from-frd)

This command processes a Feature Requirement Document (FRD) to set up the necessary structure and initial tasks for a new feature release within the unified task management system.

## Goal
Translate a higher-level feature description into a planned release structure with actionable, traceable tasks. This typically results in a *Feature* release (Minor version bump).

## Process Steps

1.  **Input FRD**:
    *   Provide the path to the FRD file (e.g., `.md`, `.txt`, `.pdf`).
    *   Alternatively, paste the content directly.

2.  **Determine Release Version & Path**:
    *   Check the project's current version (e.g., from `lib/aira/version.rb` or Git tags).
    *   Propose the next *Minor* version (e.g., v1.2.3 -> v1.3.0). Allow user override.
    *   Create the release directory structure, typically starting in `docs-dev/project/backlog/`:
        ```
        docs-dev/project/backlog/v{new_version}-{feature-name}/
        ├── docs/
        ├── decisions/
        ├── tasks/
        ├── test-cases/
        ├── user-experience/
        ├── researches/ # Optional, if significant investigation needed
        └── README.md   # Release overview (v.X.Y.Z-FeatureName.md format)
        ```
    *   Copy standard templates into relevant subdirectories (e.g., `decisions/_template.md`, `tasks/_template.md`).

3.  **Analyze FRD & Generate Tasks**:
    *   Parse the FRD content to identify key requirements, user stories, and acceptance criteria.
    *   Break down requirements into logical, implementable tasks.
    *   **Create Task Files**: Generate structured task files (`.md`) within the `{release_path}/tasks/` directory using the standard format (see `guides/project-management.md`).
        *   Populate frontmatter (`id`, `status: pending`, `priority`, `dependencies`, `comment_ids: []`). Use sequence prefixes for `id`.
        *   Fill in `# Task Title`, `## Description`, `## Implementation Details / Notes`, and `## Acceptance Criteria / Test Strategy` based on FRD analysis.
    *   **Determine Dependencies**: Analyze relationships between generated tasks and populate the `dependencies` field in the frontmatter.
    *   **Identify Decisions/Research**: Flag areas requiring architectural decisions (prompting ADR creation in `decisions/`) or further research (creating placeholder files in `researches/`).

4.  **Generate Release Overview (`README.md`)**:
    *   Create the main release overview file (`README.md` or `v.X.Y.Z-FeatureName.md`).
    *   Summarize the feature goals based on the FRD.
    *   List the high-level tasks generated.
    *   Include links to the FRD and any initial ADRs or research items.

5.  **Communicate Results**:
    *   Report the number of tasks created.
    *   Show the generated directory structure using `tree`.
    *   Indicate the location of the new release directory (usually in `backlog/`).
    *   Suggest next steps (review tasks, refine plan, move to `current/` when ready).

## Success Criteria

*   New release directory created in `docs-dev/project/backlog/` (or `current/` if specified).
*   Standard subdirectories (`docs`, `decisions`, `tasks`, etc.) are created.
*   FRD content successfully analyzed.
*   Structured task files (`.md`) generated in `{release_path}/tasks/` following the standard format.
*   Task dependencies identified and documented in frontmatter.
*   Release overview `README.md` created with summary and task list.
*   Potential ADRs or research needs are flagged.

## Prerequisites

*   A Feature Requirement Document (FRD) available as a file or text.
*   Understanding of the [Project Management Guide](../guides/project-management.md) and standard task format.
*   Knowledge of the current project version.

## Usage Example

```bash
# Example command invocation (conceptual)
lets-spec-from-frd --frd-path path/to/my-feature.md --version v1.3.0 --name CoolNewFeature

# Agent creates structure in docs-dev/project/backlog/v1.3.0-CoolNewFeature/
# Populates tasks/, decisions/, etc., based on FRD analysis.
# Generates README.md overview.
# Reports results and location.
```

## Notes
- This command focuses on *generating the initial plan*. Tasks will likely require refinement before and during implementation.
- It integrates the principles previously found in `guides/prepare-release/prepare-release-documentation.md` regarding the artifacts needed for a Feature release.