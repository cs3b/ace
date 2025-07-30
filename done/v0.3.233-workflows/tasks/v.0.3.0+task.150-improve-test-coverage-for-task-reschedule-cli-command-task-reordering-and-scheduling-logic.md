---
id: v.0.3.0+task.150
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Improve test coverage for Task Reschedule CLI command - task reordering and scheduling logic

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Implement comprehensive test coverage for Task::Reschedule CLI command focusing on task reordering logic, scheduling algorithms, and task management integration. Address uncovered line ranges from coverage analysis: lines 37-42, 45-46, 49-53, 56-60, 63-65, 67-68, 70-75, and all method implementations (0% coverage).

## Prerequisites

* Read the dev-tools technical architecture guide: `dev-tools/docs/architecture-tools.md`
* Understanding of ATOM architecture pattern (Atoms, Molecules, Organisms, Ecosystems)
* Familiarity with Ruby/RSpec testing patterns and dry-cli command testing
* Understanding of task management and scheduling algorithms

## Scope of Work

- Add missing test scenarios for uncovered methods in Task::Reschedule CLI command
- Implement edge case testing for task reordering and scheduling logic
- Add error condition testing for invalid task IDs and file operations
- Follow Ruby/RSpec testing standards and CLI testing patterns
- Ensure meaningful test coverage beyond just exercising code

### Deliverables

#### Create

- spec/coding_agent_tools/cli/commands/task/reschedule_spec.rb

#### Modify

- None (new test file)

#### Delete

- None

## Implementation Plan

### Planning Steps
* [x] Analyze source code for Task::Reschedule CLI command (lib/coding_agent_tools/cli/commands/task/reschedule.rb)
* [x] Review existing CLI test patterns in the codebase
* [x] Design test scenarios for uncovered methods: call, resolve_tasks, find_task, reschedule_add_next, reschedule_add_at_end, get_task_sort_value, parse_task_sequential_number, update_task_sort, handle_error, error_output
* [x] Plan edge case scenarios and error conditions for task rescheduling

### Execution Steps
- [x] Implement happy path tests for call method with different reschedule modes
- [x] Add edge case tests for resolve_tasks with invalid task IDs
- [x] Implement error condition tests for find_task with non-existent tasks
- [x] Add integration tests for reschedule_add_next and reschedule_add_at_end
- [x] Test get_task_sort_value and parse_task_sequential_number with edge cases
- [x] Add boundary condition tests for update_task_sort with file operations
- [x] Test error handling with handle_error and error_output methods
- [x] Implement edge cases for empty task lists and invalid options
- [x] Test integration with TaskManager organism
- [x] Verify test isolation and cleanup procedures
- [x] Run full test suite to ensure no regressions
  > TEST: Verify test suite passes
  > Type: Regression Check
  > Assert: All existing tests continue to pass after adding new tests
  > Command: cd dev-tools && bin/test

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [x] All uncovered methods have meaningful test scenarios
- [x] Edge cases and error conditions are properly tested
- [x] Tests follow RSpec best practices and dry-cli testing patterns
- [x] CLI argument parsing and validation edge cases are covered
- [x] Test execution completes without errors
- [x] Coverage analysis shows improved meaningful coverage for Task::Reschedule

## Out of Scope

- ❌ Testing with actual task files (use controlled test fixtures)
- ❌ Performance benchmarking (focus on correctness)
- ❌ Integration with real release management workflows

## Test Scenarios

### Uncovered Methods
- call (lines 37-42, 45-46, 49-53, 56-60, 63-65, 67-68, 70-75)
- resolve_tasks (lines 79-80, 82, 84-90, 92-93)
- find_task (lines 95, 97-98, 101-104, 107-108, 111-112)
- reschedule_add_next (lines 114, 116, 119, 122, 124-129)
- reschedule_add_at_end (lines 131, 133, 136, 139, 141-146)
- get_task_sort_value (lines 148-154)
- parse_task_sequential_number (lines 156-160)
- update_task_sort (lines 162, 164, 167-169, 172, 174-175, 177-178, 181-186)
- handle_error (lines 188-197)
- error_output (lines 199-201)

### Edge Cases to Test
- [ ] Task resolution (invalid IDs, file paths, mixed formats)
- [ ] Scheduling modes (add_next vs add_at_end conflicts, precedence)
- [ ] Sort value parsing (edge numbers, invalid formats, overflow)
- [ ] File operations (permission errors, corrupted files, concurrent access)
- [ ] Error handling (various exception types, debug modes)

### Integration Scenarios
- [ ] CLI command execution with different task input formats
- [ ] TaskManager integration for task discovery and updates
- [ ] Error propagation and user-friendly error messages

## References
- Coverage analysis: coverage_analysis/coverage_analysis.json
- Testing standards: dev-tools/docs/development/guides/testing-with-vcr.md
- ATOM architecture: docs/architecture-tools.md
- Source file: lib/coding_agent_tools/cli/commands/task/reschedule.rb
- CLI testing patterns: existing spec/coding_agent_tools/cli/ files
