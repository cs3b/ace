# ace-taskflow task update Usage Guide

## Overview

`ace-taskflow task update` is a CLI command for updating arbitrary metadata fields in task files. It provides a programmatic way to modify task properties without directly editing files, supporting both simple and nested field updates through a convenient command-line interface.

**Available Features:**
- Update single or multiple fields in one command
- Support for nested YAML structures using dot notation
- Type inference for common data types (string, number, boolean, array)
- Atomic file writes with automatic backup
- Clear feedback on what was changed

**Key Benefits:**
- Enables automation tools to update task metadata
- Preserves file formatting and non-metadata content
- Provides safe updates with automatic backups
- Supports complex nested structures

## Command Types

This is a **bash CLI command** executed in your terminal as part of the ace-taskflow suite.

**Basic syntax:**
```bash
ace-taskflow task update <reference> --field <key=value> [--field <key2=value2>] [options]
```

## Command Structure

### Update Command

**Syntax:**
```bash
ace-taskflow task update <reference> --field <key=value> [options]
```

**Parameters:**
- `<reference>` - Task identifier (081, task.081, v.0.9.0+task.081, or file path)
- `--field <key=value>` - Field to update (can be repeated for multiple fields)
- `--dry-run` - Preview changes without writing (future enhancement)
- `--backup` - Keep backup file after successful update (default: auto-cleanup)

**Field Syntax:**
- Simple field: `--field priority=high`
- Nested field: `--field worktree.branch=081-fix-auth`
- Quoted value: `--field title="Complex: Task with 'quotes'"`
- Array value: `--field "dependencies=[082, 083]"`
- Empty value: `--field description=""`

## Usage Scenarios

### Scenario 1: Simple Field Update

**Goal:** Update a task's priority to high

**Commands:**
```bash
# Update priority field
ace-taskflow task update 081 --field priority=high

# Expected output:
# Task updated: v.0.9.0+task.081
# Updated fields:
#   priority: high
# Task path: /path/to/.ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md
```

**What happens internally:**
1. Finds task 081 using TaskFinder
2. Loads task file and parses frontmatter
3. Updates priority field in YAML
4. Writes file atomically with backup
5. Reports changes made

### Scenario 2: Multiple Field Updates

**Goal:** Update priority and estimate in single command

**Commands:**
```bash
# Update multiple fields
ace-taskflow task update 081 \
  --field priority=high \
  --field estimate="2 weeks"

# Expected output:
# Task updated: v.0.9.0+task.081
# Updated fields:
#   priority: high
#   estimate: 2 weeks
# Task path: /path/to/.ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md
```

**Benefits:**
- Single file read/write operation
- Atomic update of all fields
- Consistent state guaranteed

### Scenario 3: Nested Field Updates (Worktree Metadata)

**Goal:** Add worktree metadata to a task (primary use case for ace-git-worktree integration)

**Commands:**
```bash
# Add worktree metadata
ace-taskflow task update 081 \
  --field worktree.branch=081-fix-authentication-bug \
  --field worktree.path=.ace-wt/task.081 \
  --field worktree.created_at="2025-11-01 09:00:00"

# Expected output:
# Task updated: v.0.9.0+task.081
# Updated fields:
#   worktree.branch: 081-fix-authentication-bug
#   worktree.path: .ace-wt/task.081
#   worktree.created_at: 2025-11-01 09:00:00
# Task path: /path/to/.ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md
```

**Resulting YAML structure:**
```yaml
---
id: v.0.9.0+task.081
status: in-progress
priority: medium
worktree:
  branch: 081-fix-authentication-bug
  path: .ace-wt/task.081
  created_at: "2025-11-01 09:00:00"
---
```

### Scenario 4: Array Updates

**Goal:** Update task dependencies

**Commands:**
```bash
# Update dependencies array
ace-taskflow task update 081 --field "dependencies=[082, 083, 084]"

# Expected output:
# Task updated: v.0.9.0+task.081
# Updated fields:
#   dependencies: [082, 083, 084]
# Task path: /path/to/.ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md
```

### Scenario 5: Complex Values with Special Characters

**Goal:** Update task title with special characters

**Commands:**
```bash
# Update title with quotes and colons
ace-taskflow task update 081 --field title="Fix: Authentication 'session' bug"

# Or with escaping
ace-taskflow task update 081 --field title='Fix: Authentication "session" bug'

# Expected output:
# Task updated: v.0.9.0+task.081
# Updated fields:
#   title: Fix: Authentication 'session' bug
# Task path: /path/to/.ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md
```

### Scenario 6: Error Handling - Task Not Found

**Goal:** Handle invalid task reference gracefully

**Commands:**
```bash
ace-taskflow task update 999 --field priority=high

# Expected output:
# Error: Task not found: 999
#
# Try: ace-taskflow tasks to see available tasks
# Exit code: 1
```

### Scenario 7: Error Handling - Invalid Field Syntax

**Goal:** Provide helpful error for incorrect syntax

**Commands:**
```bash
ace-taskflow task update 081 --field invalid-syntax

# Expected output:
# Error: Invalid field syntax. Use: --field key=value
#
# Examples:
#   --field priority=high
#   --field worktree.branch=feature-branch
#   --field "title=Task with spaces"
# Exit code: 2
```

### Scenario 8: Deep Nesting

**Goal:** Create deeply nested structure

**Commands:**
```bash
# Create deep nested structure
ace-taskflow task update 081 \
  --field metadata.review.status=approved \
  --field metadata.review.reviewer=john \
  --field metadata.review.date="2025-11-01"

# Expected output:
# Task updated: v.0.9.0+task.081
# Updated fields:
#   metadata.review.status: approved
#   metadata.review.reviewer: john
#   metadata.review.date: 2025-11-01
# Task path: /path/to/.ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md
```

**Resulting structure:**
```yaml
metadata:
  review:
    status: approved
    reviewer: john
    date: "2025-11-01"
```

## Command Reference

### ace-taskflow task update

**Syntax:**
```bash
ace-taskflow task update <reference> --field <key=value> [--field <key2=value2>] [options]
```

**Parameters:**
- `<reference>` - Task identifier:
  - Task number: `081`
  - Task with prefix: `task.081`
  - Full ID: `v.0.9.0+task.081`
  - File path: `/path/to/task.081.md`

**Options:**
- `--field <key=value>` - Field to update (repeatable)
  - Simple: `priority=high`
  - Nested: `worktree.branch=feature`
  - Array: `dependencies=[1,2,3]`
  - Empty: `description=""`

**Input/Output:**
- Input: Task reference and field updates via CLI
- Output: Confirmation of changes to stdout
- Exit codes:
  - 0: Success
  - 1: Task not found
  - 2: Invalid field syntax
  - 3: File write error

**Internal implementation:**
- Uses `TaskFinder` to locate task file
- Parses frontmatter with `SafeYamlParser`
- Applies updates via new `TaskFieldUpdater` molecule
- Writes atomically with `SafeFileWriter`
- Creates `.bak` backup before writing

## Tips and Best Practices

### Field Naming
- Use consistent field names across tasks
- Prefer snake_case for custom fields
- Group related fields using nesting (e.g., `worktree.*`)

### Type Inference
- Numbers: `--field count=42` → integer
- Booleans: `--field active=true` → boolean
- Arrays: `--field "items=[a,b,c]"` → array
- Default: Everything else → string

### Batch Updates
- Combine multiple field updates in single command
- More efficient than multiple separate commands
- Ensures atomic update of all fields

### Automation Integration
- Use in scripts for automated task management
- Integrate with ace-git-worktree for metadata tracking
- Chain with other ace-taskflow commands

### Error Recovery
- Automatic `.bak` file created before updates
- Restore from backup if update fails
- Use `--dry-run` to preview changes (future)

## Troubleshooting

**Problem:** "Task not found: 081"
- **Cause:** Task doesn't exist or wrong reference format
- **Solution:** Use `ace-taskflow tasks` to list available tasks

**Problem:** "Invalid field syntax"
- **Cause:** Missing equals sign or malformed syntax
- **Solution:** Use format `--field key=value`

**Problem:** "Cannot update nested field - parent does not exist"
- **Cause:** Trying to update deeply nested field without parent
- **Solution:** Create parent structure first or use full path

**Problem:** "Failed to update task file: Permission denied"
- **Cause:** No write permission on task file
- **Solution:** Check file permissions, restore from `.bak` if needed

## Migration Notes

**From Manual Editing:**
- Previously: Edit task files directly in editor
- Now: Use `task update` for programmatic changes
- Benefit: Safer, automated, scriptable

**From Status-Only Updates:**
- Previously: Only `task start` and `task done` for status
- Now: Update any field with `task update`
- Benefit: Full metadata control

**Integration with ace-git-worktree:**
- ace-git-worktree will use this command for adding worktree metadata
- Enables tracking of branch and worktree path in task
- Clean separation of concerns between tools