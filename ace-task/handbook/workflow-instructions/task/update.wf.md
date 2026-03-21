---
name: task/update
description: Update task metadata, status, position, or location
allowed-tools: Bash, Read
argument-hint: "<ref> [--set K=V] [--move-to FOLDER]"
doc-type: workflow
purpose: Update task fields, change status, move between folders, reparent
bundle:
  sections:
    ace-task-params:
      commands:
        - ace-task update --help
---

# Update Task

Run `ace-task update $ARGUMENTS` to modify task metadata. The embedded help above covers all flags.

## Common Patterns

```bash
# Status lifecycle
ace-task update <ref> --set status=in-progress
ace-task update <ref> --set status=done

# Multiple fields at once
ace-task update <ref> --set status=done,priority=high

# Array operations (tags, dependencies)
ace-task update <ref> --add tags=shipped --remove tags=wip

# Complete and archive in one step
ace-task update <ref> --set status=done --move-to archive

# Reparent: demote to subtask
ace-task update <ref> --move-as-child-of <parent-ref>

# Reparent: promote subtask to standalone
ace-task update <ref> --move-as-child-of none

# Pin sort position
ace-task update <ref> --position first
ace-task update <ref> --position after:<other-ref>
```
