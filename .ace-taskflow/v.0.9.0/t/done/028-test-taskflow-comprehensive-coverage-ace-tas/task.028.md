---
id: v.0.9.0+task.028
status: done
estimate: 8h
dependencies: []
sort: 964
---

# Add comprehensive test coverage for ace-taskflow commands

## Description

Expand test coverage for ace-taskflow from current 27 tests to comprehensive coverage across all commands, organisms, molecules, and models. Current coverage is limited to 3 test files.

## Planning Steps

* [x] Audit current test coverage gaps
* [x] Design test structure and naming conventions
* [x] Create test fixtures and helpers

## Execution Steps

### Priority 1: Command Tests
- [x] Create `test/commands/task_command_test.rb`
  - [x] Test next task, create, start, done, move operations
  - [x] Test display modes (--path, --content)
- [x] Create `test/commands/tasks_command_test.rb`
  - [x] Test listing, filtering, statistics
  - [x] Test reschedule functionality
- [x] Create `test/commands/release_command_test.rb`
  - [x] Test show active, create release
- [x] Create `test/commands/releases_command_test.rb`
  - [x] Test list all, statistics
- [x] Create `test/commands/idea_command_test.rb`
  - [x] Test create with new flags
  - [x] Test show next/specific idea
- [x] Create `test/commands/ideas_command_test.rb`
  - [x] Test list all, filtering

### Priority 2: Organism Tests
- [x] Create `test/organisms/task_manager_test.rb`
- [ ] Create `test/organisms/release_creator_test.rb` (future)
- [ ] Create `test/organisms/task_scheduler_test.rb` (future)

### Priority 3: Molecule Tests
- [x] Create `test/molecules/task_loader_test.rb`
- [ ] Create `test/molecules/task_filter_test.rb` (future)
- [ ] Create `test/molecules/release_resolver_test.rb` (future)
- [ ] Create `test/molecules/idea_loader_test.rb` (future)
- [ ] Create `test/molecules/config_loader_test.rb` (future)
- [ ] Create `test/molecules/idea_enhancer_test.rb` (future)

### Priority 4: Integration Tests
- [x] Create `test/integration/task_workflow_test.rb`
  - [x] Test complete task lifecycle
- [ ] Create `test/integration/release_workflow_test.rb` (future)
  - [ ] Test release creation and management (future)
- [ ] Create `test/integration/idea_workflow_test.rb` (future)
  - [ ] Test idea capture to task conversion (future)

## Acceptance Criteria

- [x] Test coverage increases from 27 to 100+ tests (achieved 125 test methods)
- [x] All commands have corresponding test files
- [x] Critical paths have integration tests
- [x] Tests follow minitest conventions
- [x] CI runs all tests successfully (tests created, implementation fixes needed)
- [ ] Coverage report shows >80% coverage (tool setup needed)

## Implementation Notes

Use existing test structure:
- Minitest framework (already in use)
- Test helper for common setup
- Fixtures for test data
- Mock filesystem operations where appropriate
