---
id: v.0.9.0+task.029
status: draft
priority: high
estimate: 8h
dependencies: []
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

- [ ] Map all deprecated tools to their ace-* replacements
  - task-manager → ace-taskflow task/tasks
  - release-manager → ace-taskflow release/releases
  - capture-it → ace-taskflow idea/ideas
  - context → ace-context
  - handbook → investigate replacement (possibly ace-nav)

  |=> need examples

  - git-commit/git-mv → standard git commands

  |=> keep the git-commit (we still have it), but we will use git mv instread of git mv

- [ ] Identify all affected workflow files (12 files total)
  - capture-idea.wf.md (already correct)
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

- [ ] Document command syntax changes
  - Old vs new command mappings
  - Option/flag differences
  - Output format changes

### Execution Steps

- [ ] Update draft-task.wf.md
  - Replace task-manager with ace-taskflow commands
  - Update git-mv/git-commit references
  - Fix template and context paths

- [ ] Update work-on-task.wf.md
  - Update release path commands
  - Replace task filtering commands
  - Remove handbook tool references

- [ ] Update draft-release.wf.md
  - Replace git-commit references
  - Update template paths
  - Fix dev-handbook references

- [ ] Update publish-release.wf.md
  - Replace git-commit --guided references
  - Update template paths
  - Fix context loading

- [ ] Update review-task.wf.md
  - Update context loading path
  - Replace any task-manager references

- [ ] Update plan-task.wf.md
  - Update context loading path
  - Fix all template paths
  - Replace task management commands

- [ ] Update replan-cascade-task.wf.md
  - Update template paths
  - Replace task management commands

- [ ] Update create-reflection-note.wf.md
  - Update context loading path
  - Fix template paths

- [ ] Update review-questions.wf.md
  - Update workflow path references
  - Fix context loading

- [ ] Update review-code.wf.md
  - Update context preset loading to use ace-context
  - Fix any dev-handbook references

- [ ] Update create-task-based-on-plan.wf.md
  - Ensure uses ace-taskflow task create
  - Update any old tool references

- [ ] Test each updated workflow
  - Verify commands execute
  - Check file paths exist
  - Validate template references

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
