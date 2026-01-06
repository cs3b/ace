# ace-taskflow status - Recently Done Section

## Overview

The `ace-taskflow status` command provides visibility into project progress, including:
- Release summary (name, task count, completion percentage)
- Current task detection from branch name
- Task activity (Recently Done, In Progress, Up Next)

This document focuses on the "Recently Done" section behavior after the fix.

## Command Structure

```bash
ace-taskflow status [--json]
```

**Options:**
- `--json` - Output in JSON format for programmatic consumption
- `--quiet` / `-q` - Suppress config summary
- `--verbose` / `-v` - Show additional details

## Expected Behavior (After Fix)

### Scenario 1: Viewing Recently Completed Tasks

**Goal:** See what tasks were completed most recently

**Command:**
```bash
ace-taskflow status
```

**Expected Output:**
```markdown
# Taskflow Status

## Release: v.0.9.0: 144/147 tasks done - Mono-Repo Multiple Gems

No task pattern detected in branch name.

## Task Activity

### Recently Done
- 150: CLI Standardization - Thor migration and ConfigSummary (done 4h ago)
- 150.37: Update ace-review CHANGELOG (done 5h ago)
- 150.36: Update ace-prompt CHANGELOG (done 5h ago)

### In Progress
- 002: Create Root Gemfile for Workspace

### Up Next
- 149: Base36 Compact ID Format Implementation
```

**Key Behaviors:**
- Tasks sorted by file modification time (most recent first)
- Both orchestrator tasks (150) and subtasks (150.37) appear
- Relative timestamps reflect actual completion time ("4h ago", "1d ago")

### Scenario 2: Many Tasks Completed in Bulk

**Goal:** After merging a PR with many task completions

**Context:** Task 150 orchestrator has 37 subtasks, all completed around the same time.

**Expected Output:**
```markdown
### Recently Done
- 150: CLI Standardization (done 4h ago)
- 150.37: Update ace-review CHANGELOG (done 4h ago)
- 150.36: Update ace-prompt CHANGELOG (done 4h ago)
```

**Key Behaviors:**
- Most recently modified files appear first
- Both parent and child tasks visible (up to configured limit)
- Limit is configurable via `status.activity.recently_done_limit` (default: 3)

### Scenario 3: Task Completed After Git Operations

**Goal:** Verify that git worktree merges preserve correct file mtimes

**Context:** After `git checkout` or `git merge` operations

**Expected Output:**
The "Recently Done" section should still show the tasks in order of their actual completion time, as determined by file mtime.

**Key Behaviors:**
- Git operations may affect file mtimes, but the relative ordering should remain accurate
- Tasks merged from worktrees appear with their merge time

### Scenario 4: JSON Output for Automation

**Goal:** Programmatically access recently done tasks

**Command:**
```bash
ace-taskflow status --json
```

**Expected Output (excerpt):**
```json
{
  "activity": {
    "recently_done": [
      {
        "id": "v.0.9.0+task.150",
        "title": "CLI Standardization",
        "completed_at": "2026-01-05T21:04:17Z",
        "relative_time": "done 4h ago"
      }
    ]
  }
}
```

## Configuration Reference

Settings in `.ace/taskflow/config.yml`:

```yaml
taskflow:
  status:
    activity:
      recently_done_limit: 3     # Max tasks to show (0 to disable)
      up_next_limit: 3           # Max upcoming tasks (0 to disable)
      include_drafts: false      # Include drafts in "Up Next"
```

## Time Display Format

Relative timestamps follow this pattern:
- `done Xm ago` - Minutes (< 60 minutes)
- `done Xh ago` - Hours (< 24 hours)
- `done Xd ago` - Days (>= 24 hours)

## Technical Notes

### File Mtime as Completion Time

The "Recently Done" section uses file modification time (`File.mtime`) to determine when tasks were completed. This works because:

1. When `ace-taskflow task done` moves a task to the archive, the file is modified
2. Git operations that update task status change the file mtime
3. PR merges that include task file changes update mtimes

### Dependency-Aware Sorting

The fix ensures that when sorting by `:modified` for the "Recently Done" section:
- Dependency-aware sorting is bypassed for done tasks (dependencies don't matter for completed work)
- OR the dependency resolver properly handles `:modified` as a sort criterion

## Troubleshooting

### Tasks Not Appearing in Recently Done

**Check 1:** Verify task status is `done` or `completed`
```bash
ace-taskflow task 150
# Look for "status: done"
```

**Check 2:** Verify file mtime is recent
```bash
stat -f "%Sm" .ace-taskflow/v.0.9.0/tasks/_archive/150-*/150.00-*.s.md
```

**Check 3:** Ensure task is in the archive directory
```bash
ls .ace-taskflow/v.0.9.0/tasks/_archive/
```

### Incorrect Ordering

If tasks appear in wrong order despite correct mtimes, this may indicate the bug is still present. The fix ensures `dependency_aware_sort` properly handles the `:modified` sort criterion.
