---
id: 8lk000
title: Writing Fast Unit Tests
type: conversation-analysis
tags: []
created_at: "2025-10-21 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8lk000-fast-unit-tests-practices.md
---
# Reflection: Writing Fast Unit Tests

**Date**: 2025-10-21
**Context**: Lessons learned from fixing and optimizing ace-docs test suite (83 tests, 8s → 0.64s)
**Author**: Development Team
**Type**: Conversation Analysis

## What Went Well

- **Systematic profiling approach**: Using `ace-test --profile` immediately identified the slowest tests
- **Root cause analysis**: Traced performance issues to real git operations and unnecessary object creation
- **Dramatic improvements**: Achieved 12x overall speedup (120x for unit tests alone)
- **Zero regressions**: All 83 tests continued passing after optimization
- **Pattern recognition**: Identified common anti-patterns (real I/O in unit tests, dead code in setup)

## What Could Be Improved

- **Earlier detection**: Tests were slow from the start but not caught during initial development
- **Test design awareness**: Developers weren't following the protected method pattern from `docs/testing-patterns.md`
- **No CI performance checks**: No automated alerts for slow tests creeping into the suite
- **Missing linting**: No automated check for common anti-patterns (system calls, DocumentRegistry in unit tests)

## Key Learnings

### The Cost of Real I/O in Unit Tests

**Problem Identified:**
- 3 molecule tests calling real git operations: ~400ms each
- 17 organism tests creating DocumentRegistry (scans filesystem): ~320ms each
- Total overhead: 6.5 seconds for operations that test nothing

**Root Causes:**
1. **Missing stubs**: Tests called `ChangeDetector.get_diff_for_document()` without stubbing `execute_git_command`
2. **Dead code**: `@registry = DocumentRegistry.new` in setup was stored but never used by Validator
3. **Unclear boundaries**: Developers didn't distinguish between unit tests (pure logic) and integration tests (real I/O)

**Learning**: Unit tests should NEVER do real I/O (git, file, network, DB). Any external dependency must be stubbed.

### The Protected Method Pattern

From `docs/testing-patterns.md`, the pattern we should have followed:

```ruby
# Production code - extract external dependencies
class MyClass
  def business_logic
    data = external_data  # Calls protected method
    process(data)
  end

  protected
  def external_data
    execute_git_command("git diff")  # External dependency
  end
end

# Test code - stub the protected method
def test_business_logic
  obj = MyClass.new
  obj.stub :external_data, "mock data" do
    result = obj.business_logic
    assert_equal expected, result
  end
end
```

**We violated this**: Tests called public methods that internally called real git operations.

### Dead Code Has Performance Costs

```ruby
# DON'T - expensive object created but never used
def setup
  @registry = DocumentRegistry.new  # 320ms × 17 tests = 5.4s wasted
  @validator = Validator.new(@registry)
end
```

**Learning**: Review all setup code - every line costs time on EVERY test.

### Test Speed Targets

Based on our optimizations:

| Test Type | Target | Acceptable | Slow | Example |
|-----------|--------|------------|------|---------|
| **Unit (Pure)** | <1ms | <10ms | >50ms | Business logic, calculations |
| **Unit (Mocked)** | <10ms | <50ms | >100ms | With stubbed external calls |
| **Integration** | <100ms | <500ms | >1s | Real file/git operations |

Our results:
- Atoms: 0.7ms per test ✅
- Molecules: 0.7ms per test ✅ (was 68ms ❌)
- Organisms: 0.7ms per test ✅ (was 170ms ❌)
- Models: 1.4ms per test ✅

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Real Git Operations in Unit Tests**
  - Occurrences: 3 tests (molecules)
  - Impact: 1.2s overhead, 97x slower than needed
  - Root Cause: Missing awareness of when to stub external commands
  - Solution Applied: Wrapped tests in `ChangeDetector.stub :execute_git_command, "" do`

- **Expensive Object Creation in Setup**
  - Occurrences: 17 tests (organisms)
  - Impact: 5.4s overhead, 226x slower than needed
  - Root Cause: Dead code (@registry stored but never used)
  - Solution Applied: Changed `Validator.new(@registry)` to `Validator.new(nil)`

#### Medium Impact Issues

- **No CI Performance Monitoring**
  - Occurrences: Throughout development
  - Impact: Slow tests shipped to main branch undetected
  - Root Cause: No automated profiling or performance gates
  - Proposed Solution: Add CI check for tests >100ms

## Action Items

### Stop Doing

- **Creating real objects in unit test setup** - Use mocks/stubs or nil for unused dependencies
- **Calling real external commands in unit tests** - Always stub git, file operations, network calls
- **Ignoring test execution time** - Slow tests indicate design problems
- **Writing tests without checking performance** - Profile new tests before committing

### Continue Doing

- **Using protected method pattern** - Extract external dependencies for easy stubbing
- **Profiling test suite** - Regular `ace-test --profile` checks catch regressions
- **Flat test structure** - Keeps tests organized and fast to discover
- **Following testing-patterns.md** - Document already had the right patterns!

### Start Doing

- **Review setup methods** - Every line in setup runs on EVERY test - minimize it
- **Stub by default for unit tests** - External calls should be exceptional and explicit
- **Add performance assertions** - Fail CI if tests exceed time budgets
- **Use integration tests for real I/O** - Move filesystem/git tests to `test/integration/`
- **Pre-commit performance checks** - Hook to warn about slow tests before commit

## Technical Details

### Fast Test Checklist

When writing unit tests, verify:

✅ **No real I/O operations:**
- [ ] No `system()`, `Open3.capture3()`, or shell commands
- [ ] No `File.read()`, `File.write()` without temp files
- [ ] No `Dir.glob()` on actual project directories
- [ ] No database queries or network calls
- [ ] No `sleep()` or timing dependencies

✅ **Minimal setup overhead:**
- [ ] Setup creates only objects actually used
- [ ] Expensive objects (DocumentRegistry, DB connections) passed as nil or mocked
- [ ] No filesystem scanning or project-wide operations

✅ **Proper stubbing:**
- [ ] External dependencies extracted to protected methods
- [ ] Tests stub the protected methods, not internal implementation
- [ ] Stubs return minimal valid data (often just `""` or `{}`)

✅ **Right test type:**
- [ ] Unit tests: Pure logic, stubbed dependencies
- [ ] Integration tests: Real I/O, actual file/git operations
- [ ] Tests in correct directory (`test/molecules/` vs `test/integration/`)

### Code Examples

**BEFORE (Slow):**
```ruby
def test_determine_since
  document = Models::Document.new(path: "test.md", ...)
  result = ChangeDetector.get_diff_for_document(document)  # Calls real git!
  assert_equal "2024-09-15", result[:since]
end
```

**AFTER (Fast):**
```ruby
def test_determine_since
  document = Models::Document.new(path: "test.md", ...)
  ChangeDetector.stub :execute_git_command, "" do  # Stub the external call
    result = ChangeDetector.get_diff_for_document(document)
    assert_equal "2024-09-15", result[:since]
  end
end
```

### Performance Comparison

| Component | Before | After | Improvement |
|-----------|--------|-------|-------------|
| Molecules | 1.16s | 12ms | **97x faster** |
| Organisms | 5.43s | 24ms | **226x faster** |
| Total Suite | 7.80s | 0.64s | **12x faster** |
| Unit Tests | 7.22s | 60ms | **120x faster** |

### Prevention Strategy

**For New Tests:**
1. Write test with stub first (assume external calls will be slow)
2. Run single test: `ace-test path/to/test.rb` and check time
3. If >10ms for unit test, profile and investigate
4. Add to CI: Fail if new tests exceed budget

**For Existing Tests:**
1. Run `ace-test --profile 20` weekly
2. Investigate any test >50ms
3. Move real I/O tests to integration suite
4. Document findings in testing-patterns.md

**CI Integration:**
```yaml
# .github/workflows/test.yml
- name: Check test performance
  run: |
    ace-test --profile 20 | tee profile.txt
    # Fail if any unit test takes >100ms
    if grep -E "test_(atoms|molecules|organisms|models)" profile.txt | awk '{print $NF}' | grep -E "[0-9]+\.[1-9][0-9][0-9]s"; then
      echo "❌ Unit tests taking >100ms detected"
      exit 1
    fi
```

## Improvement Proposals

### Tool Enhancements

**1. Test Performance Linter**
```ruby
# Proposed: ace-lint --test-performance
# Checks for common anti-patterns:
# - system/Open3 calls in unit tests
# - File I/O without Tempfile
# - DocumentRegistry.new in setup
# - Missing stubs for known slow methods
```

**2. Test Classification Tool**
```bash
# Proposed: ace-test --classify
# Analyzes tests and reports:
# - Which tests do real I/O (should be integration)
# - Which tests are properly stubbed (unit)
# - Time spent on I/O vs logic
```

**3. Performance Regression Detection**
```bash
# Proposed: ace-test --baseline
# Records baseline performance
# Future runs compare and fail if regression >20%
```

### Documentation Improvements

**Update `docs/testing-patterns.md`:**
- Add "Fast Test Checklist" section
- Include anti-pattern examples with performance costs
- Add CI integration example
- Link to this retro for real-world case study

**Create new guide: `docs/guides/fast-tests.g.md`:**
- Quick reference for test performance
- Decision tree: Unit vs Integration test
- Stubbing patterns for common dependencies (git, file, network)
- Performance budgets and enforcement

### Workflow Proposals

**Pre-commit Hook:**
```bash
# .git/hooks/pre-commit
# Run only modified tests with profiling
modified_tests=$(git diff --cached --name-only | grep _test.rb)
if [ -n "$modified_tests" ]; then
  ace-test $modified_tests --profile 5
  # Warn if any test >50ms
fi
```

## Additional Context

**Related Documentation:**
- `docs/testing-patterns.md` - Already has protected method pattern
- Test performance improvements: Commits `3fe8baae`, `0177c419`

**Performance Metrics:**
- Initial state: 83 tests, 7.80s, 5 errors, 4 failures
- After fixes: 83 tests, 7.80s, 0 errors, 0 failures
- After optimization: 83 tests, 0.64s, 0 errors, 0 failures

**Key Insight:** The patterns for fast tests were already documented in `docs/testing-patterns.md`, but weren't being followed. The real improvement needed is **enforcement** and **awareness**, not new patterns.
