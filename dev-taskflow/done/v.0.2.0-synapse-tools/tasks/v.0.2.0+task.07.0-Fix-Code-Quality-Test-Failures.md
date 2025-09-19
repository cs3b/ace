---
id: v.0.2.0+task.7.0
status: done
priority: critical
estimate: 12h
dependencies: ["v.0.2.0+task.7"]
parent_task: v.0.2.0+task.7
---

# Fix Code Quality Test Failures

## Problem Analysis

After implementing code quality improvements in task v.0.2.0+task.7-Implement-Code-Quality-Improvements, the test suite is failing with multiple issues. The changes introduced breaking changes that need to be addressed to restore system functionality.

### Summary of Failing Tests

Running `bin/test` produces 5 main failure categories:

1. **Zeitwerk Autoloading Issues** - Classes not loading due to naming convention mismatches
2. **Method Signature Mismatches** - `ArgumentError: unknown keyword` errors
3. **Response Structure Changes** - Missing `:raw_body` fields and JSON parsing problems
4. **Faraday Middleware Integration** - Custom middleware causing conflicts
5. **General Integration Issues** - Various secondary effects from the refactoring

### Test Failure Examples

```
Zeitwerk::NameError:
  expected file .../http_request_builder.rb to define constant
  CodingAgentTools::Molecules::HttpRequestBuilder, but didn't

ArgumentError: unknown keyword: :method
# ./lib/coding_agent_tools/molecules/http_request_builder.rb:77:in 'build_headers'

Failure/Error: expect(result[:raw_body]).to eq('{"users": [{"id": 1, "name": "John"}]}')
  expected: "{\"users\": [{\"id\": 1, \"name\": \"John\"}]}"
       got: nil
```

## Objective

Systematically fix all test failures introduced by the code quality improvements while maintaining the benefits of the refactoring. Ensure backward compatibility and restore full test suite functionality.

## Root Cause Analysis

The failures stem from four main categories:

### 1. **Zeitwerk Integration Issues**
- **Problem**: Class names don't follow Zeitwerk naming conventions
- **Impact**: Classes fail to autoload, breaking entire system
- **Priority**: Critical - blocks all other testing

### 2. **API Contract Changes**
- **Problem**: Method signatures changed without updating all call sites
- **Impact**: `ArgumentError` exceptions in tests and potentially production
- **Priority**: High - breaks existing functionality

### 3. **Response Format Changes**
- **Problem**: HTTP response structure modified, breaking test expectations
- **Impact**: Tests expect specific response format that no longer exists
- **Priority**: High - affects core functionality contracts

### 4. **Middleware Integration Problems**
- **Problem**: Custom dry-monitor middleware may conflict with standard middleware
- **Impact**: HTTP requests may fail or behave unexpectedly
- **Priority**: Medium - may affect observability features

## Implementation Strategy

This task is broken down into sequential subtasks that must be completed in order due to dependencies:

### Subtask Dependencies

```
v.0.2.0+task.7.1 (Zeitwerk Issues)
    ↓
v.0.2.0+task.7.2 (Method Signatures)
    ↓
v.0.2.0+task.7.3 (Response Structure)
    ↓
v.0.2.0+task.7.4 (Middleware Integration)
```

### Sequential Fix Approach

1. **First**: Fix Zeitwerk issues - nothing else can be tested until classes load
2. **Second**: Fix method signatures - core functionality must work
3. **Third**: Fix response structures - restore expected API contracts
4. **Fourth**: Fix middleware integration - ensure observability features work

## Subtasks Overview

### [v.0.2.0+task.7.1] Fix Zeitwerk Autoloading Issues ⚠️ CRITICAL
- **Status**: Must be completed first
- **Problem**: Classes not loading due to naming conventions
- **Solution**: Configure Zeitwerk inflections for acronym classes
- **Files**: `lib/coding_agent_tools.rb`
- **Test**: Verify classes can be loaded

### [v.0.2.0+task.7.2] Fix Method Signature Issues
- **Status**: Blocked by 7.1
- **Problem**: `build_headers` method doesn't accept `:method` parameter
- **Solution**: Update method signature or fix test calls
- **Files**: `http_request_builder.rb`, test files
- **Test**: No `ArgumentError: unknown keyword` errors

### [v.0.2.0+task.7.3] Fix Response Structure Changes
- **Status**: Blocked by 7.2
- **Problem**: Missing `:raw_body`, JSON parsing not working
- **Solution**: Restore expected response format with both parsed and raw data
- **Files**: `http_request_builder.rb`, `http_client.rb`
- **Test**: Response includes both `:body` and `:raw_body`

### [v.0.2.0+task.7.4] Fix Faraday Middleware Integration
- **Status**: Blocked by 7.3
- **Problem**: Custom middleware may interfere with standard middleware
- **Solution**: Fix middleware ordering and registration
- **Files**: `http_client.rb`, `faraday_dry_monitor_logger.rb`
- **Test**: HTTP requests work with middleware enabled

## Success Criteria

### Primary Goals
- [ ] All tests pass: `bin/test` returns successful exit code
- [ ] No regression in functionality from before task v.0.2.0+task.7
- [ ] Retain benefits of code quality improvements where possible

### Secondary Goals
- [ ] Maintain backward compatibility for external consumers
- [ ] Preserve observability features from dry-monitor integration
- [ ] Keep improved error handling and Faraday utilities usage

## Validation Strategy

### Continuous Testing
After each subtask completion:
```bash
# Test autoloading
ruby -e "require './lib/coding_agent_tools'; puts CodingAgentTools::Molecules::HTTPRequestBuilder.new.class"

# Test specific failing areas
bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb

# Full test suite
bin/test
```

### Integration Verification
```bash
# Test core functionality still works
exe/llm-gemini-query "test prompt" --debug

# Test new observability features
# (verify dry-monitor events are emitted)
```

## Risk Management

### High Risk Areas
1. **Breaking Changes**: Changes might affect external gem consumers
2. **Middleware Conflicts**: Custom middleware could break HTTP functionality
3. **Test Coverage**: Fixing tests might mask real functionality issues

### Mitigation Strategies
1. **Preserve Public APIs**: Prioritize maintaining existing method signatures
2. **Feature Flags**: Add configuration to disable problematic features if needed
3. **Comprehensive Testing**: Test both unit and integration scenarios

## Timeline

**Total Estimate**: 12 hours across 4 subtasks

- **v.0.2.0+task.7.1**: 2h (Critical path)
- **v.0.2.0+task.7.2**: 3h
- **v.0.2.0+task.7.3**: 4h (Most complex)
- **v.0.2.0+task.7.4**: 3h

**Critical Path**: Must complete subtasks sequentially due to dependencies.

## Acceptance Criteria

- [ ] AC1: `bin/test` passes completely (0 failures, 0 errors)
- [ ] AC2: All classes can be autoloaded via Zeitwerk
- [ ] AC3: No `ArgumentError: unknown keyword` errors
- [ ] AC4: HTTP responses include expected `:body` and `:raw_body` fields
- [ ] AC5: JSON parsing works correctly
- [ ] AC6: Custom middleware integrates without conflicts
- [ ] AC7: `exe/llm-gemini-query` executable works correctly
- [ ] AC8: No regression in core gem functionality
- [ ] AC9: Observability features (dry-monitor) work as intended
- [ ] AC10: Code quality improvements are preserved

## References

- [Parent Task: v.0.2.0+task.7-Implement-Code-Quality-Improvements](v.0.2.0+task.7-Implement-Code-Quality-Improvements.md)
- [Zeitwerk Documentation](https://github.com/fxn/zeitwerk)
- [Faraday Middleware Guide](https://lostisland.github.io/faraday/middleware/)
- [dry-monitor Documentation](https://dry-rb.org/gems/dry-monitor/)

## Notes

- This task is critical for project stability
- Must be completed before any new feature development
- Consider this a "fix forward" approach rather than reverting all changes
- Document any intentional breaking changes for future reference
