---
id: v.0.9.0+task.222
status: draft
priority: medium
estimate: 2h
dependencies: []
---

# Fix worktree target_branch to use current branch when parent has no worktree

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-git-worktree create --task XXX.YY` from a branch with an open PR (e.g., `216-add-rubocop-as-fallback-for-standardrb`)
- **Process**: The command creates a worktree for the subtask. The subtask's parent task (XXX) may not have its own worktree metadata. The system should intelligently determine the target branch for the new worktree's PR.
- **Output**: The created worktree's `target_branch` metadata should reflect the current branch (the branch the user is working from), not default to `main`

### Expected Behavior
When a user creates a worktree for a subtask from a branch that has an open PR:
1. The system attempts to resolve the target branch from the parent task's worktree metadata
2. If the parent task has no worktree metadata, the system should use the **current branch** as the target branch
3. Only if there is no current branch (detached HEAD) should it fall back to "main"
4. The `target_branch` field in the task's worktree metadata should correctly reflect this resolution

**Example Scenario**:
```bash
# User is on branch 216-add-rubocop-as-fallback-for-standardrb (task 216 with open PR)
ace-git-worktree create --task 215.03

# Expected: target_branch = "216-add-rubocop-as-fallback-for-standardrb"
# Actual (buggy):   target_branch = "main"
```

### Interface Contract

```bash
# CLI Interface
ace-git-worktree create --task <task_id> [--target-branch <branch>]

# Expected Behavior:
# - When --target-branch is provided: use that value (existing override behavior)
# - When parent task has worktree: use parent's worktree branch (existing behavior)
# - When parent has no worktree but current branch exists: use current branch (NEW)
# - When parent has no worktree and no current branch: use "main" (fallback)

# Task file output (worktree section):
worktree:
  branch: "215.03-multi-validator-architecture-for-ace-lint"
  path: "../ace-task.215.03"
  target_branch: "216-add-rubocop-as-fallback-for-standardrb"  # Should be current branch, not "main"
```

**Error Handling:**
- Current branch detection fails: Fall back to "main"
- Parent task not found: Fall back to current branch or "main"
- Detached HEAD state: Use "main" as target branch

**Edge Cases:**
- Parent task converted to orchestrator without worktree: Use current branch
- Multiple nested subtasks: Each should use its parent's branch or current branch
- User explicitly provides `--target-branch`: Override all auto-detection (existing behavior)

### Success Criteria
- [ ] **Behavioral Outcome 1**: When creating a worktree for a subtask from branch X, and the parent task has no worktree, the new worktree's `target_branch` is set to X (not "main")
- [ ] **User Experience Goal 2**: Users creating related worktrees from their current branch don't need to manually specify `--target-branch` to avoid defaulting to "main"
- [ ] **Backward Compatibility 3**: Existing behavior is preserved when parent task has worktree metadata (uses parent's branch)
- [ ] **Manual Override 4**: The `--target-branch` flag still works as expected to override auto-detection

### Validation Questions
- [ ] **Requirement Clarity**: Should the current branch be used as fallback in ALL cases where parent has no worktree, or only when the current branch has an associated PR?
- [ ] **Edge Case Handling**: What should happen if the current branch is "main" itself - should we still set target_branch to "main" or omit it?
- [ ] **User Experience**: Is the current branch behavior intuitive, or should we provide a warning message when falling back to current branch?

## Objective

Users creating subtasks from their current working branch expect the new worktree to target their current branch for PR purposes, not default to "main". This is especially common when working on related features across multiple task branches.

## Scope of Work

- **User Experience Scope**: `ace-git-worktree create --task` command behavior when parent task lacks worktree metadata
- **System Behavior Scope**: `ParentTaskResolver#resolve_target_branch` method's fallback logic
- **Interface Scope**: CLI command output and task file `worktree.target_branch` field

### Deliverables

#### Behavioral Specifications
- Current branch detection as intermediate fallback
- Updated resolution priority order for target_branch
- Clear documentation of fallback behavior

#### Validation Artifacts
- Unit tests for current branch fallback scenarios
- Integration test for the reported bug scenario
- Edge case coverage (detached HEAD, explicit override)

## Out of Scope

- **Implementation Details**: Specific code structure changes (implementation will handle this)
- **Technology Decisions**: Whether to use ace-git's current branch detection vs direct git commands
- **Performance Optimization**: Caching of branch detection results
- **Future Enhancements**: Automatic PR base detection from GitHub API

## Implementation Plan

### Technical Research Summary

**Current Implementation Reviewed:**
- `ParentTaskResolver#resolve_target_branch` (line 47-63) implements fallback logic
- Current resolution order: parent's worktree branch → DEFAULT_TARGET ("main")
- `GitCommand.current_branch` (line 93-97) is available and handles detached HEAD by returning SHA
- Tests use `MockTaskFetcher` pattern for dependency injection

**Key Finding:**
- Line 79-88 (`extract_parent_branch`): Returns `DEFAULT_TARGET` when parent has no worktree
- This is where we need to add current branch as intermediate fallback

### File Modifications

#### Modify: `ace-git-worktree/lib/ace/git/worktree/molecules/parent_task_resolver.rb`

**Changes:**
1. Add require statement at top (after line 4):
   ```ruby
   require_relative "../atoms/git_command"
   ```

2. Add new private helper method after line 118:
   ```ruby
   # Get current branch as fallback for target branch
   #
   # @return [String, nil] Current branch name, or nil if detached HEAD or error
   def current_branch_fallback
     Atoms::GitCommand.current_branch
   rescue StandardError
     nil
   end
   ```

3. Modify `extract_parent_branch` method (line 79-88):
   ```ruby
   def extract_parent_branch(parent_data)
     return DEFAULT_TARGET unless parent_data

     # Support both symbol and string keys for compatibility
     worktree_data = parent_data[:worktree] || parent_data["worktree"]
     return current_branch_fallback || DEFAULT_TARGET unless worktree_data.is_a?(Hash)

     # Return parent's worktree branch (support both key types)
     parent_branch = worktree_data[:branch] || worktree_data["branch"]
     parent_branch || (current_branch_fallback || DEFAULT_TARGET)
   end
   ```

#### Modify: `ace-git-worktree/test/molecules/parent_task_resolver_test.rb`

**Add new test methods** after line 191:

```ruby
def test_current_branch_fallback_when_parent_has_no_worktree
  # Mock GitCommand to return specific branch
  mock_git_command = Object.new
  def mock_git_command.current_branch
    "216-add-rubocop-as-fallback-for-standardrb"
  end

  parent_task = {
    "id" => "v.0.9.0+task.216",
    "title" => "Parent Task"
    # No worktree metadata
  }

  subtask_data = {
    id: "v.0.9.0+task.216.01",
    title: "Subtask 01"
  }

  # Stub GitCommand.current_branch
  Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "216-add-rubocop-as-fallback-for-standardrb") do
    resolver = create_resolver("216" => parent_task)
    result = resolver.resolve_target_branch(subtask_data)
    assert_equal "216-add-rubocop-as-fallback-for-standardrb", result
  end
end

def test_main_fallback_when_detached_head
  parent_task = {
    "id" => "v.0.9.0+task.216",
    "title" => "Parent Task"
  }

  subtask_data = {
    id: "v.0.9.0+task.216.01",
    title: "Subtask 01"
  }

  # Mock current_branch returning nil (detached HEAD simulation)
  Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, nil) do
    resolver = create_resolver("216" => parent_task)
    result = resolver.resolve_target_branch(subtask_data)
    assert_equal "main", result
  end
end

def test_parent_worktree_branch_takes_precedence_over_current_branch
  parent_task = {
    "id" => "v.0.9.0+task.216",
    "title" => "Parent Task",
    "worktree" => {
      "branch" => "216-parent-worktree-branch"
    }
  }

  subtask_data = {
    id: "v.0.9.0+task.216.01",
    title: "Subtask 01"
  }

  # Even though current branch is different, parent's worktree branch takes precedence
  Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "different-current-branch") do
    resolver = create_resolver("216" => parent_task)
    result = resolver.resolve_target_branch(subtask_data)
    assert_equal "216-parent-worktree-branch", result
  end
end
```

### Implementation Steps

1. Add require statement for GitCommand atom
2. Create `current_branch_fallback` helper method with error handling
3. Modify `extract_parent_branch` to add current branch fallback at two points:
   - When parent has no worktree metadata
   - When parent worktree exists but has no branch field
4. Add unit tests covering:
   - Current branch fallback when parent has no worktree
   - "main" fallback when detached HEAD (current_branch returns nil)
   - Parent worktree branch precedence over current branch
5. Run `ace-test` in ace-git-worktree package to verify

### Verification Plan

**Automated:**
- Run `ace-test` in ace-git-worktree package

**Manual:**
1. Create scenario matching bug report:
   ```bash
   # From branch 216-add-rubocop-as-fallback-for-standardrb
   ace-git-worktree create --task 215.03
   # Verify target_branch in task file shows "216-add-rubocop..." not "main"
   ```

### Edge Cases Handled

- **Detached HEAD**: `current_branch` returns nil/SHA → falls back to "main"
- **Git command failure**: Exception in `current_branch_fallback` → returns nil → falls back to "main"
- **Parent worktree exists**: Still uses parent's branch (backward compatible)
- **User provides --target-branch**: Handled by CLI before calling resolver (unchanged)

## References

- Plan file: `/Users/mc/.claude/plans/memoized-chasing-sun.md`
- Bug report: User reported creating worktree for task 215.03 from branch 216 resulted in target_branch=main instead of 216
- Related file: `ace-git-worktree/lib/ace/git/worktree/molecules/parent_task_resolver.rb`
