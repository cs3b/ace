---
doc-type: workflow
title: Create Worktree Workflow Instruction
purpose: Documentation for ace-git-worktree/handbook/workflow-instructions/git/worktree-create.wf.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Create Worktree Workflow Instruction

## Purpose

Create git worktrees with task-aware automation or traditional branch-based creation. This workflow provides isolated development environments integrated with ACE's task management system.

## Prerequisites

- Git repository initialized and accessible
- ace-task available (for task-aware creation)
- Configuration available in `.ace/git/worktree.yml`
- Write permissions for worktree root directory

## Variables

$task_id: Task identifier (optional, for task-aware creation)
$branch_name: Branch name (for traditional creation)
$path: Custom worktree path (optional)

## Instructions

### 1. Preparation

Load and validate worktree configuration:

```bash
# Show current configuration
ace-git-worktree config

# Validate configuration
ace-git-worktree config --validate

# Check available worktrees
ace-git-worktree list
```

### 2. Choose Creation Method

**Task-Aware Creation (Recommended for ACE workflow):**

```bash
ace-git-worktree create --task <task-id>
```

**Traditional Creation (For non-task work):**

```bash
ace-git-worktree create <branch-name>
```

### 3. Execute Creation

**Task-Aware Creation:**

```bash
# Create worktree for task
ace-git-worktree create --task 081

# With dry-run to preview
ace-git-worktree create --task 081 --dry-run

# With custom path
ace-git-worktree create --task 081 --path ~/worktrees
```

**Traditional Creation:**

```bash
# Create worktree for branch
ace-git-worktree create feature-branch

# With custom path
ace-git-worktree create feature-branch --path ~/dev-work
```

### 4. Verify Creation

```bash
# List all worktrees
ace-git-worktree list --show-tasks

# Switch to the worktree
cd $(ace-git-worktree switch 081)
# or
cd $(ace-git-worktree switch feature-branch)
```

### 5. Work in Isolated Environment

```bash
# Verify you're in the correct worktree
git status
git branch

# Work on your task/feature...
git add .
git commit -m "Your commit message"
```

### 6. Cleanup When Done

```bash
# Return to main directory
cd ..

# Remove worktree (optional)
ace-git-worktree remove --task 081
# or
ace-git-worktree remove feature-branch
```

## Advanced Options

### Custom Configuration

```bash
# Skip automatic mise trust
ace-git-worktree create --task 081 --no-mise-trust

# Skip task status update
ace-git-worktree create --task 081 --no-status-update

# Skip automatic commit
ace-git-worktree create --task 081 --no-commit

# Custom commit message
ace-git-worktree create --task 081 --commit-message "Custom message"
```

### Configuration Templates

Customize worktree behavior in `.ace/git/worktree.yml`:

```yaml
git:
  worktree:
    root_path: ".ace-wt"
    mise_trust_auto: true

    task:
      directory_format: "task.{id}"        # task.081
      branch_format: "{id}-{slug}"         # 081-fix-authentication-bug
      auto_mark_in_progress: true          # Mark task as in-progress
      auto_commit_task: true                # Commit task changes
      add_worktree_metadata: true          # Add metadata to task
```

### Template Variables

Available for directory and branch naming:
- `{id}` - Task numeric ID (e.g., `081`)
- `{task_id}` - Full task ID (e.g., `task.081`)
- `{slug}` - URL-safe slug from task title

## Examples

### Task-Aware Development Workflow

```bash
# 1. Create worktree for task 081
ace-git-worktree create --task 081
# Output: Worktree created at .ace-wt/task.081 with branch 081-fix-auth-bug

# 2. Switch to worktree
cd $(ace-git-worktree switch 081)

# 3. Work on task
git add .
git commit -m "Implement authentication fix"

# 4. When complete, return and cleanup
cd ..
ace-git-worktree remove --task 081
```

### Feature Branch Workflow

```bash
# 1. Create traditional worktree
ace-git-worktree create feature-authentication
# Output: Worktree created at .ace-wt/feature-authentication

# 2. Switch to worktree
cd $(ace-git-worktree switch feature-authentication)

# 3. Work on feature
git add .
git commit -m "Add authentication feature"

# 4. Merge and cleanup
git checkout main
git merge feature-authentication
ace-git-worktree remove feature-authentication
```

### Bulk Operations

```bash
# List all task worktrees
ace-git-worktree list --task-associated

# Clean up orphaned worktrees
ace-git-worktree prune --cleanup-directories

# Get status in JSON for scripts
ace-git-worktree list --format json --show-tasks
```

## Error Handling

| Error | Check | Fix |
|-------|-------|-----|
| Task not found | `ace-task show <id>` | Verify task ID exists |
| Not in git repo | `git status` | Run from git repository |
| Invalid config | `ace-git-worktree config --validate` | Fix configuration errors |
| Permission denied | `ls -la <worktree-root>` | Fix directory permissions |
| Worktree exists | `ace-git-worktree list` | Use different name or remove existing |

## Integration with AI Agents

AI agents can programmatically create and manage worktrees:

```bash
# Find worktree path for task
WORKTREE_PATH=$(ace-git-worktree switch --task 081)

# Create worktree and get details
RESULT=$(ace-git-worktree create --task 081 --dry-run --format json)
echo "$RESULT" | jq '.worktree_path'

# List worktrees with task associations
STATUS=$(ace-git-worktree list --format json --show-tasks)
echo "$STATUS" | jq '.worktrees[] | select(.task_associated == true)'
```

## Success Criteria

- Worktree created successfully with correct naming
- Task status updated (if task-aware creation)
- Worktree metadata added to task (if configured)
- mise configuration trusted (if present and configured)
- Worktree is accessible and functional
- Git branch created correctly
- All automated steps completed successfully

## Response Template

**Worktree Type:** [Task-aware/Traditional]
**Location:** [Worktree path]
**Branch:** [Branch name]
**Task ID:** [Task ID if applicable]
**Configuration:** [Key settings applied]
**Automation Steps:** [Completed automated actions]
