---
id: 8kn000
title: Test Performance Optimization - Parser and Subprocess Issues
type: standard
tags: []
created_at: '2025-09-24 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8kn000-subprocess-test-performance.md"
---

# Reflection: Test Performance Optimization - Parser and Subprocess Issues

## Date: 2025-09-24
## Context: ace-test-runner and ace-core test performance optimization

## Problem Statement

Two major performance issues were identified:

1. **Parser Performance**: ace-test-runner was taking 3+ seconds total despite tests completing in ~150ms. The delay occurred during result parsing phase.

2. **Subprocess Tests**: 19 tests in ace-core were taking 140-160ms each due to spawning Ruby subprocesses using `run_in_clean_env` to unset the PROJECT_ROOT_PATH environment variable.

## Root Cause Analysis

### Parser Performance Issues (ace-test-runner)
- **Multiple ANSI Code Cleaning**: Each parsing method was calling `gsub(/\e\[[0-9;]*m/, '')` on entire output
- **O(n²) Complexity**: Test time parsing searched entire output for each test location
- **Expensive Regex on Success**: Complex patterns like `((?:.*?\n)*?)` running even when no failures existed
- **Inefficient Failure Parsing**: Still takes 2-3 seconds when tests actually fail (NOT YET FIXED)

### Subprocess Test Issues (ace-core)
- Tests used `Open3.capture2e` to spawn Ruby subprocesses
- Each subprocess had ~150ms overhead for Ruby interpreter startup
- Purpose was to test behavior when PROJECT_ROOT_PATH env variable was unset
- Tests needed isolation to avoid global ENV modification in parallel execution

## Solution Approach

### Parser Optimization (ace-test-runner)

1. **Clean ANSI codes once**
   ```ruby
   def parse_output(output)
     clean_output = output.gsub(/\e\[[0-9;]*m/, '')
     # Pass clean_output to all parsing methods
   end
   ```

2. **Build location index to avoid O(n²)**
   ```ruby
   location_index = {}
   clean_output.scan(/(test_[\w_]+).*?\[(.*?):(\d+)\]/) do |name, file, line|
     location_index[name] ||= "#{file}:#{line}"
   end
   # Then use O(1) lookups instead of regex searches
   ```

3. **Check for failures before expensive regex**
   ```ruby
   if failures.empty? && (clean_output.include?(' FAIL ') || clean_output.include?(' ERROR '))
     # Only then run expensive regex patterns
   end
   ```

### Subprocess Elimination (ace-core)

#### Initial Consideration
First considered modifying ENV directly in setup/teardown, but this would:
- Cause race conditions in parallel test execution
- Pollute global state between tests
- Break test isolation principles

#### Elegant Solution: Protected Method Pattern
1. **Extract ENV access to protected method**
   ```ruby
   protected
   def env_project_root
     ENV['PROJECT_ROOT_PATH']
   end
   ```

2. **Use method stubbing in tests**
   ```ruby
   finder.stub :env_project_root, nil do
     assert_equal expected, finder.find
   end
   ```

### Implementation Details
- Modified `ProjectRootFinder` to use protected `env_project_root` method
- Updated 15 tests in `project_root_finder_test.rb`
- Updated 3 tests in `config_discovery_path_resolution_test.rb`
- Updated 1 test in `directory_traverser_test.rb`
- Added 2 new tests for ENV variable behavior (previously missing)
- Fixed ace-test-suite reporter to use test results instead of exit code

## Results

### Parser Performance Metrics (ace-test-runner)
- **Before**: 3.5 seconds total (150ms tests + 3.35s parsing)
- **After (success path)**: <200ms total
- **Improvement**: 20x faster for successful tests
- **Still Pending**: Failure parsing still takes 2-3 seconds

### Subprocess Test Performance Metrics (ace-core)
- **Before**: 3 seconds total, 140-160ms per subprocess test
- **After**: 0.15 seconds total, <1ms per test
- **Improvement**: 20x faster execution

### Code Quality
- Minimal production code changes (one protected method)
- Cleaner test code without subprocess complexity
- Better test coverage with ENV variable tests
- Parallel-safe without global state modification

## Key Learnings

### 1. Profile First, Optimize Later
- Always instrument and measure before optimizing
- The bottleneck may not be where you expect (parsing, not subprocess execution)
- Use timing logs to identify exact performance issues

### 2. Regex Performance Matters
- Complex patterns like `((?:.*?\n)*?)` can be extremely expensive
- Check for simple string patterns before running expensive regex
- Build indexes for O(1) lookups instead of O(n²) searches

### 3. Question Subprocess Necessity
Before using subprocesses for test isolation, consider:
- Is it testing ENV manipulation or just absence?
- Can method stubbing achieve the same isolation?
- What's the actual isolation requirement?

### 2. Protected Methods for Testability
Extracting external dependencies (ENV, File, Time) to protected methods enables:
- Clean stubbing in tests
- No API pollution
- Maintains encapsulation

### 4. Protected Methods for Testability
Extracting external dependencies (ENV, File, Time) to protected methods enables:
- Clean stubbing in tests
- No API pollution
- Maintains encapsulation

### 5. Performance Investigation Process
Effective debugging approach:
1. Add timing instrumentation with ENV['DEBUG_TIMING']='1'
2. Use `--profile` flag to identify slow tests
3. Look for patterns in slow test names
4. Check for subprocess spawning, I/O operations, or complex regex
5. Consider alternative isolation techniques

### 6. Test Suite Reporter Bug
Secondary issue discovered: ace-test-suite was using process exit code instead of test results from summary.json, causing incorrect failure reporting.

## Future Recommendations

### Immediate Actions Required
1. **Fix failure parsing performance** in ace-test-runner
   - Apply similar optimizations to failure extraction
   - Test with failing tests to ensure performance improvements work
   - Consider streaming/chunked parsing for very large outputs

### For Similar Situations
1. **Prefer method stubbing over subprocess isolation** when testing absence of external state
2. **Extract external dependencies to protected methods** for testability
3. **Profile tests regularly** to catch performance regressions early
4. **Document test patterns** in team guidelines
5. **Add performance regression tests** for parsers and critical paths

### Testing ENV-Dependent Code
Pattern for parallel-safe ENV testing:
```ruby
class MyClass
  protected
  def env_value
    ENV['MY_VAR']
  end
end

# In tests
obj.stub :env_value, 'test_value' do
  # test behavior
end
```

### Monitoring Test Performance
- Add CI check for test duration regression
- Regular profiling of slowest tests
- Consider test parallelization for remaining slow tests

## Conclusion

Two significant performance improvements were achieved:

1. **Parser optimization** in ace-test-runner reduced parsing time from 3.35 seconds to near-instant for successful tests, though failure parsing still needs work.

2. **Subprocess elimination** in ace-core tests achieved a 20x speedup through thoughtful refactoring that actually improved code quality.

Both solutions demonstrate that performance optimizations can align with clean code principles when approached systematically. The key is to profile first, understand the root cause, and then apply targeted fixes that improve both performance and maintainability.

### Outstanding Issue
**Critical**: Failure parsing in ace-test-runner still takes 2-3 seconds when tests fail. This needs immediate attention as it significantly impacts the developer experience when debugging test failures.