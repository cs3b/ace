---
id: v.0.9.0+task.028
status: pending
priority: medium
estimate: 8h
dependencies: []
sort: 993
---

# Add comprehensive test coverage for ace-taskflow commands

## Description

Expand test coverage for ace-taskflow from current 27 tests to comprehensive coverage across all commands, organisms, molecules, and models. Current coverage is limited to 3 test files.

## Planning Steps

* [ ] Audit current test coverage gaps
* [ ] Design test structure and naming conventions
* [ ] Create test fixtures and helpers

## Execution Steps

### Priority 1: Command Tests
- [ ] Create `test/commands/task_command_test.rb`
  - [ ] Test next task, create, start, done, move operations
  - [ ] Test display modes (--path, --content)
- [ ] Create `test/commands/tasks_command_test.rb`
  - [ ] Test listing, filtering, statistics
  - [ ] Test reschedule functionality
- [ ] Create `test/commands/release_command_test.rb`
  - [ ] Test show active, create release
- [ ] Create `test/commands/releases_command_test.rb`
  - [ ] Test list all, statistics
- [ ] Create `test/commands/idea_command_test.rb`
  - [ ] Test create with new flags
  - [ ] Test show next/specific idea
- [ ] Create `test/commands/ideas_command_test.rb`
  - [ ] Test list all, filtering

### Priority 2: Organism Tests
- [ ] Create `test/organisms/task_manager_test.rb`
- [ ] Create `test/organisms/release_creator_test.rb`
- [ ] Create `test/organisms/task_scheduler_test.rb`

### Priority 3: Molecule Tests
- [ ] Create `test/molecules/task_loader_test.rb`
- [ ] Create `test/molecules/task_filter_test.rb`
- [ ] Create `test/molecules/release_resolver_test.rb`
- [ ] Create `test/molecules/idea_loader_test.rb`
- [ ] Create `test/molecules/config_loader_test.rb`
- [ ] Create `test/molecules/idea_enhancer_test.rb`

### Priority 4: Integration Tests
- [ ] Create `test/integration/task_workflow_test.rb`
  - [ ] Test complete task lifecycle
- [ ] Create `test/integration/release_workflow_test.rb`
  - [ ] Test release creation and management
- [ ] Create `test/integration/idea_workflow_test.rb`
  - [ ] Test idea capture to task conversion

## Acceptance Criteria

- [ ] Test coverage increases from 27 to 100+ tests
- [ ] All commands have corresponding test files
- [ ] Critical paths have integration tests
- [ ] Tests follow minitest conventions
- [ ] CI runs all tests successfully
- [ ] Coverage report shows >80% coverage

## Implementation Notes

Use existing test structure:
- Minitest framework (already in use)
- Test helper for common setup
- Fixtures for test data
- Mock filesystem operations where appropriate
