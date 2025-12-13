---
id: v.0.9.0+task.154
status: done
priority: low
estimate: 1-2h
dependencies: []
worktree:
  branch: 154-improve-ace-test-error-message-for-file-not-found
  path: "../ace-task.154"
  created_at: '2025-12-13 23:12:58'
  updated_at: '2025-12-13 23:12:58'
---

# Improve ace-test error message for file not found

## Objective

Improve the error message when `ace-test` is given a file path that doesn't exist. Currently it says "Unknown target: <path>" which is confusing because it looks like the tool doesn't support file paths. The message should clearly indicate the file was not found.

## Scope of Work

- Improve error message in `PatternResolver` when target looks like a file path but doesn't exist
- Distinguish between "unknown target name" and "file not found" errors

### Deliverables

#### Modify

- `ace-test-runner/lib/ace/test_runner/molecules/pattern_resolver.rb` - Improve error handling

## Technical Approach

### Current Behavior

In `pattern_resolver.rb:16-29`:
```ruby
def resolve_target(target)
  return resolve_all_files if target.nil? || target == "all"
  return [target] if File.exist?(target)  # Returns if file exists

  # ... pattern/group lookup ...

  # If not found, raises generic error:
  raise ArgumentError, "Unknown target: #{target}. Available targets: #{available_targets.join(', ')}"
end
```

When a user runs `ace-test test/foo_test.rb` from the wrong directory, the file doesn't exist, so the code falls through to the "Unknown target" error.

### Proposed Solution

Detect if the target looks like a file path and provide a specific error:

```ruby
def resolve_target(target)
  return resolve_all_files if target.nil? || target == "all"
  return [target] if File.exist?(target)

  target_key = target.to_s

  if @groups.key?(target_key)
    resolve_group(target_key)
  elsif @patterns.key?(target_key)
    expand_pattern(@patterns[target_key])
  elsif looks_like_file_path?(target)
    # Provide helpful error for file paths
    raise ArgumentError, "File not found: #{target}. " \
      "Make sure you're running from the correct directory or use an absolute path."
  else
    raise ArgumentError, "Unknown target: #{target}. Available targets: #{available_targets.join(', ')}"
  end
end

private

def looks_like_file_path?(target)
  # Check if it looks like a file path (contains / or ends with .rb)
  target.include?("/") || target.end_with?(".rb")
end
```

## Implementation Plan

### Planning Steps

* [x] Identify the source of the confusing error message
* [x] Understand how file path detection works in resolve_target
* [x] Design improved error message

### Execution Steps

- [ ] Step 1: Add `looks_like_file_path?` helper method to PatternResolver
  > TEST: Helper Method
  > Type: Unit Test
  > Assert: Method correctly identifies file paths
  > Command: ace-test atoms

- [ ] Step 2: Update resolve_target to use specific error for file paths
  > TEST: Error Message
  > Type: Unit Test
  > Assert: Shows "File not found" instead of "Unknown target"
  > Command: ace-test molecules

- [ ] Step 3: Add test cases for the new error behavior
  > TEST: All Tests Pass
  > Type: Integration
  > Assert: All ace-test-runner tests pass
  > Command: cd ace-test-runner && ace-test

## Acceptance Criteria

- [ ] Running `ace-test test/nonexistent.rb` shows "File not found: test/nonexistent.rb"
- [ ] Running `ace-test foo/bar/test.rb` shows "File not found" with helpful message
- [ ] Running `ace-test unknown_target` still shows "Unknown target" with available targets
- [ ] All existing tests pass

## References

- Bug discovered: Running `ace-test test/organisms/task_manager_test.rb` from root directory
- Source file: `ace-test-runner/lib/ace/test_runner/molecules/pattern_resolver.rb:28`