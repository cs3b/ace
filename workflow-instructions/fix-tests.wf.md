# Fix Tests Workflow Instruction

## Goal

Systematically diagnose and fix failing automated tests (unit, integration, etc.) - focusing specifically on test failures rather than general application bugs.

## Prerequisites

- Test suite has been run and failures have been identified
- Access to test output (error messages, stack traces)
- Development environment is set up correctly
- Understanding of the project's testing approach

## Project Context Loading

**Essential project context:**
- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

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

## Claude Commands for Test Fixing

**Primary command for iterative fixing:**

```bash
# Find and work on next failing test
bin/test --next-failure
```

**Test discovery commands:**

```bash
# Quick test status check
bin/test --status

# List all failing tests
bin/test --list-failures

# Run specific test file
bin/test path/to/test_file.rb

# Run with detailed output
bin/test --verbose

# Run only failing tests
bin/test --only-failures
```

## Iterative Fix Process

**Main Loop (repeat until no failures):**

1. **Identify Next Failure:**

   ```bash
   bin/test --next-failure
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
   bin/test path/to/fixed_test.rb
   
   # Run related tests
   bin/test --related path/to/fixed_test.rb
   ```

5. **Loop Back:**
   - Return to step 1 until `bin/test --next-failure` returns no errors

**Final Verification:**

```bash
# Run full test suite
bin/test
```

## Legacy Process Steps (for reference)

1. **Initial Analysis:**

   ```bash
   # Run full test suite
   bin/test
   
   # Run only failing tests
   bin/test --only-failures
   
   # Run with detailed output
   bin/test --verbose
   ```

   **Capture:**
   - Failing test names and locations
   - Error messages and stack traces
   - Test execution time (for timeout issues)
   - Pattern of failures (consistent vs intermittent)

2. **Prioritize Failures:**

   **Priority order:**
   1. **Unit tests** - Usually fastest to fix and run
   2. **Integration tests** - May involve multiple components
   3. **End-to-end tests** - Most complex, slowest to debug

   **Within each level, prioritize:**
   - Tests blocking other work
   - Tests with clear error messages
   - Recently modified tests
   - Core functionality tests

3. **Isolate and Diagnose:**

   **Run specific test:**

   ```bash
   # Ruby/RSpec example
   bin/test spec/path/to/failing_spec.rb:42
   
   # Run specific test by name pattern
   bin/test --name "test_user_authentication"
   
   # Run next failure
   bin/test --next-failure
   ```

   **Common failure patterns:**
   - **Assertion failures**: Expected vs actual mismatch
   - **Setup errors**: Missing test data or configuration
   - **Timeout errors**: Slow operations or deadlocks
   - **Dependency errors**: Missing mocks or stubs
   - **State pollution**: Tests affecting each other

4. **Diagnose Root Cause:**

   **Environment Issues:**

   ```bash
   # Check language version
   ruby -v
   python --version
   node -v
   
   # Verify dependencies
   bundle install
   npm install
   pip install -r requirements.txt
   
   # Reset test database
   bin/rails db:test:prepare
   
   # Clear caches
   rm -rf tmp/*
   rm -rf .pytest_cache
   ```

   **Test Isolation Problems:**
   - Check setup/teardown methods
   - Verify database transactions/rollbacks
   - Look for shared state between tests
   - Review test execution order dependencies

   **Common Fixes:**

   ```ruby
   # Example: Ensure clean state
   before(:each) do
     DatabaseCleaner.clean
     Rails.cache.clear
   end
   
   # Example: Fix timing issues
   it "processes asynchronously" do
     perform_async_operation
     wait_for { async_result }.to be_present
   end
   
   # Example: Proper mocking
   allow(ExternalService).to receive(:call).and_return(mock_response)
   ```

5. **Implement Fix:**

   **Fix categories:**
   - **Test code fix**: Update assertions, fix test logic
   - **Application code fix**: Fix actual bug revealed by test
   - **Test data fix**: Correct fixtures or factories
   - **Infrastructure fix**: Update test helpers or configuration

   **Verification steps:**
   1. Run the specific failing test
   2. Run all tests in the same file
   3. Run all tests in the same module/component
   4. Run full test suite

6. **Document and Commit:**

   **Document in commit message:**

   ```
   fix(tests): resolve flaky user authentication test
   
   - Add proper database cleanup in teardown
   - Fix race condition in async callback
   - Increase timeout for CI environment
   
   The test was failing intermittently due to database
   state pollution from previous tests.
   ```

   **Add code comments if needed:**

   ```ruby
   # IMPORTANT: This sleep is required because the external
   # service has a rate limit. See issue #123
   sleep 0.1
   ```

## Quick Troubleshooting Decision Tree

**Test Failure Type → Action:**

- **Syntax Error** → Fix code syntax immediately
- **Missing Method/Class** → Check if file moved or renamed
- **Database Error** → Run `bin/test --setup-db` or equivalent
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

- Use `bin/test --next-failure` for systematic progress
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
bin/test --fix-deprecations

# Update factory references
bin/test --update-factories
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
1. Run `bin/test --next-failure` to identify first failing test
2. Investigate root cause and implement fix
3. Continue with `bin/test --next-failure` until no more failures
4. Run full test suite `bin/test` to verify all tests pass

---

This workflow provides a systematic approach to fixing test failures, emphasizing proper diagnosis, isolation, and sustainable solutions that maintain test suite health.
