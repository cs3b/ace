# Task 056: Add informative output to ace-git-commit

## Status
- **State**: done
- **Priority**: P2
- **Estimate**: 2-3 hours
- **Created**: 2025-10-01
- **Started**: 2025-10-01
- **Completed**: 2025-10-01

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

**Expected behavior:**
```
❯ ace-git-commit
39a9e5fa (HEAD -> main) feat(task): Draft task 056 - Add informative output to ace-git-commit
 .ace-taskflow/v.0.9.0/ideas/20250930-105556-we-have-not-info-about-what-files-have-been-commit.md |  34 -----------------------
 .cache/ace-context/project.md                                                                     | 100 +++++++++++++++++++++++++++++++++++++++++--------------------------
 ace-taskflow/lib/ace/taskflow/molecules/release_resolver.rb                                       |   6 ++--
 ace-taskflow/test/commands/release_command_test.rb                                                |  19 +++++++------
 ace-taskflow/test/commands/task_command_test.rb                                                   |   6 ++--
 ace-taskflow/test/commands/tasks_command_test.rb                                                  |   4 +--
 ace-taskflow/test/support/test_factory.rb                                                         |  10 ++++---
 7 files changed, 87 insertions(+), 92 deletions(-)
```

Format: `git log --oneline HEAD -1` followed by `git diff --stat HEAD~1 HEAD` output

## Idea Reference
- Source: `.ace-taskflow/v.0.9.0/docs/ideas/056-20250930-105556-we-have-not-info-about-what-files-have-been-commit.md`

## Solution Design

### Output Format

Use git's native formatting commands to build the summary:

```
<commit-hash> (<refs>) <commit-message-first-line>
 <file-path> | <changes-count> <+/->
 <file-path> | <changes-count> <+/->
 ...
 N files changed, X insertions(+), Y deletions(-)
```

Commands to use:
- `git log --oneline HEAD -1` - Get commit hash, refs, and message
- `git diff --stat HEAD~1 HEAD` - Get file-by-file stats with visual bars

### Implementation Approach

**Option 1: Parse git commit output**
- Capture stderr from `git commit` (where the summary goes)
- Parse and display it to stdout
- Pros: Matches git exactly, no custom formatting
- Cons: Parsing git output, harder to extend for multi-commit scenarios

**Option 2: Build summary from git operations (SELECTED)**
- After commit, run `git log --oneline HEAD -1` and `git diff --stat HEAD~1 HEAD`
- Display the output directly (already formatted by git)
- Pros: Clean separation, uses git APIs, extensible for future multi-commit operations
- Cons: Two extra git commands after commit

**Decision: Option 2** - Better supports future multi-commit scenarios where we'll display summary for each commit made

### Changes Required

1. **ace-git-commit/lib/ace/git_commit/molecules/commit_summarizer.rb** (NEW)
   - Create new molecule for generating commit summaries
   - Method: `summarize(commit_sha)`
   - Runs `git log --oneline <sha> -1`
   - Runs `git diff --stat <sha>~1 <sha>`
   - Returns combined output string

2. **ace-git-commit/lib/ace/git_commit/organisms/commit_orchestrator.rb**
   - After successful commit in `perform_commit`:
     - Get commit SHA from `git rev-parse HEAD`
     - Call `CommitSummarizer.summarize(sha)`
     - Output summary to stdout
   - Handle dry-run mode (show "would commit" instead of summary)
   - Handle debug mode (show both debug info and summary)

3. **Tests to add/update:**
   - `test/molecules/commit_summarizer_test.rb` (NEW)
   - `test/organisms/commit_orchestrator_test.rb` - verify summary display
   - Add integration test for full commit workflow with output

### Edge Cases
- Empty commits (git diff will show nothing, that's fine)
- Large commits (100+ files) - git handles this well with summary line
- Binary files - shown in diff stat
- Renamed files - shown in diff stat
- First commit in repo (no parent, use `git show --stat` instead)
- Dry-run mode (skip summary, already shows "would commit" message)
- Debug mode (show both debug info and commit summary)

## Acceptance Criteria

- [x] ace-git-commit displays commit summary using git's native formatting
- [x] Shows commit hash with refs (e.g., `39a9e5fa (HEAD -> main)`)
- [x] Shows commit message first line
- [x] Shows per-file diff stats with visual bars
- [x] Shows summary line (N files changed, X insertions(+), Y deletions(-))
- [x] Works in normal mode
- [x] Works in --dry-run mode (no summary, keeps existing behavior)
- [x] Works in --debug mode (shows both debug info and summary)
- [x] Handles first commit in repo (no parent commit)
- [x] Error messages still go to stderr
- [x] Exit codes remain unchanged
- [x] All existing tests pass
- [x] New CommitSummarizer molecule has full test coverage
- [x] Output supports future multi-commit operations

## Implementation Plan

### Phase 1: Create CommitSummarizer molecule (45 min)
1. Create `lib/ace/git_commit/molecules/commit_summarizer.rb`
2. Implement `summarize(commit_sha, git_executor)` method:
   - Run `git log --oneline <sha> -1`
   - Run `git diff --stat <sha>~1 <sha>` (or `git show --stat <sha>` for first commit)
   - Combine outputs with newline
3. Handle first commit edge case (no parent)
4. Create `test/molecules/commit_summarizer_test.rb` with full coverage

### Phase 2: Update commit_orchestrator (30 min)
1. After successful commit in `perform_commit`:
   - Get commit SHA: `git rev-parse HEAD`
   - Create CommitSummarizer instance
   - Call `summarizer.summarize(sha, @git)`
   - Output summary to stdout (not in dry-run mode)
2. Keep existing debug mode behavior

### Phase 3: Testing and validation (45 min)
1. Update `test/organisms/commit_orchestrator_test.rb`
2. Add integration test for full commit workflow
3. Test edge cases:
   - First commit in repo
   - Large commits
   - Empty commits
   - Dry-run mode
   - Debug mode
4. Manual testing with real commits

## Testing Strategy

### Unit Tests
```ruby
# test/molecules/commit_summarizer_test.rb
def test_summarize_returns_formatted_output
  summarizer = CommitSummarizer.new
  output = summarizer.summarize("HEAD", git_executor)

  assert_match /^[a-f0-9]{8}/, output  # commit hash
  assert_match /\d+ files? changed/, output  # summary line
end

def test_summarize_handles_first_commit
  # Test with repo that has only one commit
  # Should use git show instead of git diff
end

# test/organisms/commit_orchestrator_test.rb
def test_displays_commit_summary_after_commit
  output = capture_stdout do
    orchestrator.execute(options)
  end

  assert_match /^[a-f0-9]{8}/, output  # commit hash
  assert_match /\d+ files? changed/, output  # summary
  refute_match /Committing\.\.\./, output unless options.debug
end

def test_no_summary_in_dry_run_mode
  options.dry_run = true
  output = capture_stdout do
    orchestrator.execute(options)
  end

  refute_match /^[a-f0-9]{8}/, output  # no commit hash
  assert_match /=== DRY RUN ===/, output
end
```

### Integration Tests
```ruby
def test_full_commit_workflow_with_output
  # Setup repo with changes
  # Run ace-git-commit
  # Verify output contains:
  #   - commit hash and refs
  #   - commit message
  #   - file stats
  #   - summary line
end
```

## Dependencies
- None (self-contained enhancement)

## Related
- Improved user experience
- Better debugging capability
- Consistency with git CLI
