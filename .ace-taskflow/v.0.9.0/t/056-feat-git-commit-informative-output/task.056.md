# Task 056: Add informative output to ace-git-commit

## Status
- **State**: todo
- **Priority**: P2
- **Estimate**: 2-3 hours
- **Created**: 2025-10-01

## Context

Currently, `ace-git-commit` provides no feedback about what was committed. Users don't know:
- Whether the commit succeeded
- What files were committed
- Statistics about the changes (insertions/deletions)
- The commit hash and branch

This is problematic because:
1. Silent success doesn't confirm the operation completed
2. No visibility into what was actually committed
3. Inconsistent with standard git commit behavior
3. Makes it hard to verify the right files were included

**Example of current behavior:**
```
❯ ace-git-commit
❯ # No output at all
```

**Expected behavior (matching git commit):**
```
❯ ace-git-commit
[main e90676a] feat(taskflow): Add retro management commands
 3 files changed, 145 insertions(+), 2 deletions(-)
 create mode 100644 lib/ace/taskflow/commands/retro.rb
```

## Idea Reference
- Source: `.ace-taskflow/v.0.9.0/docs/ideas/056-20250930-105556-we-have-not-info-about-what-files-have-been-commit.md`

## Solution Design

### Output Format
Match git commit's standard output format:
```
[branch commit-hash] commit-message-first-line
 N files changed, X insertions(+), Y deletions(-)
 create mode <mode> <file>  # for new files
 delete mode <mode> <file>  # for deleted files
 rename <old> => <new>      # for renamed files
```

### Implementation Approach

**Option 1: Parse git commit output (RECOMMENDED)**
- Capture stderr from `git commit` (where the summary goes)
- Parse and display it to stdout
- Pros: Matches git exactly, no custom formatting
- Cons: Parsing git output (but it's stable format)

**Option 2: Build summary from git operations**
- After commit, run `git show --stat --format="%h" HEAD`
- Format and display the information
- Pros: Clean separation, uses git APIs
- Cons: Extra git command, need to format manually

**Decision: Option 1** - Use git's own output for consistency

### Changes Required

1. **ace-git-commit/lib/ace/git_commit/atoms/git_executor.rb**
   - Modify `execute` method to capture stderr separately
   - Return both stdout and stderr
   - Update return type: `{ stdout: String, stderr: String, combined: String }`

2. **ace-git-commit/lib/ace/git_commit/organisms/commit_orchestrator.rb**
   - Update `perform_commit` method to capture commit output
   - Parse stderr for commit summary
   - Display summary to stdout (not just in debug mode)
   - Keep stderr separate for actual errors

3. **Tests to update:**
   - `test/atoms/git_executor_test.rb` - test new return format
   - `test/organisms/commit_orchestrator_test.rb` - verify output display
   - Add integration test that verifies actual commit output

### Edge Cases
- Empty commits (should still show output)
- Large commits (100+ files)
- Binary files
- Renamed files
- Dry-run mode (should show "would commit" message)
- Debug mode (should show both debug info and commit summary)

## Acceptance Criteria

- [ ] ace-git-commit displays commit summary like git commit
- [ ] Shows branch name and commit hash
- [ ] Shows file count and insertion/deletion stats
- [ ] Shows individual file status (create/delete/rename)
- [ ] Works in normal mode
- [ ] Works in --dry-run mode (shows "would commit")
- [ ] Works in --debug mode (shows both debug and summary)
- [ ] Error messages still go to stderr
- [ ] Exit codes remain unchanged
- [ ] All existing tests pass
- [ ] New tests cover output formatting

## Implementation Plan

### Phase 1: Modify git_executor (30 min)
1. Update `execute` method to return structured output
2. Add tests for new return format
3. Ensure backward compatibility with existing callers

### Phase 2: Update commit_orchestrator (45 min)
1. Capture commit output in `perform_commit`
2. Parse and format commit summary
3. Display to stdout
4. Handle edge cases (dry-run, debug modes)

### Phase 3: Testing (45 min)
1. Update existing tests for new behavior
2. Add integration tests for output format
3. Test edge cases (large commits, renames, etc.)
4. Manual testing with various commit scenarios

## Testing Strategy

### Unit Tests
```ruby
# test/atoms/git_executor_test.rb
def test_execute_returns_structured_output
  result = executor.execute("status")
  assert_instance_of Hash, result
  assert_includes result, :stdout
  assert_includes result, :stderr
end

# test/organisms/commit_orchestrator_test.rb
def test_displays_commit_summary
  output = capture_stdout do
    orchestrator.execute(options)
  end
  assert_match /\[main [a-f0-9]{7}\]/, output
  assert_match /\d+ files? changed/, output
end
```

### Integration Tests
```ruby
def test_commit_output_matches_git_format
  # Setup repo with changes
  # Run ace-git-commit
  # Verify output format
end
```

## Dependencies
- None (self-contained enhancement)

## Related
- Improved user experience
- Better debugging capability
- Consistency with git CLI
