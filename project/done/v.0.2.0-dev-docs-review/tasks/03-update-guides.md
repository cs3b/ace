---
id: 03
status: done
priority: medium
dependencies: [01] # Depends on task system consolidation
---

# Task Title: Update Guides for Unified Workflow

## Description
Modify core guides (`.md` files in `docs-dev/guides/`) to reflect the unified task management system, simplified release process, and ensure overall consistency.

## Implementation Details / Notes
- **`guides/project-management.md`:** Update to describe the unified `project/{backlog,current,done}` structure. Detail the standard task file format (`.md` with frontmatter, including suggestion for Markdown checklists for subtasks). Describe the *three* primary specification workflows (PR Feedback, FRD, PRD) and how they map to the task system and release types. Remove any conflicting information or references to `task-manager`. Incorporate the essence of task transition checklists directly into this guide's workflow description.
- **`guides/README.md`:** Update overview to reflect the unified task management.
- **Integrate/Remove `guides/prepare-release/prepare-release-documentation.md`:** The core logic defining required artifacts per release type (Patch, Feature, Major) needs to be integrated into the process descriptions for the new `lets-spec-*` commands (Task 02). Once integrated, this specific guide file should be removed to avoid duplication. Ensure the standard `v.x.x.x` version naming is used consistently in examples.
- **`guides/ship-release.md`:** Ensure it aligns with the simplified release documentation guidelines.
- **Template Location:** Confirm all templates reside within `guides/prepare-release/v.x.x.x/` subdirectories. Remove any lingering references to `project/template/` (confirming it's already deleted).
- **Incorporate Best Practices:** Review `docs-dev/project/backlog/v.x.x.x-docs-improvements/research/task-master-ai-hlo.md` and `windsurf-tips.md`. Integrate actionable advice into `guides/project-management.md` or the new `docs/unified-workflow-guide.md`. Specifically:
    - Emphasize "Planning Before Coding" / "Slow Vibe Coding".
    - Recommend using `tree` for showing structure.
    - Mention the value of structured task details.
    - Add notes about potential future enhancements like task generation from high-level specs or complexity analysis.
    - **Consistency Audit:** Review other guides (`coding-standards`, `testing`, `documentation`, etc.) for any references to the old task management system or inconsistent terminology and update as needed. Double-check removal of `prepare-release-documentation.md` references once its content is integrated elsewhere.

## Acceptance Criteria / Test Strategy
- `guides/project-management.md` accurately reflects the unified workflow, including the standard task format (with subtask checklists) and the three spec workflows.
- Content from `guides/prepare-release/prepare-release-documentation.md` is successfully integrated into new spec command descriptions, and the original file is removed.
- `project/template/` references are confirmed removed.
- Guides are consistent with each other and with the updated commands.
- Actionable advice from research is integrated.
