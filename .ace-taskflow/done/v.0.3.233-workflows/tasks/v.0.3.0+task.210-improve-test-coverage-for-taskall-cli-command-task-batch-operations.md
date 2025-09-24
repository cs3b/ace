---
id: v.0.3.0+task.210
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Improve test coverage for TaskAll CLI command - task batch operations

## Objective

The `task-manager all` CLI command (`CodingAgentTools::Cli::Commands::Task::All`) currently lacks comprehensive test coverage. This command is responsible for listing all tasks with batch operations including filtering, sorting, dependency cycle detection, and various output formatting options. Adding proper test coverage will ensure the reliability of this critical task management feature.

## Scope of Work

- Create comprehensive unit tests for the `Task::All` CLI command
- Cover all CLI options and flags including filtering, sorting, verbose output, debugging, and cycle detection
- Test error handling, edge cases, and integration with underlying organisms
- Ensure test coverage follows existing patterns from similar CLI commands

### Deliverables

#### Create

- `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/spec/coding_agent_tools/cli/commands/task/all_spec.rb`

#### Modify

- N/A (new test file creation only)

#### Delete

- N/A

## Implementation Plan

### Planning Steps

* [x] Analyze existing Task::All command implementation and identify all features requiring test coverage
  > TEST: Feature Analysis Complete
  > Type: Pre-condition Check
  > Assert: All command options, methods, and code paths are identified for testing
  > Command: Manual review - verify comprehensive feature list created
* [x] Review existing test patterns from task/reschedule_spec.rb to follow consistent testing approach
* [x] Plan test scenarios covering success cases, error cases, and edge cases for all command options

### Execution Steps

- [x] Create spec file structure with basic setup following existing patterns from reschedule_spec.rb
  > TEST: Spec File Created
  > Type: Action Validation
  > Assert: Spec file exists with proper RSpec structure and basic test setup
  > Command: ls -la spec/coding_agent_tools/cli/commands/task/all_spec.rb
- [x] Implement tests for basic command execution without options (happy path)
- [x] Add tests for all CLI options: --debug, --show-cycles, --sort, --filter, --verbose, --release
- [x] Implement tests for error handling scenarios (task manager failures, invalid filters/sorts)
- [x] Add tests for edge cases (empty task lists, malformed tasks, exception handling)
- [x] Test output formatting and colorization functionality
- [x] Test integration with underlying organisms (TaskManager, TaskSortEngine, TaskFilterEngine, UnifiedTaskFormatter)
- [x] Run tests to verify all scenarios pass and achieve comprehensive coverage
  > TEST: Test Suite Passes
  > Type: Action Validation
  > Assert: All tests pass and provide comprehensive coverage of the Task::All command
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task/all_spec.rb -v

## Acceptance Criteria

- [x] AC 1: Complete spec file created at .ace/tools/spec/coding_agent_tools/cli/commands/task/all_spec.rb with comprehensive test coverage
- [x] AC 2: All CLI options and flags are tested including --debug, --show-cycles, --sort, --filter, --verbose, --release
- [x] AC 3: Error handling, edge cases, and integration scenarios are properly tested
- [x] AC 4: Test suite passes completely and follows established patterns from existing CLI command tests
- [x] AC 5: Code coverage for Task::All command is significantly improved through comprehensive unit testing

## Out of Scope

- ❌ Integration tests with real file system (unit tests with mocking only)
- ❌ Performance testing or benchmarking
- ❌ Modifying the Task::All command implementation itself
- ❌ Testing underlying organisms separately (focus on CLI command integration)

## References

- Existing implementation: `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/lib/coding_agent_tools/cli/commands/task/all.rb`
- Test pattern reference: `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/spec/coding_agent_tools/cli/commands/task/reschedule_spec.rb`
- CLI framework: dry-cli gem documentation