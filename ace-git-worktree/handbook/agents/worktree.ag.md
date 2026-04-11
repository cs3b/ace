---
doc-type: agent
title: Worktree Agent
purpose: Documentation for ace-git-worktree/handbook/agents/worktree.ag.md
ace-docs:
  last-updated: 2025-12-27
  last-checked: 2026-03-21
---

# Worktree Agent

A specialized agent for managing git worktrees with task-aware automation. Handles creation, listing, switching, removal, and cleanup of worktrees integrated with ACE's task management system.

## Capabilities

### Task-Aware Operations
- Create worktrees for specific tasks with automatic metadata integration
- Fetch task information from ace-task
- Update task status and add worktree metadata
- Commit task changes before worktree creation

### Traditional Worktree Operations
- Create worktrees for traditional branch-based development
- List all worktrees with filtering and formatting options
- Switch between worktrees using various identifiers
- Remove worktrees with safety checks and cleanup
- Prune deleted worktrees and orphaned directories

### Configuration Management
- Show and validate worktree configuration
- Display configuration file locations and settings
- Support for custom naming conventions and behaviors

## Usage Examples

### Task-Aware Workflow
```bash
# Create worktree for task 081
@worktree create --task 081

# Switch to task worktree
@worktree switch 081

# Remove task worktree
@worktree remove --task 081
```

### Traditional Workflow
```bash
# Create worktree for feature branch
@worktree create feature-branch

# List all worktrees
@worktree list --show-tasks

# Switch to worktree
@worktree switch feature-branch
```

### Management Operations
```bash
# List with filtering
@worktree list --task-associated --format json

# Clean up deleted worktrees
@worktree prune --cleanup-directories

# Show configuration
@worktree config --validate
```

## Configuration

The worktree agent uses configuration from `.ace/git/worktree.yml`:

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

## Integration Points

- **ace-task**: Task metadata fetching and status updates
- **ace-git-commit**: Consistent commit message generation
- **ace-git**: Safe git command execution
- **ace-core**: Configuration cascade management

## Expected Parameters

The worktree agent accepts standard CLI parameters:

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

The worktree agent handles common error conditions:

- **Task not found**: Validates task ID existence before creation
- **Not in git repository**: Checks git repository status
- **Configuration invalid**: Validates configuration before operations
- **Worktree conflicts**: Detects existing worktrees and provides alternatives
- **Permission issues**: Validates directory permissions and access
- **Uncommitted changes**: Warns about changes before removal

## Output Formats

### Table Format
Human-readable table with columns for Task, Branch, Path, and Status.

### JSON Format
Machine-readable JSON with complete worktree metadata for scripting and automation.

### Simple Format
Concise format for quick overviews and scripting.

## Response Template

**Operation:** [create/list/switch/remove/prune/config]
**Worktree(s):** [Worktree information]
**Status:** [Success/Failure with details]
**Location(s):** [Relevant paths]
**Next Steps:** [Recommended follow-up actions]

## Best Practices

1. **Use task-aware creation** for ACE workflow integration
2. **Validate configuration** before operations
3. **Use dry-run** to preview changes
4. **Clean up worktrees** when tasks are complete
5. **Prune regularly** to maintain clean repository state
6. **Check git status** before removing worktrees with changes

## Integration with AI Agents

The worktree agent provides deterministic output suitable for AI automation:

```bash
# Get worktree path for task
WORKTREE_PATH=$(ace-git-worktree switch 081)

# Get worktree status as JSON
STATUS=$(ace-git-worktree list --format json --show-tasks)

# Create worktree and verify creation
RESULT=$(ace-git-worktree create --task 081 --dry-run --format json)
if echo "$RESULT" | jq -e '.success'; then
  echo "Worktree creation would succeed"
fi
```