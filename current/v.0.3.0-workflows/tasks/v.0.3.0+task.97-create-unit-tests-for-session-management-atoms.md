---
id: v.0.3.0+task.97
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Create Unit Tests for Session Management Atoms

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/atoms/code | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/atoms/code
    ├── directory_creator.rb
    ├── file_content_reader.rb
    ├── session_name_builder.rb
    └── session_timestamp_generator.rb
```

## Objective

Create comprehensive unit tests for the Session Management Atom classes (SessionNameBuilder and SessionTimestampGenerator) to ensure reliable session naming and timestamp generation functionality with proper edge case coverage.

## Scope of Work

- Create unit tests for SessionNameBuilder class covering build(), build_prefix(), and sanitize_target() methods
- Create unit tests for SessionTimestampGenerator class covering generate(), generate_iso8601(), and generate_for_time() methods
- Test edge cases including special characters, long strings, empty inputs, and unicode handling
- Validate timestamp formatting and time zone handling
- Ensure proper RSpec test structure and coverage

### Deliverables

#### Create

- dev-tools/spec/coding_agent_tools/atoms/code/session_name_builder_spec.rb
- dev-tools/spec/coding_agent_tools/atoms/code/session_timestamp_generator_spec.rb

#### Modify

- None

#### Delete

- None

## Phases

1. Analyze existing implementation and identify test scenarios
2. Create comprehensive test cases for SessionNameBuilder
3. Create comprehensive test cases for SessionTimestampGenerator
4. Validate test coverage and edge cases

## Implementation Plan

### Planning Steps

- [ ] Analyze SessionNameBuilder implementation to understand sanitization logic and edge cases
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All public and private methods are identified with their expected behaviors
  > Command: cd dev-tools && bundle exec rspec --dry-run spec/coding_agent_tools/atoms/code/session_name_builder_spec.rb
- [ ] Analyze SessionTimestampGenerator implementation to understand timestamp formatting requirements
- [ ] Research RSpec testing patterns for time-based functionality and mocking strategies

### Execution Steps

- [ ] Create SessionNameBuilder test file with comprehensive test coverage
- [ ] Test build() method with various focus, target, and timestamp combinations
  > TEST: Verify Build Method Functionality
  > Type: Unit Test Validation
  > Assert: All build() method scenarios pass including edge cases
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/code/session_name_builder_spec.rb -t build
- [ ] Test build_prefix() method without timestamp scenarios
- [ ] Test sanitize_target() private method with edge cases (slashes, spaces, special chars, length limits)
  > TEST: Verify Sanitization Logic
  > Type: Edge Case Validation
  > Assert: All sanitization scenarios handle edge cases correctly
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/code/session_name_builder_spec.rb -t sanitize
- [ ] Create SessionTimestampGenerator test file with time mocking
- [ ] Test generate() method returns correct YYYYMMDD-HHMMSS format
- [ ] Test generate_iso8601() returns proper ISO8601 format
- [ ] Test generate_for_time() with specific Time objects
  > TEST: Verify Timestamp Generation
  > Type: Time-based Test Validation
  > Assert: All timestamp methods generate expected formats
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/code/session_timestamp_generator_spec.rb
- [ ] Run complete test suite to ensure no regressions
  > TEST: Full Test Suite Validation
  > Type: Regression Check
  > Assert: All existing tests continue to pass with new test additions
  > Command: cd dev-tools && bundle exec rspec

## Acceptance Criteria

- [ ] SessionNameBuilder has comprehensive test coverage including all public methods and edge cases
- [ ] SessionTimestampGenerator has complete test coverage with proper time mocking
- [ ] All tests follow RSpec best practices and project testing conventions
- [ ] Test files are properly organized in the expected directory structure
- [ ] All tests pass and provide meaningful error messages for failures

## Out of Scope

- ❌ Testing integration with other components beyond the atom level
- ❌ Performance testing or benchmarking
- ❌ Modifying the implementation of the classes being tested

## References

- dev-tools/lib/coding_agent_tools/atoms/code/session_name_builder.rb
- dev-tools/lib/coding_agent_tools/atoms/code/session_timestamp_generator.rb
- dev-tools/spec/spec_helper.rb
- dev-handbook/guides/testing/ruby-rspec.md