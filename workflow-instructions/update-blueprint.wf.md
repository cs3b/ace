# Update Project Blueprint Workflow Instruction

## Goal

Update the `dev-taskflow/blueprint.md` file with a concise summary of the current project structure, key files, and
links to core project documents. The blueprint provides essential orientation for developers and AI agents to quickly
understand the project organization.

## Definition

A "blueprint" in this context is a concise overview document that provides orientation to the project's structure and
organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand
how to navigate the codebase.

## Prerequisites

- Project structure should be relatively stable.
- Core documents (`what-do-we-build.md`, `architecture.md`) should exist and be reasonably up-to-date.

## Process Steps

1. **Identify Core Project Documents:** Verify `dev-taskflow/what-do-we-build.md` and `dev-taskflow/architecture.md`
   are present.

2. **Update High-Level Structure Overview:**
    - Include a brief description of main directories and their purpose.
    - Explain the relationship between key directories (e.g., `dev-handbook` vs. `dev-taskflow`).
    - Document any submodules if applicable.

3. **Analyze Project Structure:**
    - Review the overall project structure to identify essential directories and files.
    - Identify patterns for files that should be excluded from the overview.
    - If needed, update the `bin/tree` script configuration to reflect the appropriate filtering.

4. **Identify Key Project-Specific Files:**
    - List only the most critical files with brief descriptions explaining their importance.
    - Focus on files unique to this project and not already covered in the architecture documentation.
    - Examples: core configuration files, entry points, primary modules.

5. **Update Links:** Ensure the Markdown links to `what-do-we-build.md` and `architecture.md` are correct within `blueprint.md`.

6. **Save:** Save the updated `dev-taskflow/blueprint.md` file.

## Input

- User confirmation that core documents are ready.
- Optional: User-specified filters for the directory structure command.

## Output / Success Criteria

- `dev-taskflow/blueprint.md` file is created or updated.
- The file contains a clear definition of what constitutes a "blueprint" in this project.
- The file provides a concise overview of key directories and their purpose.
- The file includes instructions for viewing the complete directory structure.
- The file lists truly key project-specific files with descriptions.
- The file contains correct links to `what-do-we-build.md` and `architecture.md`.
- Information isn't duplicated from other project documentation.

## Usage Example

Invoke this workflow instruction when:

- Significant structural changes have occurred in the project.
- Before starting a major planning phase.
- If the context loaded by `load-env` seems inaccurate regarding project structure.

Example Invocation:
> "Run the `update-blueprint` workflow instruction to refresh the project blueprint."

## Future Enhancements

- A script could fully automate the blueprint generation process.
- Could be integrated into `load-env` to automatically refresh if changes are detected.
- Add visualization of project structure using ASCII diagrams or Mermaid charts.
