---
name: task/reorganize
allowed-tools: Bash, Read
description: Reorganize task hierarchy using promote, demote, and convert operations
argument-hint: "[operation] [task-ref] [parent-ref]"
bundle:
  params:
    output: cache
  embed_document_source: true
variables:
  task_ref: Task reference to reorganize (e.g., "019", "121.01")
  target_parent: Target parent task for demote operation (e.g., "121")
  operation: Operation type (promote, demote, convert-orchestrator)
doc-type: workflow
purpose: Restructure task hierarchy by promoting subtasks to standalone, demoting tasks
  to subtasks, or converting standalone tasks to orchestrators
update:
  frequency: on-change
  last-updated: '2025-12-09'
---

# Reorganize Tasks

Restructure task hierarchy using the `ace-task move` command with `--child-of` flag.

## Goal

Provide flexible task reorganization to adapt task structure as understanding evolves, including:
- Promoting subtasks to standalone tasks
- Demoting standalone tasks to subtasks under a parent
- Converting standalone tasks to orchestrators (to add subtasks later)

## Operations

### Operation 1: Promote Subtask to Standalone

Convert a subtask (e.g., `121.01`) to a standalone task with a new number and directory.

**When to use**: When a subtask has grown too large or independent to remain a subtask.

**Command**:
```bash
ace-task move <subtask_ref> --child-of
```

**Example**:
```bash
# Promote subtask 121.01 to standalone task
ace-task move 121.01 --child-of

# With dry-run to preview
ace-task move 121.01 --child-of --dry-run
```

**What happens**:
1. Subtask file is copied to a new standalone task directory
2. New task number is assigned (globally unique)
3. ID is updated to new standalone format
4. `parent` field is removed from frontmatter
5. Original subtask file is deleted

**Output**:
```
Promoted subtask v.0.9.0+task.121.01 to standalone task v.0.9.0+task.155
New reference: v.0.9.0+task.155
Path: .ace-tasks/v.0.9.0/tasks/155-promoted-task/155-promoted-task.s.md
```

### Operation 2: Demote Task to Subtask

Convert a standalone task to a subtask under a parent orchestrator.

**When to use**: When a task should be part of a larger orchestrated effort.

**Prerequisites**: The target parent must be an orchestrator (have `NNN-orchestrator.s.md` file or subtask files).

**Command**:
```bash
ace-task move <task_ref> --child-of <parent_ref>
```

**Example**:
```bash
# Demote task 019 to subtask under orchestrator 121
ace-task move 019 --child-of 121

# With dry-run to preview
ace-task move 019 --child-of 121 --dry-run
```

**What happens**:
1. Task file is copied to parent task's directory
2. Next available subtask number is assigned (e.g., `121.03`)
3. ID is updated to subtask format
4. `parent` field is added to frontmatter
5. Auxiliary files (docs/, notes, etc.) are preserved and copied to parent directory
6. Original task directory is deleted

**Output**:
```
Demoted task v.0.9.0+task.019 to subtask v.0.9.0+task.121.03
New reference: v.0.9.0+task.121.03
Path: .ace-tasks/v.0.9.0/tasks/121-orchestrator/121.03-demoted-task.s.md
```

### Operation 3: Convert to Orchestrator

Convert a standalone task to an orchestrator, with the original task becoming the first subtask (.01).

**When to use**: When a task needs to be broken into subtasks for parallel work.

**Command**:
```bash
ace-task move <task_ref> --child-of self
```

**Example**:
```bash
# Convert task 019 to orchestrator
ace-task move 019 --child-of self

# With dry-run to preview
ace-task move 019 --child-of self --dry-run
```

**What happens**:
1. New orchestrator file created (`NNN-orchestrator.s.md`) with overview template
2. Original task becomes subtask `.01` with same content
3. Subtask ID updated (e.g., `v.0.9.0+task.019` → `v.0.9.0+task.019.01`)
4. Parent field added to subtask frontmatter
5. Original standalone file deleted
6. Task can now have more subtasks added via `ace-task create --child-of 019`

**Output**:
```
Converted task 019 to orchestrator with subtask .01
Subtask: v.0.9.0+task.019.01
Orchestrator: .ace-tasks/v.0.9.0/tasks/019-task-slug/019-orchestrator.s.md
Subtask file: .ace-tasks/v.0.9.0/tasks/019-task-slug/019.01-task-slug.s.md
```

## Common Options

### Dry-Run Mode

Preview any operation without making changes:

```bash
ace-task move <ref> [options] --dry-run
ace-task move <ref> [options] -n
```

Dry-run shows:
- Operations that would be performed
- New reference that would be assigned
- New path that would be created

### Release Move (Legacy)

Move tasks between releases (this is the original `move` behavior):

```bash
# Move to specific release
ace-task move 019 --release v.0.10.0

# Move to backlog
ace-task move 019 --backlog

# Legacy positional syntax still works
ace-task move 019 backlog
```

## Decision Guide

| Scenario | Operation | Command |
|----------|-----------|---------|
| Subtask outgrew its parent | Promote | `task move 121.01 --child-of` |
| Task should join an orchestrator | Demote | `task move 019 --child-of 121` |
| Task needs to be split | Convert | `task move 019 --child-of self` |
| Move to different release | Release move | `task move 019 --release v.0.10.0` |

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "not a subtask" | Trying to promote non-subtask | Only subtasks can be promoted |
| "already a subtask" | Task is already a child | Already in correct structure |
| "already an orchestrator" | Task already has subtasks | Already in correct structure |
| "subtask limit reached" | 99 subtasks already exist | Promote some subtasks first |

## Workflow Integration

### After Promotion

After promoting a subtask:
1. Update any references to the old subtask ID in other tasks
2. Consider updating the orchestrator's scope
3. Run `ace-task show <new_ref>` to verify

### After Demotion

After demoting a task:
1. Check if dependencies need updating
2. Subtask inherits orchestrator's release
3. Run `ace-task show <parent_ref>` to see full structure

### After Conversion

After converting to orchestrator:
1. Create subtasks: `ace-task create --child-of <ref> "Subtask title"`
2. Original task becomes the orchestrator file (`NNN-orchestrator.s.md`)
3. Consider adding orchestrator scope/description

## Success Criteria

* Task reorganized with appropriate new ID format
* Old task/subtask file properly cleaned up
* Metadata updated (parent field added/removed as appropriate)
* New location accessible via `ace-task show`
* Dry-run accurately previews operations
