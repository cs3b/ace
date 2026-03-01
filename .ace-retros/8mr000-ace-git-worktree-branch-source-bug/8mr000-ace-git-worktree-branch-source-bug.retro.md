---
id: 8mr000
title: ace-git-worktree Branch Source Bug
type: standard
tags: []
created_at: "2025-11-28 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8mr000-ace-git-worktree-branch-source-bug.md
---
# Reflection: ace-git-worktree Branch Source Bug

**Date**: 2025-11-28
**Context**: Critical bug discovered in ace-git-worktree - subtask branches created from wrong source
**Author**: Claude + User
**Type**: Bug Analysis

## Problem Summary

During orchestrator task 121 (ace-prompt), subtask 121.02 branch was created from `main` instead of from the parent orchestrator branch (`121-ace-prompt-prompt-workspace-orchestrator`).

**Impact:**
- Branch 121.02 was missing 11 commits from parent (including 121.01 work)
- Had duplicate ace-git-worktree commit that was already in parent
- Required manual fixup after merge

## Root Cause Analysis

### The Bug

In `ace-git-worktree/lib/ace/git/worktree/molecules/worktree_creator.rb:323`:

```ruby
result = Atoms::GitCommand.worktree("add", worktree_path, "-b", branch_name, timeout: @timeout)
```

This calls `git worktree add <path> -b <branch>` **without a start-point**.

### Git Behavior

- `git worktree add <path> -b <branch>` → creates from **HEAD of main worktree**
- `git worktree add <path> -b <branch> <start-point>` → creates from **specified commit/branch**

### What Happened

1. User was on branch `121-ace-prompt-prompt-workspace-orchestrator` (parent)
2. Ran `ace-git-worktree create --task 121.02`
3. ace-git-worktree executed: `git worktree add /path -b 121.02-branch`
4. Git created new branch from HEAD of **main worktree** (which was on `main`)
5. Result: 121.02 branch based on `main`, not on parent orchestrator branch

## What Went Well

- Bug was caught during PR review
- User identified the commit discrepancy
- Manual workaround was possible (merge fixed it)

## What Could Be Improved

- ace-git-worktree should use current branch as source, not main worktree HEAD
- Should have verification step to confirm branch ancestry
- PR diff should show warning if commits are missing from expected parent

## Key Learnings

1. **Git worktree default behavior is surprising** - uses main worktree HEAD, not current directory's branch
2. **Orchestrator workflow requires branch inheritance** - subtasks must branch from parent, not main
3. **Need explicit start-point** - never rely on implicit HEAD for worktree creation

## Action Items

### Stop Doing

- Relying on implicit HEAD for `git worktree add -b`
- Assuming current directory branch is used as source

### Start Doing

- **Fix ace-git-worktree**: Add explicit start-point to worktree creation
- **Add `--source` flag**: Allow specifying source branch explicitly
- **Default to current branch**: Detect current branch and use as start-point
- **Add validation**: Warn if creating subtask branch that doesn't include parent commits

## Technical Details

### Proposed Fix

In `worktree_creator.rb`, change:

```ruby
# Current (buggy)
result = Atoms::GitCommand.worktree("add", worktree_path, "-b", branch_name, timeout: @timeout)

# Fixed - use current branch as start-point
current_branch = Atoms::GitCommand.execute("rev-parse", "--abbrev-ref", "HEAD")[:output].strip
result = Atoms::GitCommand.worktree("add", worktree_path, "-b", branch_name, current_branch, timeout: @timeout)
```

### Alternative: Add --source flag

```bash
# Explicit source specification
ace-git-worktree create --task 121.02 --source 121-ace-prompt-prompt-workspace-orchestrator

# Or use current branch (default)
ace-git-worktree create --task 121.02  # uses current branch automatically
```

### For Orchestrator Workflow

When creating subtask worktrees, the orchestrator should:
1. Be on the parent branch
2. Pass parent branch name as source: `--source $(git branch --show-current)`
3. Verify new branch contains all parent commits

## Severity

**HIGH** - This bug causes:
- Incorrect branch ancestry
- Missing commits in subtask branches
- Potential merge conflicts
- Inconsistent codebase state

## Task Proposal

Create new task: **fix-git-worktree-branch-source**
- Fix default behavior to use current branch
- Add `--source` flag for explicit control
- Add validation for orchestrator subtask creation
- Update work-on-subtasks workflow documentation

## Additional Context

- PR #51 was affected (121.02 branch)
- PR #50 was correct (121.01 was first subtask, branched correctly from parent)
- The bug manifests when main worktree is on a different branch than expected
