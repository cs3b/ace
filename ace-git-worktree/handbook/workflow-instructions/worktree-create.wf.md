---
purpose: Create git worktrees with task integration
tools:
  - ace-git-worktree
  - ace-taskflow
  - git
parameters:
  - task_id: Task identifier (optional for traditional worktrees)
  - branch_name: Branch name (for traditional worktrees)
  - options: Additional creation options
---

# Worktree Creation Workflow

## Purpose

Create isolated git worktrees for task development with automatic status tracking and environment setup.

## Prerequisites

- Git repository with worktree support
- ace-git-worktree gem installed
- ace-taskflow gem installed (for task-aware mode)
- Configuration at .ace/git/worktree.yml (optional)

## Process

### Task-Aware Worktree Creation

1. **Identify the task**
   ```bash
   # List available tasks
   ace-taskflow tasks

   # Or find specific task
   ace-taskflow task 081
   ```

2. **Create task worktree**
   ```bash
   # Create with all automation
   ace-git-worktree create --task 081

   # Preview first
   ace-git-worktree create --task 081 --dry-run

   # Skip certain steps if needed
   ace-git-worktree create --task 081 --no-commit
   ace-git-worktree create --task 081 --no-status-update
   ```

3. **Navigate to worktree**
   ```bash
   cd $(ace-git-worktree switch 081)
   ```

4. **Start development**
   - The task is marked as in-progress
   - Worktree metadata is added to task frontmatter
   - mise.toml is automatically trusted if present

### Traditional Worktree Creation

1. **Create worktree with branch name**
   ```bash
   ace-git-worktree create feature-branch

   # With custom path
   ace-git-worktree create feature-branch --path .worktrees/feature
   ```

2. **Navigate to worktree**
   ```bash
   cd $(ace-git-worktree switch feature-branch)
   ```

## Configuration

Default configuration at `.ace/git/worktree.yml`:

```yaml
root_path: ".ace-wt"
mise_trust_auto: true

task:
  directory_format: "task.{id}"
  branch_format: "{id}-{slug}"
  auto_mark_in_progress: true
  auto_commit_task: true
```

## Workflow Automation

The task-aware creation performs these steps automatically:

1. Fetches task metadata from ace-taskflow
2. Updates task status to in-progress (if configured)
3. Adds worktree metadata to task frontmatter
4. Commits task changes to main branch
5. Creates worktree with consistent naming
6. Trusts mise.toml if present

## Error Handling

| Situation | Solution |
|-----------|----------|
| Task not found | Verify task ID with `ace-taskflow tasks` |
| Directory exists | Use different path or remove existing |
| ace-taskflow unavailable | Install gem or use traditional mode |
| Uncommitted changes | Commit or stash changes first |

## Best Practices

1. **Always preview with --dry-run** for important tasks
2. **Use task mode** for tracked development work
3. **Keep worktree names consistent** via configuration
4. **Clean up completed worktrees** with `ace-git-worktree remove`
5. **Prune deleted worktrees** periodically with `ace-git-worktree prune`

## Examples

### Complete Task Workflow

```bash
# 1. Find next task
ace-taskflow tasks next

# 2. Create worktree
ace-git-worktree create --task 081

# 3. Navigate and work
cd $(ace-git-worktree switch 081)
# ... develop feature ...

# 4. Complete and clean up
git push
ace-taskflow task done 081
ace-git-worktree remove 081
```

### Multiple Worktrees for Same Task

```bash
# First worktree
ace-git-worktree create --task 081
# Creates: .ace-wt/task.081

# Second worktree (automatically numbered)
ace-git-worktree create --task 081
# Creates: .ace-wt/task.081-2
```

## Related Commands

- `ace-git-worktree list --show-tasks` - View all worktrees
- `ace-git-worktree config` - Check configuration
- `ace-taskflow task <id>` - View task details