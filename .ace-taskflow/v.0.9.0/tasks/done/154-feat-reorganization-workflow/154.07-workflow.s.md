---
id: v.0.9.0+task.154.07
status: done
priority: medium
estimate: 1h
dependencies:
  - v.0.9.0+task.154.06
parent: v.0.9.0+task.154
---

# Create reorganize-tasks.wf.md workflow and Claude command

## Scope

Create workflow instruction file documenting task reorganization commands and optionally a Claude slash command for common reorganization operations.

## Implementation Plan

### Execution Steps

- [x] Create `reorganize-tasks.wf.md` workflow instruction file
- [x] Document all reorganization operations: promote, demote, convert
- [x] Include examples and use cases
- [x] Optionally create Claude slash command (if needed)

## Deliverables

- [x] `ace-taskflow/handbook/workflow-instructions/reorganize-tasks.wf.md`

## Acceptance Criteria

- [x] Workflow file created with clear instructions
- [x] All three operations documented with examples
- [x] Dry-run option documented
