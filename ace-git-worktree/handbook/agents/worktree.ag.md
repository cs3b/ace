---
purpose: Manage git worktrees with task integration
tools:
  - ace-git-worktree
  - ace-taskflow
  - git
capabilities:
  - create_worktree
  - list_worktrees
  - remove_worktree
  - navigate_worktree
---

# Worktree Agent

## Purpose

Efficiently manage git worktrees for parallel development with integrated task tracking.

## Capabilities

### Worktree Creation
- Create task-aware worktrees with automatic status updates
- Create traditional worktrees for non-task work
- Configure naming conventions and automation

### Worktree Management
- List all worktrees with task associations
- Navigate to worktrees by task ID or branch name
- Remove worktrees with cleanup
- Prune deleted worktree references

### Task Integration
- Automatically fetch task metadata
- Update task status to in-progress
- Add worktree metadata to tasks
- Commit changes before creating worktrees

## Usage Patterns

### Quick Task Worktree
```bash
# Minimal input - create worktree for task
ace-git-worktree create --task 081
```

### Explore Worktrees
```bash
# See what's active
ace-git-worktree list --show-tasks

# Navigate to specific worktree
cd $(ace-git-worktree switch 081)
```

### Cleanup Operations
```bash
# Remove specific worktree
ace-git-worktree remove 081

# Clean up all deleted references
ace-git-worktree prune
```

## Decision Points

When creating worktrees, the agent considers:

1. **Task vs Traditional**: Is this for a tracked task?
2. **Automation Level**: Should status be updated automatically?
3. **Naming Convention**: Use configured templates or custom names?
4. **Environment Setup**: Should mise.toml be trusted?

## Error Handling

The agent handles common issues:
- Missing task IDs with helpful suggestions
- Existing directories with duplicate handling
- ace-taskflow unavailability with fallback
- Uncommitted changes with clear messages

## Configuration

Respects configuration in `.ace/git/worktree.yml`:
- Root path for worktrees
- Naming templates
- Automation settings
- mise integration

## Output Format

Provides structured output suitable for:
- Human reading (table format)
- Script parsing (JSON format)
- Shell integration (path output)

## Best Practices

1. Always use task mode for tracked work
2. Preview with --dry-run for important operations
3. Keep consistent naming via configuration
4. Clean up completed worktrees promptly
5. Use --show-tasks to track associations

## Integration Points

- **ace-taskflow**: Task metadata and status updates
- **git**: Core worktree operations
- **mise**: Environment trust automation
- **ace-git-commit**: Task change commits

## Examples

### Complete Task Development
```bash
# Start task
ace-git-worktree create --task 081
cd $(ace-git-worktree switch 081)

# Work on task...

# Complete task
ace-taskflow task done 081
ace-git-worktree remove 081
```

### Parallel Development
```bash
# Multiple active worktrees
ace-git-worktree create --task 081
ace-git-worktree create --task 082
ace-git-worktree create feature-experiment

# View all
ace-git-worktree list --show-tasks

# Switch between them
cd $(ace-git-worktree switch 081)
cd $(ace-git-worktree switch feature-experiment)
```