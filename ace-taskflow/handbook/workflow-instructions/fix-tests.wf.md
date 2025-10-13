---
name: fix-tests
description: Systematically diagnose and fix failing automated tests
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
argument-hint: ''
doc-type: workflow
purpose: fix-tests workflow instruction
update:
  frequency: on-change
  last-updated: '2025-10-02'
---

# Fix Tests Workflow Instruction

## Goal

Systematically diagnose and fix failing automated tests (unit, integration, etc.) - focusing specifically on test failures rather than general application bugs.

## Prerequisites

- Test suite has been run and failures have been identified
- Access to test output (error messages, stack traces)
- Development environment is set up correctly
- Understanding of the project's testing approach

## Project Context Loading

- Read and follow: `ace-nav wfi://load-project-context`

**Before starting test fixes:**

1. Check recent changes: `git log --oneline -10`
2. Review test configuration: Look for `test/`, `spec/`, or `tests/` directories
3. Understand testing framework: Check `Gemfile`, `package.json`, or `requirements.txt`
4. If `docs/testing.md` exists, read it for project-specific testing guidelines

**During test fixing:**

- Check for existing similar tests for patterns
- Verify fixes align with project architecture

## When to Use This Workflow

**Use this workflow for:**

- Automated tests failing in your test suite
- Test-specific issues (setup, isolation, execution)
- Test infrastructure problems
- Flaky or intermittent test failures

**NOT for:**

- General application bugs not causing test failures
- Feature development or new requirements
- Performance optimization unrelated to tests

## Framework Detection

**Auto-detect testing framework by checking project files:**

**Ruby:**
- Check `Gemfile` for `rspec`, `minitest`
- Check for `spec/` directory → RSpec
- Check for `test/` directory → Minitest

**JavaScript:**
- Check `package.json` for `jest`, `mocha`, `jasmine`, `vitest`
- Check for `jest.config.js` → Jest
- Check for `.mocharc.*` → Mocha

**Python:**
- Check `requirements.txt` or `pyproject.toml` for `pytest`, `unittest`
- Check for `pytest.ini` → pytest
- Check for `test_*.py` or `*_test.py` → pytest/unittest

**Go:**
- Check for `*_test.go` files → Go testing package

**Framework-Specific Commands:**

```bash
# RSpec (Ruby)
bundle exec rspec

# Minitest (Ruby)
bundle exec rake test

# Jest (JavaScript)
npm test
npx jest

# pytest (Python)
pytest

# Go testing
go test ./...
```

## Claude Commands for Test Fixing

**Primary command for iterative fixing:**

```bash
# Find and work on next failing test
# Run project-specific test command --next-failure
```

**Test discovery commands:**

```bash
# Quick test status check
# Run project-specific test command --status

# List all failing tests
# Run project-specific test command --list-failures

# Run specific test file
# Run project-specific test command path/to/test_file.rb

# Run with detailed output
# Run project-specific test command --verbose

# Run only failing tests
# Run project-specific test command --only-failures
```

## Primary Fix Process: Iterative Approach

**This is the recommended method for fixing test failures systematically and efficiently.**

**Main Loop (repeat until no failures):**

1. **Identify Next Failure:**

   ```bash
   # Run project-specific test command --next-failure
   ```

2. **Investigate Root Cause:**
   - Read test file and understand what it's testing
   - Check recent changes that might have broken it
   - Look for patterns with other failures

3. **Implement Solution:**
   - Fix the underlying issue (not just the test)
   - Ensure fix doesn't break other tests
   - Ask user only if solution is unclear

4. **Verify Fix:**

   ```bash
   # Run the specific test
   # Run project-specific test command path/to/fixed_test.rb

   # Run related tests
   # Run project-specific test command --related path/to/fixed_test.rb
   ```

5. **Loop Back:**
   - Return to step 1 until `# Run project-specific test command --next-failure` returns no errors

**Final Verification:**

```bash
# Run full test suite
# Run project-specific test command
```

## Quick Troubleshooting Decision Tree

**Test Failure Type → Action:**

- **Syntax Error** → Fix code syntax immediately
- **Missing Method/Class** → Check if file moved or renamed
- **Database Error** → Run `# Run project-specific test command --setup-db` or equivalent
- **Timeout** → Check for infinite loops or increase timeout
- **Permission Error** → Check file permissions and dependencies
- **Network Error** → Mock external services or check connectivity
- **Environment Error** → Verify system dependencies and configuration

**Quick First Steps:**

1. **Recent Changes?** → `git log --oneline -10` and check related files
2. **Dependencies Updated?** → Run `bundle install`, `npm install`, etc.
3. **Environment Issues?** → Check Ruby/Python/Node versions
4. **Database Issues?** → Reset test database and clear caches

## Common Test Issues and Solutions

### 1. Database State Issues

**Symptoms**: Tests pass individually but fail when run together
**Solutions**:

- Use database transactions
- Implement proper cleanup in teardown
- Check for hardcoded IDs
- Use factories instead of fixtures

### 2. Time-Dependent Tests

**Symptoms**: Tests fail at certain times or dates
**Solutions**:

- Mock time with tools like Timecop
- Use relative dates instead of absolute
- Set consistent timezone in tests

### 3. External API Tests

**Symptoms**: Tests fail due to network or API changes
**Solutions**:

- Use VCR or similar for recording/replaying
- Mock external services
- Use test doubles for APIs
- Implement proper error handling

### 4. Async/Concurrent Tests

**Symptoms**: Intermittent failures, race conditions
**Solutions**:

- Add proper wait conditions
- Use test helpers for async operations
- Increase timeouts appropriately
- Ensure proper synchronization

### 5. Test Performance

**Symptoms**: Tests timeout or run very slowly
**Solutions**:

- Profile slow tests
- Use test data builders efficiently
- Minimize database operations
- Parallelize test execution

## Time Management and Efficiency

**Quick wins first:**

- Fix syntax errors immediately
- Resolve missing imports/requires
- Update outdated assertions

**Batch similar fixes:**

- Group tests by failure type
- Fix all database-related issues together
- Update all tests using deprecated methods

**Know when to ask:**

- Business logic questions
- Complex architectural decisions
- Unclear requirements or specifications

**Time-saving techniques:**

- Use `# Run project-specific test command --next-failure` for systematic progress
- Run specific test files instead of full suite during development
- Use test-specific debugging tools (`--verbose`, `--backtrace`)
- Fix root causes instead of individual symptoms

## Testing Principles

**Write Good Tests:**

- **Isolated**: No dependencies between tests
- **Repeatable**: Same result every time
- **Self-validating**: Clear pass/fail
- **Timely**: Run quickly
- **Focused**: Test one thing

**Test Organization:**

- Group related tests logically
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Keep tests DRY but readable

**Debugging Techniques:**

- Add debug output temporarily
- Use debugger breakpoints
- Examine test logs
- Run tests in different orders
- Binary search for problematic tests

## Output / Success Criteria

- All tests in the suite pass consistently
- Root cause of failures understood and documented
- No new test failures introduced
- Test execution time remains reasonable
- Fixes follow testing best practices
- Knowledge captured for future reference

## Reference Patterns

### RSpec (Ruby)

```ruby
RSpec.describe UserService do
  let(:user) { create(:user) }

  before do
    # Setup
  end

  after do
    # Cleanup
  end

  it "performs expected behavior" do
    result = UserService.call(user)
    expect(result).to be_success
  end
end
```

### Jest (JavaScript)

```javascript
describe('UserService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('performs expected behavior', async () => {
    const result = await UserService.call(mockUser);
    expect(result.success).toBe(true);
  });
});
```

### pytest (Python)

```python
import pytest

class TestUserService:
    @pytest.fixture
    def user(self):
        return User(name="Test User")

    def test_performs_expected_behavior(self, user):
        result = UserService.call(user)
        assert result.success == True
```

### Go testing

```go
package main

import "testing"

func TestUserService(t *testing.T) {
    user := &User{Name: "Test User"}
    result := UserService.Call(user)
    if !result.Success {
        t.Errorf("Expected success, got %v", result)
    }
}
```

## Automated Fix Patterns

**Pattern Recognition:**

- Update deprecated method calls
- Fix changed API signatures
- Update test data for schema changes
- Resolve path changes after refactoring

**Quick Commands:**

```bash
# Update all tests using old method
find . -name "*test*" -type f -exec sed -i 's/old_method/new_method/g' {} \;

# Fix common RSpec deprecations
# Run project-specific test command --fix-deprecations

# Update factory references
# Run project-specific test command --update-factories
```

**Common Automated Fixes:**

- Replace `should` with `expect` in RSpec
- Update `assert_equal` to `assert_equals` in unittest
- Fix imports after module reorganization
- Update configuration paths after restructuring

## Usage Example
>
> "The test suite is failing with 5 errors in the user authentication module. Help me fix these test failures."

**Response Process:**

1. Run `# Run project-specific test command --next-failure` to identify first failing test
2. Investigate root cause and implement fix
3. Continue with `# Run project-specific test command --next-failure` until no more failures
4. Run full test suite `# Run project-specific test command` to verify all tests pass

---

This workflow provides a systematic approach to fixing test failures, emphasizing proper diagnosis, isolation, and sustainable solutions that maintain test suite health.
