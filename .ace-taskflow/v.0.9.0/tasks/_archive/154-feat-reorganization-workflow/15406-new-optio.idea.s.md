---
id: v.0.9.0+task.154.06
status: done
priority: medium
estimate: 1h
dependencies:
  - v.0.9.0+task.154.05
parent: v.0.9.0+task.154
---

# Update TaskCommand move_task with new options

## Scope

Update the `move_task` method in TaskCommand to use `parse_move_args_with_optparse` and route to the appropriate TaskManager method based on `--child-of` value.

## Implementation Plan

### Execution Steps

- [x] Update `move_task` in TaskCommand to use `parse_move_args_with_optparse`
- [x] Route based on `--child-of` value:
  - `--child-of PARENT` → `demote_to_subtask`
  - `--child-of` (empty) → `promote_to_standalone`
  - `--child-of self` → `convert_to_orchestrator`
  - No `--child-of` → existing release move behavior
- [x] Support `--dry-run` for all operations
- [x] Update help text
- [x] Run tests: `ace-test test/commands/task_command_test.rb`

## Deliverables

- [x] Updated `move_task` method
- [x] Updated help text

## Acceptance Criteria

- [x] `ace-taskflow task move 019 --child-of 121` demotes to subtask
- [x] `ace-taskflow task move 121.01 --child-of` promotes to standalone
- [x] `ace-taskflow task move 019 --child-of self` converts to orchestrator
- [x] `ace-taskflow task move 019 backlog` still works (release move)
- [x] `--dry-run` works for all operations
- [x] All tests pass
