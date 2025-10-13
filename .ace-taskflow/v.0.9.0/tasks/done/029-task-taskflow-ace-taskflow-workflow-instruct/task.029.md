---
id: v.0.9.0+task.029
status: done
estimate: 8h
dependencies: []
sort: 996
---

# Update ace-taskflow workflow instructions to use ace-* tools

## Behavioral Specification

### User Experience

- **Input**: Developers and AI agents reading workflow instructions
- **Process**: Follow updated workflows with correct ace-* tool commands
- **Output**: Successful task execution using current mono-repo tools

### Expected Behavior

The ace-taskflow workflow instructions should reference only the current ace-* tools from the mono-repo architecture, removing all references to deprecated tools (task-manager, release-manager, capture-it, context, handbook) and ensuring consistent, working commands throughout.

### Interface Contract

The workflows can use tools to make work more efficient and accurate:

- `ace-taskflow task/tasks` for task management
- `ace-taskflow release/releases` for release management
- `ace-taskflow idea/ideas` for idea capture
- `ace-context` for context loading
- `ace-nav` for navigation and discovery
- Standard git commands instead of custom wrappers

### Success Criteria

- [ ] All deprecated tool references replaced with ace-* equivalents
- [ ] All workflow commands execute successfully
- [ ] Path references updated to correct locations
- [ ] Templates and embedded documents properly referenced
- [ ] No broken links or missing file references

## Objective

Migrate all workflow instructions in ace-taskflow/handbook/workflow-instructions/ from legacy dev-tools commands to the new ace-* mono-repo tool architecture, ensuring consistency and functionality.

## Implementation Plan

### Planning Steps

- [x] Map all deprecated tools to their ace-* replacements
  - task-manager → ace-taskflow task/tasks
  - release-manager → ace-taskflow release/releases
  - capture-it → ace-taskflow idea/ideas
  - context → ace-context
  - handbook → REMOVE (not used, drop all references)
  - git-commit → KEEP (still available)
  - git-mv → git mv (use standard git command)

- [x] Identify all affected workflow files (12 files total)
  - capture-idea.wf.md (already correct ✓)
  - draft-task.wf.md
  - work-on-task.wf.md
  - draft-release.wf.md
  - publish-release.wf.md
  - review-task.wf.md
  - plan-task.wf.md
  - replan-cascade-task.wf.md
  - create-reflection-note.wf.md
  - review-questions.wf.md
  - review-code.wf.md
  - create-task-based-on-plan.wf.md

- [x] Document required changes
  - Workflow loading: Use `ace-nav wfi://load-project-context`
  - Template references: Use `tmpl://` protocol (e.g., `tmpl://task-management/task.draft`)
  - Guide listing: Replace `tree` with `ace-nav guide://`
  - Submodules: Remove all references (no longer used)
  - Tool verification: Remove `handbook --verify-tools`

### Execution Steps

- [x] Update work-on-task.wf.md
  - Line 13: `dev-handbook/workflow-instructions/load-project-context.wf.md` → `ace-nav wfi://load-project-context`
  - Line 267: Remove `handbook --verify-tools git npm` entirely
  - Line 259: Update task filtering to use ace-taskflow commands

- [x] Update draft-task.wf.md
  - Line 17: `dev-handbook/workflow-instructions/load-project-context.wf.md` → `ace-nav wfi://load-project-context`
  - Line 106: `git-mv` → `git mv`
  - Line 111: Keep `git-commit` (still available)
  - Line 213: `<template path="dev-handbook/templates/task-management/task.draft.template.md">` → `<template path="tmpl://task-management/task.draft">`

- [x] Update plan-task.wf.md
  - Line 17: → `ace-nav wfi://load-project-context`
  - Line 455: → `<template path="tmpl://task-management/task.pending">`
  - Line 470: `tree -L 2 dev-handbook/guides` → `ace-nav guide://`
  - Line 553: → `<template path="tmpl://task-management/task.technical-approach">`
  - Line 573: → `<template path="tmpl://task-management/task.tool-selection-matrix">`
  - Line 591: → `<template path="tmpl://task-management/task.file-modification-checklist">`
  - Line 622: → `<template path="tmpl://task-management/task.risk-assessment">`

- [x] Update draft-release.wf.md
  - Line 14: Remove `dev-handbook/` directory reference
  - Line 19: → `ace-nav wfi://load-project-context`
  - Lines 195-197: Remove submodule check entirely
  - Line 208: Remove "Verify dev-handbook submodule" line
  - Line 457: → `<template path="tmpl://release-management/release-overview">`
  - Line 542: → `<template path="tmpl://task-management/task.pending">`
  - Line 557: `tree -L 2 dev-handbook/guides` → `ace-nav guide://`

- [x] Update publish-release.wf.md
  - Line 17: → `ace-nav wfi://load-project-context`
  - Lines 90-91: Keep `git-commit` (still available)
  - Line 327: → `<template path="tmpl://release-management/changelog">`

- [x] Update review-task.wf.md
  - Line 17: → `ace-nav wfi://load-project-context`

- [x] Update review-questions.wf.md
  - Line 17: → `ace-nav wfi://load-project-context`
  - Line 18: `dev-handbook/workflow-instructions/review-task.wf.md` → `ace-nav wfi://review-task`

- [x] Update review-code.wf.md
  - Line 49: Remove `dev-handbook` from presets
  - Line 52: Remove git submodule command for dev-handbook
  - Line 107: Remove dev-handbook commit reference
  - Line 111: Update presets list

- [x] Update create-reflection-note.wf.md
  - Line 21: → `ace-nav wfi://load-project-context`
  - Line 228: Update or embed template reference
  - Line 362: → `<template path="tmpl://release-reflections/retrospective">`

- [x] Update replan-cascade-task.wf.md
  - Line 90: → `<template path="tmpl://tasks/impact-note">`

- [x] Update create-task-based-on-plan.wf.md
  - Ensure all commands use ace-taskflow (already correct)

- [x] Test each updated workflow
  - Verify ace-nav commands work ✓
  - Check template references resolve ✓
  - Validate all commands execute ✓

## Acceptance Criteria

- [x] All 12 workflow files reviewed and updated
- [x] No references to deprecated tools remain
- [x] All ace-* commands use correct syntax
- [x] All file paths and templates properly referenced
- [x] Each workflow tested and functional

## References

- Current ace-* tools: ace-context, ace-nav, ace-taskflow, ace-test, ace-test-suite
- Deprecated tools: task-manager, release-manager, capture-it, context, handbook
- Migration from dev-tools to ace-* gem architecture (ADR-015)
