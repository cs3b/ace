---
id: v.0.9.0+task.154.04
status: done
priority: medium
estimate: 2h
dependencies:
  - v.0.9.0+task.154.03
parent: v.0.9.0+task.154
---

# Implement demote_to_subtask in TaskManager

## Scope

Add `demote_to_subtask` method to TaskManager that converts a standalone task to a subtask under a parent task.

## Implementation Plan

### Execution Steps

- [x] Add `demote_to_subtask` method to TaskManager
  - Find task by reference
  - Verify it's not already a subtask
  - Find parent task
  - Verify parent is an orchestrator
  - Get next subtask number
  - Move file to parent directory with new naming
  - Add parent field to frontmatter
  - Update ID to subtask format
  - Delete original task directory
  - Return new subtask reference
- [x] Add tests for `demote_to_subtask`
- [x] Run tests: `ace-test test/organisms/task_manager_test.rb`

## Deliverables

- [x] `demote_to_subtask` method in TaskManager
- [x] Test coverage

## Acceptance Criteria

- [x] `demote_to_subtask("019", "121")` converts task 019 to subtask of 121
- [x] New subtask gets next available number (e.g., 121.03)
- [x] Original task directory is removed
- [x] Parent field is added to frontmatter
- [x] All tests pass
