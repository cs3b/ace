---
id: v.0.3.0+task.91
status: pending
priority: medium
estimate: 1h
dependencies: []
---

# Standardize shell command escaping in ShellCommandExecutor

## 0. Directory Audit ✅

_Command run:_

```bash
find dev-tools -name "*shell_command_executor*" -type f | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/atoms/taskflow_management/shell_command_executor.rb
    dev-tools/spec/coding_agent_tools/atoms/taskflow_management/shell_command_executor_spec.rb
```

## Objective

Replace the custom `escape_argument` method in ShellCommandExecutor with the more robust and standard `Shellwords.escape` from the Ruby standard library. The custom implementation is simple but may not cover all edge cases that Shellwords handles.

## Scope of Work

- Replace custom escape_argument implementation with Shellwords.escape
- Update all usages of the custom method
- Ensure backward compatibility
- Verify security improvements

### Deliverables

#### Create

- None

#### Modify

- dev-tools/lib/coding_agent_tools/atoms/taskflow_management/shell_command_executor.rb

#### Delete

- None (remove the custom escape_argument method)

## Phases

1. Analyze current custom implementation
2. Replace with standard library
3. Test the changes

## Implementation Plan

### Planning Steps

- [ ] Review current escape_argument implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Custom escape method is identified
  > Command: cd dev-tools && grep -A 5 "def.*escape_argument" lib/coding_agent_tools/atoms/taskflow_management/shell_command_executor.rb
- [ ] Identify all usages of escape_argument
- [ ] Review Shellwords.escape capabilities

### Execution Steps

- [ ] Step 1: Import Shellwords module
  - Add `require 'shellwords'` at the top of the file
- [ ] Step 2: Replace escape_argument calls with Shellwords.escape
  > TEST: Verify Shellwords Usage
  > Type: Action Validation
  > Assert: Shellwords.escape is used instead of custom method
  > Command: cd dev-tools && grep -n "Shellwords.escape" lib/coding_agent_tools/atoms/taskflow_management/shell_command_executor.rb
- [ ] Step 3: Remove the custom escape_argument method
  - Delete the entire method definition
  - Ensure no references remain
- [ ] Step 4: Update any helper method that wraps escaping
  - If there's a convenience method, update it to use Shellwords
- [ ] Step 5: Test with edge cases
  - Test with quotes, spaces, special characters
  - Ensure proper escaping for all shell metacharacters
- [ ] Step 6: Run existing tests
  > TEST: All Tests Pass
  > Type: Integration Test
  > Assert: ShellCommandExecutor tests pass with new implementation
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/taskflow_management/shell_command_executor_spec.rb
- [ ] Step 7: Verify no breaking changes
  > TEST: Integration Check
  > Type: Functional Test
  > Assert: Components using ShellCommandExecutor still work
  > Command: cd dev-tools && grep -r "ShellCommandExecutor" --include="*.rb" | head -5

## Acceptance Criteria

- [ ] AC 1: Custom escape_argument method is removed
- [ ] AC 2: All escaping uses Shellwords.escape from standard library
- [ ] AC 3: All edge cases are properly handled (quotes, spaces, metacharacters)
- [ ] AC 4: All existing tests pass
- [ ] AC 5: No breaking changes for consumers of ShellCommandExecutor
- [ ] AC 6: Security is improved with more robust escaping

## Out of Scope

- ❌ Changing the public interface of ShellCommandExecutor
- ❌ Adding new shell command features
- ❌ Modifying command execution logic beyond escaping

## References

- Code review report: dev-taskflow/current/v.0.3.0-workflows/code_review/code-dev-tools-lib-20250724-184702/cr-report-gpro.md (lines 133-138)
- Ruby Shellwords documentation
- Shell command injection prevention best practices