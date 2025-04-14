---
id: 03
status: pending
priority: medium
dependencies: [01] # Depends on task system consolidation
---

# Task Title: Update Guides for Unified Workflow

## Description
Modify core guides (`.md` files in `docs-dev/guides/`) to reflect the unified task management system, simplified release process, and ensure overall consistency.

## Implementation Details / Notes
- **`guides/project-management.md`:** Update to describe the unified `project/{backlog,current,done}` structure. Detail the standard task file format (`.md` with frontmatter). Describe the integrated PR feedback workflow. Remove any conflicting information or references to `task-manager`. Incorporate the essence of the `transition-checklist.md` directly into this guide's workflow description.
- **`guides/README.md`:** Update overview to reflect the unified task management.
- **`guides/prepare-release/prepare-release-documentation.md`:** Clarify which directories/artifacts within the `v.x.x.x/` template are mandatory, recommended, or optional for different release types (Patch, Feature, Major). Ensure the version naming convention (e.g., `v.0.2.0` vs. `v.0.2.0-001`) is clarified and used consistently.
- **`guides/ship-release.md`:** Ensure it aligns with the simplified release documentation guidelines.
- **Template Consolidation:** Address the feedback regarding duplicated templates in `guides/` vs. `project/`. Decide on a single source for templates (likely `guides/`) and update references. Remove the duplicate `project/template/` directory if it exists (it wasn't explicitly listed in the initial file structure but was mentioned in feedback).
- **Incorporate Best Practices:** Review `docs-dev/project/backlog/v.x.x.x-docs-improvements/research/task-master-ai-hlo.md` and `windsurf-tips.md`. Integrate actionable advice into `guides/project-management.md` or the new `docs/unified-workflow-guide.md`. Specifically:
    - Emphasize "Planning Before Coding" / "Slow Vibe Coding".
    - Recommend using `tree` for showing structure.
    - Mention the value of structured task details.
    - Add notes about potential future enhancements like task generation from high-level specs or complexity analysis.
- **Consistency Audit:** Review other guides (`coding-standards`, `testing`, `documentation`, etc.) for any references to the old task management system or inconsistent terminology and update as needed.

## Acceptance Criteria / Test Strategy
- `guides/project-management.md` accurately reflects the unified workflow.
- `guides/prepare-release/prepare-release-documentation.md` clearly defines documentation requirements per release type.
- Template duplication is resolved.
- Guides are consistent with each other and with the updated commands.