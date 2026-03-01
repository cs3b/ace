---
name: task/manage-status
allowed-tools: Bash, Read
description: Manage task lifecycle status (start, done, undone)
argument-hint: "[action] [task-ref]"
bundle:
  params:
    output: cache
  embed_document_source: true
variables:
  task_ref: Task reference to update (e.g., "019", "121.01")
  action: Status action (start, done, undone)
doc-type: workflow
purpose: Change task status through its lifecycle from pending to in-progress to completed
update:
  frequency: on-change
  last-updated: '2026-02-14'
---

# Manage Task Status

Control task lifecycle using `ace-task` status commands.

## Goal

Provide a simple interface for updating task status as work progresses:
- Mark tasks as in-progress when starting work
- Mark tasks as done when completed
- Reopen tasks when work needs to continue

## Status Actions

### Action 1: Start Task (`task start`)

Mark a task as in-progress to indicate active work.

**When to use**: When you begin working on a task.

**Command**:
```bash
ace-task start <task_ref>
```

**Example**:
```bash
# Start working on task 121
ace-task start 121

# Start working on subtask 121.01
ace-task start 121.01
```

**What happens**:
1. Task status is set to `in_progress`
2. Frontmatter is updated
3. Task appears in "in progress" filters

### Action 2: Complete Task (`task done`)

Mark a task as completed when all work is finished.

**When to use**: When a task's acceptance criteria are met and work is complete.

**Command**:
```bash
ace-task done <task_ref>
```

**Example**:
```bash
# Mark task 121 as complete
ace-task done 121

# Mark subtask 121.01 as complete
ace-task done 121.01
```

**What happens**:
1. Task status is set to `completed`
2. Frontmatter is updated
3. Task appears in "completed" filters
4. Task is removed from active work lists

### Action 3: Reopen Task (`task undone`)

Reopen a completed task to continue work.

**When to use**: When a completed task needs additional work (bugs found, requirements changed).

**Command**:
```bash
ace-task undone <task_ref>
```

**Example**:
```bash
# Reopen task 121
ace-task undone 121

# Reopen subtask 121.01
ace-task undone 121.01
```

**What happens**:
1. Task status is set to `pending` (or `in_progress` if appropriate)
2. Frontmatter is updated
3. Task returns to active work lists

## Decision Guide

| Scenario | Action | Command |
|----------|--------|---------|
| Starting work on a task | Start | `task start 121` |
| Task acceptance criteria met | Done | `task done 121` |
| Need to continue completed work | Undone | `task undone 121` |
| Found regression after completion | Undone | `task undone 121` |
| Ready to review but not merge | Done | `task done 121` (review is separate) |

## Workflow Integration

### Before Starting

Before marking a task as started:
1. Ensure you understand the task requirements
2. Check for any blockers or dependencies
3. Verify the task scope is clear

### After Completing

After marking a task as done:
1. Run `ace-task show <ref>` to verify status
2. Check if parent orchestrator needs status update
3. Consider if related tasks should be updated

### Orchestrator Tasks

For orchestrator tasks with subtasks:
- Mark subtasks done as you complete them
- Orchestrator status typically reflects aggregate subtask status
- Use `ace-task show <orchestrator_ref>` to see full progress

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "task not found" | Invalid task reference | Verify task ID with `task list` |
| "already in_progress" | Starting already started task | No action needed |
| "already completed" | Completing already done task | No action needed |
| "cannot reopen" | Task in invalid state | Check task file for corruption |

## Related Commands

- `ace-task show <ref>` - View task details and current status
- `ace-task list --status in_progress` - List all in-progress tasks
- `ace-task list --status completed` - List all completed tasks

## Success Criteria

* Task status correctly reflects current work state
* Frontmatter metadata is updated
* Task appears in correct status filters
* Changes are committed if using version-controlled task files
