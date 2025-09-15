---
id: v.0.3.0+task.197
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Improve test coverage for TaskFilterParser molecule - task filtering logic

## 0. Directory Audit ✅

_Command run:_

```bash
find .ace/tools/lib -name "*task_filter*" -type f
find .ace/tools/spec -name "*task_filter*" -type f
```

_Result excerpt:_

```
.ace/tools/lib/coding_agent_tools/molecules/taskflow_management/task_filter_parser.rb
.ace/tools/lib/coding_agent_tools/molecules/taskflow_management/task_filter_engine.rb
# No existing test files found for TaskFilterParser
```

## Objective

The TaskFilterParser molecule currently has no test coverage, which creates a risk for task filtering functionality that is critical to the task management system. This parser is responsible for parsing filter strings (like "status:pending", "priority:!low", "status:pending|in-progress") into structured FilterCriteria objects that can be applied to task collections.

The TaskFilterParser is used by TaskFilterEngine to filter tasks in the task management system, making it essential for commands like finding the next actionable task. Without proper test coverage, we cannot ensure the reliability of task filtering logic, especially for complex scenarios like OR conditions, negation, and edge cases.

## Scope of Work

- Create comprehensive unit tests for TaskFilterParser class and its FilterCriteria struct
- Test all public methods: parse_filter, parse_filters, validate_filters
- Test FilterCriteria matching logic including OR conditions, negation, and attribute access
- Test edge cases: invalid input, empty values, nil handling, malformed filter strings
- Test integration with task data objects and frontmatter attribute access
- Ensure 100% test coverage for the task filtering logic

### Deliverables

#### Create

- .ace/tools/spec/coding_agent_tools/molecules/taskflow_management/task_filter_parser_spec.rb

#### Modify

- None required

#### Delete

- None required

## Phases

1. Audit - Analyze existing TaskFilterParser implementation and identify test scenarios
2. Design - Create comprehensive test structure covering all methods and edge cases
3. Implement - Write unit tests with proper RSpec patterns following project conventions
4. Validate - Ensure all tests pass and provide complete coverage

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [x] Analyze TaskFilterParser implementation to understand all methods and functionality
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All public methods, FilterCriteria behavior, and edge cases are identified
  > Command: ruby -e "require './.ace/tools/lib/coding_agent_tools/molecules/taskflow_management/task_filter_parser'; puts CodingAgentTools::Modules::TaskflowManagement::TaskFilterParser.methods(false)"
- [x] Examine existing test patterns in the project to follow conventions
- [x] Design test structure covering all parsing scenarios, matching logic, and validation
- [x] Identify integration points with TaskFilterEngine and task data structures

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [x] Create the test file with proper RSpec structure and required dependencies
  > TEST: Test File Creation
  > Type: Action Validation
  > Assert: Test file exists with proper RSpec structure and can be loaded
  > Command: ruby -e "require './.ace/tools/spec/coding_agent_tools/molecules/taskflow_management/task_filter_parser_spec.rb'; puts 'Test file loads successfully'"
- [x] Implement tests for FilterCriteria struct matching logic
  > TEST: FilterCriteria Tests
  > Type: Action Validation
  > Assert: All FilterCriteria matching scenarios are tested including OR conditions, negation, and attribute access
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_filter_parser_spec.rb -t "FilterCriteria"
- [x] Implement tests for parse_filter method covering all valid and invalid scenarios
  > TEST: Parse Filter Tests
  > Type: Action Validation
  > Assert: All filter parsing scenarios are tested including edge cases and malformed input
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_filter_parser_spec.rb -t "parse_filter"
- [x] Implement tests for parse_filters method handling arrays of filter strings
  > TEST: Parse Filters Tests
  > Type: Action Validation
  > Assert: Batch parsing scenarios are tested including mixed valid/invalid filters
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_filter_parser_spec.rb -t "parse_filters"
- [x] Implement tests for validate_filters method checking known attributes
  > TEST: Validate Filters Tests
  > Type: Action Validation
  > Assert: Filter validation scenarios are tested including valid/invalid attributes
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_filter_parser_spec.rb -t "validate_filters"
- [x] Run complete test suite to ensure all tests pass and provide coverage
  > TEST: Complete Test Suite
  > Type: Action Validation
  > Assert: All TaskFilterParser tests pass and provide comprehensive coverage
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_filter_parser_spec.rb

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [x] AC 1: TaskFilterParser test file created with comprehensive test coverage
- [x] AC 2: All public methods (parse_filter, parse_filters, validate_filters) have complete test coverage
- [x] AC 3: FilterCriteria matching logic is thoroughly tested including OR conditions, negation, and attribute access
- [x] AC 4: All edge cases are tested including nil inputs, empty strings, malformed filters, and invalid attributes
- [x] AC 5: All automated tests in the Implementation Plan pass
- [x] AC 6: Tests follow project RSpec conventions and integrate properly with existing test suite

## Out of Scope

- ❌ Testing TaskFilterEngine integration (covered separately)
- ❌ Modifying TaskFilterParser implementation (only testing existing code)
- ❌ Performance testing or optimization
- ❌ Adding new features to TaskFilterParser
- ❌ Testing CLI commands that use TaskFilterParser (covered in CLI tests)

## References

- TaskFilterParser implementation: `.ace/tools/lib/coding_agent_tools/molecules/taskflow_management/task_filter_parser.rb`
- TaskFilterEngine usage: `.ace/tools/lib/coding_agent_tools/molecules/taskflow_management/task_filter_engine.rb`
- Existing test patterns: `.ace/tools/spec/coding_agent_tools/molecules/taskflow_management/task_sort_engine_spec.rb`
- RSpec testing conventions: `.ace/tools/spec/support/TESTING_CONVENTIONS.md`
