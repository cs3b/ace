---
id: v.0.9.0+task.154.05
status: done
priority: medium
estimate: 2h
dependencies:
  - v.0.9.0+task.154.04
parent: v.0.9.0+task.154
---

# Implement convert_to_orchestrator in TaskManager

## Scope

Add `convert_to_orchestrator` method to TaskManager that converts a standalone task to an orchestrator by renaming its file to the `.00-orchestrator.s.md` pattern.

## Implementation Plan

### Execution Steps

- [x] Add `convert_to_orchestrator` method to TaskManager
  - Find task by reference
  - Verify it's not already an orchestrator
  - Verify it's not a subtask
  - Rename task file to `.00-orchestrator.s.md` pattern
  - Return success with new path
- [x] Add tests for `convert_to_orchestrator`
- [x] Run tests: `ace-test test/organisms/task_manager_test.rb`

## Deliverables

- [x] `convert_to_orchestrator` method in TaskManager
- [x] Test coverage

## Acceptance Criteria

- [x] `convert_to_orchestrator("019")` renames file to `019.00-*.s.md` pattern
- [x] Error if task is already an orchestrator
- [x] Error if task is a subtask
- [x] All tests pass
