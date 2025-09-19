---
id: v.0.3.0+task.191
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Improve test coverage for AllCLI command - batch operations

## Objective

Improve test coverage for the "All" CLI command (`coding_agent_tools/cli/commands/all.rb`) with a focus on batch operations - functions that process multiple tools simultaneously such as filtering, categorization, different output formats, and error handling scenarios.

The current test coverage exists but has gaps in edge cases, error scenarios, and complex batch operations that need to be addressed to ensure reliability.

## Scope of Work

- Analyze current test coverage gaps in the All CLI command
- Add missing test cases for batch operations scenarios  
- Enhance error handling test coverage
- Test edge cases with different tool configurations
- Ensure comprehensive coverage of all output formats and filtering options

### Deliverables

#### Modify

- `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/spec/coding_agent_tools/cli/commands/all_spec.rb` - Enhanced test coverage

## Implementation Plan

### Planning Steps

* [x] Analyze current test coverage in all_spec.rb and identify gaps
  > TEST: Coverage Analysis Check
  > Type: Pre-condition Check
  > Assert: Current test gaps are identified and documented
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/cli/commands/all_spec.rb --format documentation
* [x] Review ToolLister organism tests to understand batch operation patterns
* [x] Research edge cases and error scenarios that need testing
* [x] Plan test cases for comprehensive batch operations coverage

### Execution Steps

- [x] Add comprehensive error handling test cases (ToolLister failures, invalid options)
- [x] Add edge case tests for empty tool directories and missing executables
- [x] Add tests for blacklist filtering with various patterns  
- [x] Add tests for complex category filtering scenarios
- [x] Add tests for output format edge cases (malformed JSON, empty results)
- [x] Add tests for performance with large numbers of tools
- [x] Add integration tests that verify end-to-end batch processing workflows
- [x] Run enhanced test suite and verify all tests pass
  > TEST: Comprehensive Test Suite Validation
  > Type: Action Validation
  > Assert: All new and existing tests pass with improved coverage
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/cli/commands/all_spec.rb --format documentation

## Acceptance Criteria

- [x] All identified test coverage gaps are addressed with new test cases
- [x] Error handling scenarios are comprehensively tested
- [x] Edge cases for batch operations are covered (empty results, invalid inputs, etc.)
- [x] All output formats (table, json, plain, names) are thoroughly tested
- [x] Category filtering and tool blacklisting scenarios are fully tested
- [x] Integration tests verify end-to-end batch processing functionality
- [x] All tests pass without failures
- [x] Test coverage for the All command reaches comprehensive levels

## Out of Scope

- ❌ Modifying the actual All command implementation (only testing)
- ❌ Adding new features to the All command
- ❌ Testing other CLI commands (focus only on All command)
- ❌ Performance optimizations (testing only)

## References

- Current implementation: `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/lib/coding_agent_tools/cli/commands/all.rb`
- Current tests: `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/spec/coding_agent_tools/cli/commands/all_spec.rb`
- ToolLister organism: `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/lib/coding_agent_tools/organisms/tool_lister.rb`