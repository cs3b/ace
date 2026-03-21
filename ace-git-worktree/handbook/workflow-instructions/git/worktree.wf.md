---
doc-type: workflow
title: Worktree Workflow
purpose: worktree workflow instruction
ace-docs:
  last-updated: 2026-03-06
  last-checked: 2026-03-21
---

# Worktree Workflow

## Purpose

Manage git worktrees with task-aware automation and traditional operations using ace-git-worktree CLI.

## Primary Tool: ace-git-worktree

All operations use the **ace-git-worktree** command.

## Task-Aware Operations

### Create Worktree for Task
```bash
# Create worktree for task (recommended)
ace-git-worktree create --task 081

# With dry-run preview
ace-git-worktree create --task 081 --dry-run

# Skip automatic operations
ace-git-worktree create --task 081 --no-commit --no-status-update
```

### Switch to Task Worktree
```bash
# Switch by task ID
ace-git-worktree switch 081

# Verbose output
ace-git-worktree switch 081 --verbose
```

### Remove Task Worktree
```bash
# Remove task worktree
ace-git-worktree remove --task 081

# Preview removal
ace-git-worktree remove --task 081 --dry-run

# Force removal with uncommitted changes
ace-git-worktree remove --task 081 --force
```

## Traditional Worktree Operations

### Create Worktree for Branch
```bash
# Create for branch
ace-git-worktree create feature-branch

# Custom path
ace-git-worktree create feature-branch --path ../custom-path

# Without mise trust
ace-git-worktree create feature-branch --no-mise-trust
```

### List Worktrees
```bash
# List all worktrees
ace-git-worktree list

# Show task associations
ace-git-worktree list --show-tasks

# Filter by task association
ace-git-worktree list --task-associated

# Output formats
ace-git-worktree list --format json
ace-git-worktree list --format table
ace-git-worktree list --format simple

# Search/filter
ace-git-worktree list --search "081"
```

### Switch Worktree
```bash
# By branch name
ace-git-worktree switch feature-branch

# By directory name
ace-git-worktree switch task.081

# By path
ace-git-worktree switch ../as-task.081
```

### Remove Worktree
```bash
# By branch name
ace-git-worktree remove feature-branch

# Keep directory
ace-git-worktree remove feature-branch --keep-directory

# Force removal
ace-git-worktree remove feature-branch --force
```

## Cleanup Operations

### Prune Deleted Worktrees
```bash
# Prune git worktree metadata
ace-git-worktree prune

# Also remove orphaned directories
ace-git-worktree prune --cleanup-directories

# Dry-run preview
ace-git-worktree prune --cleanup-directories --dry-run

# Verbose output
ace-git-worktree prune --verbose
```

## Configuration

### Show Configuration
```bash
# Show current configuration
ace-git-worktree config --show

# Validate configuration
ace-git-worktree config --validate

# Show configuration file locations
ace-git-worktree config --files
```

### Configuration File

Configuration from `.ace/git/worktree.yml`:

```yaml
git:
  worktree:
    root_path: ".ace-wt"
    mise_trust_auto: true
    task:
      directory_format: "task.{id}"
      branch_format: "{id}-{slug}"
      auto_mark_in_progress: true
      auto_commit_task: true
      add_worktree_metadata: true
```

## Command Reference

### create
- `--task <task-id>`: Create worktree for specific task
- `--path <path>`: Custom worktree path
- `--dry-run`: Preview without creating
- `--no-mise-trust`: Skip automatic mise trust
- `--no-status-update`: Skip task status update
- `--no-commit`: Skip committing task changes

### list
- `--format <format>`: Output format (table, json, simple)
- `--show-tasks`: Include task associations
- `--task-associated`: Filter by task association
- `--search <pattern>`: Filter by search pattern

### switch
- `identifier`: Worktree identifier (task ID, branch name, directory, path)
- `--verbose`: Show detailed information

### remove
- `--task <task-id>`: Remove task worktree
- `--force`: Force removal with uncommitted changes
- `--keep-directory`: Keep worktree directory
- `--dry-run`: Preview without removing

### prune
- `--cleanup-directories`: Remove orphaned directories
- `--dry-run`: Preview changes
- `--verbose`: Detailed output

### config
- `--show`: Show current configuration
- `--validate`: Validate configuration
- `--files`: Show configuration file locations

## Error Handling

The CLI handles common error conditions:
- **Task not found**: Validates task ID existence before creation
- **Not in git repository**: Checks git repository status
- **Configuration invalid**: Validates configuration before operations
- **Worktree conflicts**: Detects existing worktrees and provides alternatives
- **Permission issues**: Validates directory permissions and access
- **Uncommitted changes**: Warns about changes before removal

## Best Practices

1. **Use task-aware creation** for ACE workflow integration
2. **Validate configuration** before operations
3. **Use dry-run** to preview changes
4. **Clean up worktrees** when tasks are complete
5. **Prune regularly** to maintain clean repository state
6. **Check git status** before removing worktrees with changes

## Response Format

```markdown
**Operation:** [create/list/switch/remove/prune/config]
**Worktree(s):** [Worktree information]
**Status:** [Success/Failure with details]
**Location(s):** [Relevant paths]
**Next Steps:** [Recommended follow-up actions]
```