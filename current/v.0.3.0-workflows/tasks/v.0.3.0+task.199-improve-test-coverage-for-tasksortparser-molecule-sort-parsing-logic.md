---
id: v.0.3.0+task.199
status: in-progress
priority: medium
estimate: 2h
dependencies: []
---

# Improve test coverage for TaskSortParser molecule - sort parsing logic

## Objective

Create comprehensive test coverage for the TaskSortParser molecule's sort parsing logic. Currently, this molecule is only tested indirectly through TaskSortEngine tests, but has no dedicated unit tests for its core parsing functionality. This includes testing the parsing of sort strings, validation logic, and SortCriteria behavior.

## Scope of Work

- Create dedicated test file for TaskSortParser molecule with comprehensive test coverage
- Test all parsing methods including parse_sort, parse_sorts, and validate_sorts
- Test SortCriteria struct behavior including attribute value extraction and special attribute handling
- Ensure edge cases and error conditions are properly tested
- Verify that test coverage meets project standards (>95%)

### Deliverables

#### Create

- dev-tools/spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb

#### Modify

- N/A (no existing files need modification)

#### Delete

- N/A

## Implementation Plan

### Planning Steps

* [x] Analyze current TaskSortParser implementation and identify testing gaps
  > TEST: Analysis Verification
  > Type: Pre-condition Check
  > Assert: TaskSortParser implementation understood and test coverage gaps identified
  > Command: rspec dev-tools/spec/coding_agent_tools/molecules/taskflow_management/task_sort_engine_spec.rb --format doc | grep -i "TaskSortParser"

* [x] Review existing test patterns in other molecule test files for consistency
  > TEST: Pattern Analysis
  > Type: Pre-condition Check  
  > Assert: Test patterns and conventions understood from similar molecule tests
  > Command: ls dev-tools/spec/coding_agent_tools/molecules/taskflow_management/

* [x] Plan comprehensive test cases covering all public methods and edge cases
  > TEST: Test Plan Validation
  > Type: Pre-condition Check
  > Assert: Test plan covers all public methods and critical edge cases
  > Command: echo "Planning complete - ready for implementation"

### Execution Steps

- [x] Create test file structure following project conventions
  > TEST: Test File Creation
  > Type: Action Validation
  > Assert: Test file created with proper RSpec structure and module namespacing
  > Command: ruby -c dev-tools/spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb

- [ ] Implement tests for SortCriteria struct methods (ascending?, descending?, implementation_order?)
  > TEST: SortCriteria Struct Tests
  > Type: Action Validation
  > Assert: SortCriteria struct methods have comprehensive test coverage
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb -t struct_methods

- [ ] Implement tests for SortCriteria.get_sort_value method with various attribute types
  > TEST: Sort Value Extraction Tests
  > Type: Action Validation
  > Assert: get_sort_value method properly handles all attribute types and edge cases
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb -t get_sort_value

- [ ] Implement tests for parse_sort method with valid and invalid inputs
  > TEST: Parse Sort Method Tests
  > Type: Action Validation
  > Assert: parse_sort method properly parses sort strings and handles errors
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb -t parse_sort

- [ ] Implement tests for parse_sorts method with comma-separated inputs
  > TEST: Parse Multiple Sorts Tests
  > Type: Action Validation
  > Assert: parse_sorts method properly handles multiple sort criteria
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb -t parse_sorts

- [ ] Implement tests for validate_sorts method with known and unknown attributes
  > TEST: Sort Validation Tests
  > Type: Action Validation
  > Assert: validate_sorts method properly validates sort criteria
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb -t validate_sorts

- [ ] Add edge case tests for nil, empty, and malformed inputs
  > TEST: Edge Case Coverage
  > Type: Action Validation
  > Assert: All edge cases and error conditions are properly tested
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb -t edge_cases

- [ ] Verify test coverage meets project standards
  > TEST: Coverage Verification
  > Type: Action Validation
  > Assert: Test coverage for TaskSortParser is above 95%
  > Command: cd dev-tools && bundle exec rspec --coverage spec/coding_agent_tools/molecules/taskflow_management/task_sort_parser_spec.rb

- [ ] Run all tests to ensure no regressions
  > TEST: Integration Test
  > Type: Action Validation
  > Assert: All existing tests still pass with new test file added
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/taskflow_management/

## Acceptance Criteria

- [ ] AC 1: Comprehensive test file created for TaskSortParser molecule
- [ ] AC 2: All public methods have dedicated test coverage with edge cases
- [ ] AC 3: Test coverage meets project standards (>95% for TaskSortParser)
- [ ] AC 4: All tests pass and no regressions introduced

## Out of Scope

- ❌ Modifying the TaskSortParser implementation itself
- ❌ Performance optimization of parsing logic
- ❌ Adding new parsing features
- ❌ Integration tests beyond the molecule level

## References

- TaskSortParser implementation: `dev-tools/lib/coding_agent_tools/molecules/taskflow_management/task_sort_parser.rb`
- Existing TaskSortEngine tests: `dev-tools/spec/coding_agent_tools/molecules/taskflow_management/task_sort_engine_spec.rb`
- Other molecule test files for pattern reference: `dev-tools/spec/coding_agent_tools/molecules/taskflow_management/`