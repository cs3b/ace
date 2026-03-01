---
name: bug/fix
description: Execute bug fix plan, apply changes, create tests, and verify resolution
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
argument-hint: ''
estimate: 1-2h
doc-type: workflow
purpose: fix-bug workflow instruction
update:
  frequency: on-change
  last-updated: '2025-12-09'
---

# Fix Bug Workflow Instruction

## Goal

Execute a bug fix based on analysis from the analyze-bug workflow (or user-provided fix plan), apply the necessary code changes, create/update regression tests, and verify that the bug is resolved.

## Prerequisites

- Bug analysis completed (via analyze-bug workflow or manual analysis)
- Fix plan available (from analysis or user-provided)
- Access to the codebase where the bug exists
- Development environment set up correctly
- Tests can be executed locally

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

**Before starting bug fix:**

1. Check current branch status: `git status`
2. Ensure you're on an appropriate branch for the fix
3. Verify tests are passing before changes: `ace-test`
4. Review the fix plan from analysis phase

## When to Use This Workflow

**Use this workflow for:**

- Executing a fix plan from analyze-bug workflow
- Applying user-provided fix instructions
- Creating regression tests for bugs
- Verifying bug resolution

**NOT for:**

- Bug analysis (use analyze-bug workflow first)
- Test failures without a bug (use fix-tests workflow)
- Feature development or enhancements
- Refactoring without specific bugs

## Process Steps

### 1. Load Fix Plan

**Check for existing analysis:**

```bash
# Check for cached analysis
ls .cache/ace-task/bug-analysis/
```

**If analysis exists:**

- Load the analysis.yml from the most recent session
- Review root cause, affected files, and proposed tests
- Confirm the fix plan with user if needed

**If no analysis exists:**

- Ask user for fix plan or run analyze-bug workflow first
- Gather: affected files, root cause, proposed solution
- Document the fix approach before proceeding

### 2. Prepare for Fix

**Set up the fix branch:**

```bash
# Check current status
git status

# If not on a fix branch, consider creating one
git checkout -b fix/[bug-description]
```

**Verify baseline:**

- Run existing tests to ensure they pass
- Note any pre-existing failures (not related to this fix)
- Confirm the bug reproduces in current state

### 3. Implement the Fix

**For each file in the fix plan:**

1. **Read the file and understand context:**
   - Review surrounding code
   - Understand dependencies
   - Check for similar patterns in codebase

2. **Apply the fix:**
   - Make minimal changes to fix the bug
   - Follow existing code style and patterns
   - Add appropriate error handling
   - Include inline comments only if logic is non-obvious

3. **Review the change:**
   - Verify the fix addresses root cause
   - Check for unintended side effects
   - Ensure backward compatibility if needed

**Fix implementation guidelines:**

- Fix the root cause, not just symptoms
- Keep changes focused and minimal
- Don't refactor unrelated code
- Maintain existing patterns and style

### 4. Create Regression Tests

**Implement proposed tests from analysis:**

1. **Create unit test for the specific bug:**
   ```ruby
   # Example: test/atoms/component_test.rb
   def test_handles_nil_preferences
     # Arrange: Set up condition that caused the bug
     user = User.new(preferences: nil)

     # Act: Execute the code that was failing
     result = @component.process(user)

     # Assert: Verify correct behavior
     assert_equal expected_default, result
   end
   ```

2. **Create integration test if needed:**
   ```ruby
   # Example: test/integration/workflow_test.rb
   def test_complete_flow_with_missing_data
     # Test the full workflow that exhibited the bug
   end
   ```

**Test requirements:**

- **Fail before / pass after**: Verify that the new test fails without the fix applied, then passes after. This confirms the test actually catches the bug.
- Test must pass with the fix
- Follow project test patterns and conventions
- Place tests in appropriate directories per project structure

### 5. Verify the Fix

**Run verification sequence:**

1. **Run the specific new tests:**
   ```bash
   # Run just the new test file
   ace-test test/path/to/new_test.rb
   ```

2. **Run related tests:**
   ```bash
   # Run tests for the affected component
   ace-test test/[layer]/[component]_test.rb
   ```

3. **Run full test suite:**
   ```bash
   # Verify no regressions
   ace-test
   ```

4. **Manual verification:**
   - Execute the original reproduction steps
   - Confirm the bug no longer occurs
   - Check related functionality still works

**Verification checklist:**

- [ ] New tests pass
- [ ] Related tests pass
- [ ] Full test suite passes
- [ ] Bug no longer reproduces manually
- [ ] No new warnings or errors introduced

### 6. Handle Verification Failures

**If new tests fail:**

- Review test implementation for correctness
- Verify fix is complete
- Check for missing edge cases

**If existing tests fail:**

- Analyze if failure is expected due to fix
- Update tests if behavior change is intentional
- Fix any unintended regressions

**If bug still reproduces:**

- Review fix implementation
- Check for multiple root causes
- Consider if analysis was incomplete
- Return to analysis phase if needed

### 7. Document the Fix

**Update fix documentation:**

```markdown
## Fix Applied

### Changes Made
- `path/to/file1.rb`: [Description of change]
- `path/to/file2.rb`: [Description of change]

### Tests Added
- `test/path/test_file.rb`: [Test description]

### Verification Results
- [ ] All new tests passing
- [ ] All existing tests passing
- [ ] Bug no longer reproduces
- [ ] Manual verification complete

### Notes
[Any additional context about the fix]
```

**Clean up analysis cache:**

```bash
# Optionally archive the analysis
mv .cache/ace-task/bug-analysis/{session} \
   .cache/ace-task/bug-analysis/archive/
```

## Common Fix Patterns

### 1. Nil/Null Reference Fix

**Pattern**: Add nil checks with safe defaults

```ruby
# Before (bug)
def get_preference(user)
  user.preferences.theme
end

# After (fix)
def get_preference(user)
  return DEFAULT_THEME unless user.preferences
  user.preferences.theme || DEFAULT_THEME
end
```

**Test**:
```ruby
def test_handles_nil_preferences
  user = User.new(preferences: nil)
  assert_equal DEFAULT_THEME, get_preference(user)
end
```

### 2. Race Condition Fix

**Pattern**: Add synchronization or redesign

```ruby
# Before (bug)
def update_counter
  @counter += 1
end

# After (fix)
def update_counter
  @mutex.synchronize { @counter += 1 }
end
```

**Test**:
```ruby
def test_concurrent_updates
  threads = 10.times.map { Thread.new { update_counter } }
  threads.each(&:join)
  assert_equal 10, @counter
end
```

### 3. Validation Fix

**Pattern**: Add input validation at boundaries

```ruby
# Before (bug)
def process(input)
  input.split(',').map(&:to_i)
end

# After (fix)
def process(input)
  raise ArgumentError, "Input required" if input.nil? || input.empty?
  input.split(',').map(&:to_i)
end
```

**Test**:
```ruby
def test_rejects_nil_input
  assert_raises(ArgumentError) { process(nil) }
end

def test_rejects_empty_input
  assert_raises(ArgumentError) { process('') }
end
```

### 4. Error Handling Fix

**Pattern**: Add proper error handling and recovery

```ruby
# Before (bug)
def fetch_data(url)
  response = HTTP.get(url)
  JSON.parse(response.body)
end

# After (fix)
def fetch_data(url)
  response = HTTP.get(url)
  raise FetchError, "Failed: #{response.status}" unless response.success?
  JSON.parse(response.body)
rescue JSON::ParserError => e
  raise FetchError, "Invalid response: #{e.message}"
end
```

**Test**:
```ruby
def test_handles_failed_response
  stub_request(:get, url).to_return(status: 500)
  assert_raises(FetchError) { fetch_data(url) }
end

def test_handles_invalid_json
  stub_request(:get, url).to_return(body: "not json")
  assert_raises(FetchError) { fetch_data(url) }
end
```

## Error Handling

### Fix Implementation Issues

**Symptom**: Fix causes new test failures
**Resolution**:

1. Identify which tests fail and why
2. Determine if failures are expected behavior changes
3. Update tests or adjust fix as needed
4. Ensure fix doesn't break unrelated functionality

**Symptom**: Fix doesn't resolve the bug
**Resolution**:

1. Verify the fix was applied correctly
2. Check if there are multiple root causes
3. Return to analysis phase for deeper investigation
4. Consider if reproduction environment differs

**Symptom**: Can't create meaningful tests
**Resolution**:

1. Break down the test into smaller units
2. Use mocking/stubbing for external dependencies
3. Focus on the specific condition that caused the bug
4. Consider integration test if unit test is difficult

### Recovery Procedures

If the fix introduces problems:

1. **Revert the changes:**
   ```bash
   git checkout -- path/to/affected/files
   # or
   git reset HEAD~1  # if committed
   ```

2. **Return to analysis:**
   - Review the original analysis
   - Consider alternative fix approaches
   - Gather more context if needed

3. **Seek clarification:**
   - Ask user about expected behavior
   - Clarify edge cases
   - Confirm fix approach before re-implementing

## Output / Success Criteria

The fix is complete when:

- [ ] **Fix Applied**: All planned changes implemented
- [ ] **Tests Created**: Regression tests added and passing
- [ ] **Tests Passing**: Full test suite passes without regressions
- [ ] **Bug Resolved**: Original bug no longer reproduces
- [ ] **Documentation Updated**: Fix documented with verification results

## Fix Summary Template

Present the fix summary to the user:

```markdown
## Bug Fix Complete

### Summary
[One-sentence description of what was fixed]

### Changes Applied
| File | Change |
|------|--------|
| `path/to/file1.rb` | [Description] |
| `path/to/file2.rb` | [Description] |

### Tests Added
| Test | Purpose |
|------|---------|
| `test/path/component_test.rb` | [What it validates] |

### Verification Results
- [x] New tests passing
- [x] Related tests passing
- [x] Full test suite passing
- [x] Bug no longer reproduces

### Ready for Review
The fix is ready for code review and merge.
```

## Usage Example

> "I ran /ace-bug-analyze earlier and have a fix plan. Please apply the fix for the nil preferences bug."

**Response Process:**

1. Load the cached analysis from `.cache/ace-task/bug-analysis/`
2. Review the fix plan and confirm with user
3. Implement the fix in affected files
4. Create regression tests as proposed
5. Run verification sequence
6. Present fix summary

---

This workflow ensures bug fixes are properly implemented, tested, and verified to prevent regressions.

<documents>
<template id="fix-summary">
## Bug Fix Complete

### Summary
[One-sentence description of what was fixed]

### Changes Applied
| File | Change |
|------|--------|
| `path/to/file1.rb` | [Description] |
| `path/to/file2.rb` | [Description] |

### Tests Added
| Test | Purpose |
|------|---------|
| `test/path/component_test.rb` | [What it validates] |

### Verification Results
- [x] New tests passing
- [x] Related tests passing
- [x] Full test suite passing
- [x] Bug no longer reproduces

### Ready for Review
The fix is ready for code review and merge.
</template>

<template id="fix-documentation">
## Fix Applied

### Changes Made
- `path/to/file1.rb`: [Description of change]
- `path/to/file2.rb`: [Description of change]

### Tests Added
- `test/path/test_file.rb`: [Test description]

### Verification Results
- [ ] All new tests passing
- [ ] All existing tests passing
- [ ] Bug no longer reproduces
- [ ] Manual verification complete

### Notes
[Any additional context about the fix]
</template>
</documents>
