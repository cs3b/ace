# Create Release Overview Workflow Instruction

## Goal

Generate or update the main release overview document (e.g., `dev-taskflow/current/{release_dir}/README.md` or
`v.X.Y.Z-Codename.md`) summarizing the release goals, key changes, requirements, and plan.

## Prerequisites

- A release directory exists (e.g., in `dev-taskflow/current/`).
- Tasks for the release are defined or becoming clear.
- The release type (Patch, Feature, Major) is known.

## Process Steps

1. **Identify Target Release:** Confirm the release directory path (e.g., `dev-taskflow/current/v1.2.3-myfeature`).
2. **Gather Context:**
    - Review the tasks defined within the release (`{release_path}/tasks/*.md`).
    - Review relevant source documents (e.g., PRD, FRD, PR comments that initiated the release).
    - Review recent commit history if the release is already in progress.

- Draft/Update Overview Document: Create or edit the main `README.md` (or `v.X.Y.Z-*.md`) file for the release.
  Use the structure from the template (`dev-handbook/guides/draft-release/v.x.x.x/v.x.x.x-codename.md`) as a guide.
  Key sections include:
  - **Release Overview:** Brief summary.
  - **Release Information:** Type, Dates, Status.
  - **Goals & Requirements:** High-level objectives, metrics, acceptance criteria.
  - **Implementation Plan:** High-level phases, components, dependencies.
  - **Quality Assurance:** Testing strategy outline.
  - **Release Checklist:** Standard pre-release checks.

1. **Populate Content:** Fill in the sections based on the gathered context and the release scope.
2. **Review & Refine:** Ensure the overview is clear, accurate, and aligned with the release goals and tasks.
3. **Save:** Save the updated overview document.

## Input

- Release directory path (root-relative).
- Related tasks, source documents, and potentially commit history.

## Output / Success Criteria

- The main release overview document (`README.md` or `v.X.Y.Z-*.md`) within the specified release directory
  is created or updated.
- The document accurately reflects the release's goals, scope, and plan.
- Key sections (Overview, Info, Goals, Plan, QA, Checklist) are present and populated appropriately.

## Reference Documentation

- [Writing Workflow Instructions Guide](dev-handbook/guides/.meta/workflow-instructions-definition.g.md)
- [Release Overview Template](dev-handbook/guides/draft-release/v.x.x.x/v.x.x.x-codename.md)
- [Project Management Guide](dev-handbook/guides/project-management.g.md)
- [Release Process Guide](dev-handbook/guides/release-publish.g.md)
