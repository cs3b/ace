---
id: v.0.3.0+task.106
status: in-progress
priority: high
estimate: 3h
dependencies: []
---

# Fix Git-Commit Main Repository Command Context Issue

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/molecules/git | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/molecules/git
    ├── commit_message_generator.rb
    ├── concurrent_executor.rb
    ├── multi_repo_coordinator.rb
    └── path_dispatcher.rb
```

## Objective

Fix the critical inconsistency in git-commit tool where main repository uses `git commit` without context flag while submodules correctly use `git -C <path> commit`. This inconsistency causes:

1. **Context-dependent failures**: Main repo commands fail when executed from submodule directories
2. **False error reporting**: Commands succeed but report "Partial success" errors
3. **Unreliable behavior**: Different execution outcomes depending on current working directory
4. **Developer confusion**: Inconsistent command patterns between repositories

The root cause is in `PathDispatcher.build_command_context()` which treats main repository as a special case without the `-C` flag, making it dependent on current working directory context.

## Scope of Work

- Unify command construction logic to use `git -C <full_path>` for ALL repositories including main
- Remove special-case handling that omits the `-C` flag for main repository
- Ensure all git operations run in their proper repository context regardless of execution directory
- Update related tests to verify consistent behavior across all repository types
- Validate fix resolves the original error condition that triggered this investigation

### Deliverables

#### Create

- None

#### Modify

- `dev-tools/lib/coding_agent_tools/molecules/git/path_dispatcher.rb` - Unify command context building
- `dev-tools/spec/coding_agent_tools/molecules/git/path_dispatcher_spec.rb` - Update tests for new behavior
- Any other test files that depend on the old main repo command format

#### Delete

- None

## Phases

1. **Investigation** - Confirm the current behavior and identify all affected code paths
2. **Implementation** - Modify command construction to be consistent across all repositories
3. **Testing** - Verify fix works from various execution contexts
4. **Validation** - Test original failing scenario to confirm resolution

## Implementation Plan

### Planning Steps

- [ ] Examine current `PathDispatcher.build_command_context()` implementation to understand special-case logic
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current main repo vs submodule command differences are documented
  > Command: cd dev-tools && grep -A 10 -B 5 "repository\[:name\].*main" lib/coding_agent_tools/molecules/git/path_dispatcher.rb
- [ ] Identify all locations that may be affected by changing main repo command format
- [ ] Research any potential side effects of always using `-C` flag for main repository

### Execution Steps

- [ ] Modify `build_command_context()` to use unified command construction for all repositories
  > TEST: Command Context Unification
  > Type: Unit Validation
  > Assert: All repositories now use git -C <full_path> format consistently
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/git/path_dispatcher_spec.rb -f documentation
- [ ] Update existing tests that expect old main repository command format
- [ ] Add comprehensive test cases for command execution from different working directories
- [ ] Test the original failing git-commit command that triggered this issue
  > TEST: Original Issue Resolution
  > Type: Integration Validation
  > Assert: Mixed repository file commits work without false errors
  > Command: git-commit dev-taskflow/current/v.0.3.0-workflows/tasks/v.0.3.0+task.106-fix-git-commit-main-repository-command-context-issue.md dev-tools/lib/coding_agent_tools/molecules/git/path_dispatcher.rb --intention "test unified command context"
- [ ] Verify all git-commit workflows continue to work from various execution contexts

## Acceptance Criteria

- [ ] AC 1: All repositories (main, dev-tools, dev-taskflow, dev-handbook) use consistent `git -C <full_path>` command format
- [ ] AC 2: git-commit commands work reliably regardless of current working directory
- [ ] AC 3: No more false "Partial success" error messages when commits actually succeed
- [ ] AC 4: The original failing command that triggered this investigation now works without errors
- [ ] AC 5: All existing git-commit functionality remains unaffected (backward compatibility)
- [ ] AC 6: Test coverage verifies consistent behavior across all repository types and execution contexts

## Out of Scope

- ❌ Complete rewrite of git-commit architecture
- ❌ Changes to commit message generation logic
- ❌ Performance optimization unrelated to the context issue
- ❌ Adding new git-commit features or flags
- ❌ Modifying other git operations beyond commit workflow

## References

### Root Cause Location
- **File**: `dev-tools/lib/coding_agent_tools/molecules/git/path_dispatcher.rb`
- **Method**: `build_command_context(repository)`
- **Problem**: Special case for main repository omits `-C` flag

### Original Error Context
- **Error observed**: `[main] Error: Git command failed: git commit -m test(models): add comprehensive unit tests for all model classes`
- **Symptom**: "Partial success: Committed in repositories: dev-taskflow, dev-tools" (false error)
- **Actual result**: Commits succeeded in all repositories including main

### Related Tasks
- **Task 105**: Fixed file-to-repository sorting logic (completed)
- **Task 92**: Fixed error message formatting (completed)
- **This task**: Fixes remaining command context inconsistency

### Expected Solution
```ruby
# Before (inconsistent):
if repository[:name] == "main"
  { git_command_prefix: "git", ... }           # No -C flag
else  
  { git_command_prefix: "git -C #{path}", ... } # Has -C flag
end

# After (unified):
escaped_path = Shellwords.escape(repository[:full_path])
{ git_command_prefix: "git -C #{escaped_path}", ... } # Always has -C flag
```