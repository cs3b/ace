# v.0.2.0 [StreamlineWorkflow]

## Release Overview
This release focuses exclusively on improving the internal development workflow for collaborating with coding agents within the `docs-dev` environment. It aims to solidify a unified task management system by integrating valuable concepts learned from experiments (like Task Master) and research, simplifying release documentation, and ensuring consistency across commands and guides.

## Release Information
- **Type**: Feature (Process Improvement)
Date: 2025-04-15
- **Target Date**: YYYY-MM-DD
- **Release Date**: YYYY-MM-DD
- **Status**: Planning

## Goals &amp; Requirements

*(Incorporating feedback received 2025-04-15)*
### Primary Goals
- [x] **Goal 1: Solidify Unified Task Management** *(Partially Complete: ADR Accepted, Guides/Commands Updated for structure)*
  - **Success Metrics:** Single, clear task management system within `docs-dev/project/` using structured Markdown task files; `project/task-manager` directory removed; PR feedback processing directly creates/updates structured tasks in the unified system.
  - **Acceptance Criteria:** Commands (`lets-start`, `lets-spec-from-pr-comments`, `_review-kanban-board`) reference the unified system; Standard task file format defined and used; `project/task-manager` removed.
  - **Implementation Strategy:** Finalize standard Markdown task format (keeping initial format simple but flexible for future needs). Update `lets-spec-from-pr-comments` workflow to *exclusively* handle PR feedback -> patch release task generation. Note the need for separate commands (`lets-spec-from-prd`, `lets-spec-from-frd`) for generating specs from higher-level documents (which may result in feature/major releases). Update guides and commands. Remove `project/task-manager`.
  Status: In Progress
  - **Risks &amp; Mitigations:** Standard task format might become overly complex. Mitigation: Keep the initial format simple, allowing for future enhancements like subtasks or complexity fields if needed.

- [ ] **Goal 2: Simplify Release Documentation Process**
  - **Success Metrics:** Clear guidelines on which parts of the `prepare-release` template are needed for different release types (patch, feature, major).
  - **Acceptance Criteria:** Updated `prepare-release-documentation.md` guide (or its content integrated into new spec commands); structure is simplified but documentation remains comprehensive and clear for required release types (e.g., PR feedback mapping to Patch, FRD to Feature, PRD to Major).
  - **Implementation Strategy:** Review the existing template and guide, explicitly stating requirements per release type.
  - **Dependencies &amp; Status:** None. Status: Planning.
  - **Risks &amp; Mitigations:** Oversimplification might lead to missing important documentation for complex releases. Mitigation: Ensure major releases still mandate comprehensive documentation.

- [ ] **Goal 3: Ensure Workflow Consistency**
  - **Success Metrics:** Consistent terminology (e.g., `current` vs. `next`); aligned Kanban board references; commands consistently link to guides.
  - **Acceptance Criteria:** All references to task states (`backlog`, `current`, `done` - no `next`) are consistent; `_review-kanban-board.md` command works and points to the correct structure; commands avoid duplicating guide content.
  - **Implementation Strategy:** Audit all `commands/` and `guides/` files for consistency. Update as needed.
  - **Dependencies &amp; Status:** Relies on Goal 1 (Unified Task Management). Status: Planning.
  - **Risks &amp; Mitigations:** Missing some inconsistencies during the audit. Mitigation: Peer review of updated documents.
- [ ] **Goal 4: Integrate Workflow Best Practices from Research**
  - **Success Metrics:** Key principles like "planning before coding" and clear structure communication are explicitly mentioned in relevant guides. Consideration given to future enhancements like complexity analysis or task generation from high-level specs.
  - **Acceptance Criteria:** `guides/project-management.md` or `docs/unified-workflow-guide.md` emphasizes planning first; Recommendation to use `tree` command added; Task format allows for potential future complexity/subtask fields.
  - **Implementation Strategy:** Review `task-master-ai-hlo.md` and `windsurf-tips.md`. Extract actionable best practices and integrate them into the relevant guide updates (Task 03). Emphasize the feedback cycle (explore options -> select -> LLM feedback -> human feedback -> implement). Add notes about techniques/prompts for identifying missing requirements upfront. Add placeholder notes for future enhancements (e.g., defining a `lets-analyze-complexity` command for use during release prep).
  - **Dependencies &amp; Status:** None. Status: Planning.
  - **Risks &amp; Mitigations:** Incorporating too many conceptual ideas might bloat the current simple workflow. Mitigation: Focus on integrating immediately actionable advice and note future possibilities.

## Implementation Plan
Refer to tasks defined in `docs-dev/project/current/v.0.2.0/tasks/`. Key phases include:
1.  Decision Making (ADR for Task Management).
2.  Updating Core Guides (Project Management, Release Process).
3.  Updating Commands to align with new workflow.
4.  Cleanup/Archiving deprecated structures (`project/task-manager`).
5.  Validation of the new workflow.

## Quality Assurance
- **Process Validation:** Manually walk through common workflows (starting a task, processing PR feedback, preparing a release) using the updated documentation and commands.
- **Consistency Check:** Automated search or manual review for inconsistent terms or references.
- **Guide Review:** Ensure guides are clear, concise, and accurately reflect the streamlined process.

## Release Checklist
- [x] ADR for Unified Task Management finalized and accepted. *(Task 01)*
- [x] Task management system unified in `docs-dev/project/`. *(Task 01)*
- [x] `project/task-manager` deprecated/archived. *(Task 01 - Requires manual deletion check)*
- [x] Release documentation logic integrated into spec commands; `prepare-release-documentation.md` removed. *(Task 03)*
- [x] Commands (`load-env`, `lets-start`, `lets-spec-from-pr-comments`, `_review-kanban-board`, `self-reflect`, `lets-release`, new spec commands, `log-session`) updated/created for unified task system. *(Tasks 01, 02, 04)*
- [x] Guides (`project-management.md`, `README.md`, `ship-release.md`, `unified-workflow-guide.md`) updated and best practices integrated. *(Tasks 01, 03)*
- [x] Terminology and references (Kanban board, task states) made consistent across Commands and Guides. *(Tasks 01, 02, 03)*
- [ ] Validation test cases passed.
- [ ] CHANGELOG updated for v0.2.0 process changes.
- [ ] Release notes prepared outlining the workflow improvements.
