---
doc-type: workflow
title: Manage Worktree Workflow Instruction
purpose: Documentation for ace-git-worktree/handbook/workflow-instructions/git/worktree-manage.wf.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Manage Worktree Workflow Instruction

## Purpose

Manage existing git worktrees including listing, switching between, removing, and cleaning up worktrees. This workflow provides comprehensive worktree lifecycle management.

## Prerequisites

- Existing worktrees in the repository
- ace-git-worktree installed and configured
- Appropriate permissions for worktree operations

## Variables

$identifier: Worktree identifier (task ID, branch name, directory, or path)
$action: Management action (list, switch, remove, prune)

## Instructions

### 1. List Worktrees

**Basic Listing:**

```bash
# List all worktrees in table format
ace-git-worktree list

# List with task associations
ace-git-worktree list --show-tasks

# List in different formats
ace-git-worktree list --format json
ace-git-worktree list --format simple
```

**Filtered Listing:**

```bash
# List only task-associated worktrees
ace-git-worktree list --task-associated

# List only non-task worktrees
ace-git-worktree list --no-task-associated

# List only usable worktrees
ace-git-worktree list --usable

# Search by branch pattern
ace-git-worktree list --search auth
```

### 2. Switch Between Worktrees

**By Various Identifiers:**

```bash
# Switch by task ID
cd $(ace-git-worktree switch 081)

# Switch by branch name
cd $(ace-git-worktree switch feature-branch)

# Switch by directory name
cd $(ace-git-worktree switch task.081)

# Switch by full path
cd $(ace-git-worktree switch /path/to/worktree)
```

**Alternative Navigation:**

```bash
# Get worktree path and store in variable
WORKTREE_PATH=$(ace-git-worktree switch 081)
echo "Worktree path: $WORKTREE_PATH"
cd "$WORKTREE_PATH"

# List available worktrees first
ace-git-worktree switch --list
```

### 3. Remove Worktrees

**Task-Aware Removal:**

```bash
# Remove task worktree
ace-git-worktree remove --task 081

# Force remove (with uncommitted changes)
ace-git-worktree remove --task 081 --force

# Keep directory (remove git tracking only)
ace-git-worktree remove --task 081 --keep-directory
```

**Traditional Removal:**

```bash
# Remove by branch name
ace-git-worktree remove feature-branch

# Remove by identifier
ace-git-worktree remove task.081

# Remove with dry-run preview
ace-git-worktree remove --task 081 --dry-run
```

### 4. Clean Up Deleted Worktrees

**Basic Pruning:**

```bash
# Prune git metadata for deleted worktrees
ace-git-worktree prune

# Remove orphaned directories too
ace-git-worktree prune --cleanup-directories

# Dry run to preview changes
ace-git-worktree prune --dry-run

# Verbose output
ace-git-worktree prune --verbose
```

### 5. Configuration Management

**Show Configuration:**

```bash
# Show current configuration
ace-git-worktree config

# Validate configuration
ace-git-worktree config --validate

# Show configuration file locations
ace-git-worktree config --files

# Show detailed configuration
ace-git-worktree config --show
```

## Advanced Operations

### Bulk Management

```bash
# Get worktree status for all tasks
ace-git-worktree list --format json --show-tasks | jq '.worktrees'

# Count worktrees by type
ace-git-worktree list --show-tasks | grep "Task" | wc -l

# Find worktrees with specific patterns
ace-git-worktree list --search "bug" --format simple
```

### Search and Filter

```bash
# Search worktrees by multiple criteria
ace-git-worktree list --search auth --task-associated --format json

# Filter by usability
ace-git-worktree list --usable --format simple

# Show only worktrees with branches
ace-git-worktree list | grep -v "bare\|detached"
```

### Status and Monitoring

```bash
# Get comprehensive status
ace-git-worktree list --show-tasks --format json

# Check specific worktree
ace-git-worktree switch 081 --verbose

# Validate setup
ace-git-worktree config --validate
```

## Automation and Scripting

### JSON Output for Scripts

```bash
# Get all worktrees as JSON
WORKTREES=$(ace-git-worktree list --format json --show-tasks)

# Extract specific information
echo "$WORKTREES" | jq '.worktrees[] | select(.task_id == "081")'
echo "$WORKTREES" | jq '.worktrees[] | .path'
echo "$WORKTREES" | jq '.worktrees | length'
```

### Batch Operations

```bash
# Remove multiple worktrees
for task_id in 081 082 083; do
  ace-git-worktree remove --task "$task_id" --force
done

# Switch between worktrees
WORKTREES=("081" "082" "083")
for task_id in "${WORKTREES[@]}"; do
  echo "Switching to task $task_id"
  cd "$(ace-git-worktree switch "$task_id")"
  # Do work in each worktree...
  cd ..
done
```

### Conditional Operations

```bash
# Only remove if worktree exists
if ace-git-worktree switch 081 --help > /dev/null 2>&1; then
  ace-git-worktree remove --task 081
fi

# Check if worktrees need cleanup
if ace-git-worktree prune --dry-run | grep -q "Pruning"; then
  ace-git-worktree prune --cleanup-directories
fi
```

## Error Recovery

### Common Issues

**Worktree Not Found:**

```bash
# List available worktrees
ace-git-worktree list

# Search for similar identifiers
ace-git-worktree list --search "081"

# Try different identifier formats
ace-git-worktree switch task.081
ace-git-worktree switch 081-fix-auth
```

**Permission Issues:**

```bash
# Check worktree directory permissions
ls -la .ace-wt/

# Fix permissions if needed
chmod -R 755 .ace-wt/
```

**Git Repository Issues:**

```bash
# Check git status in worktree
cd $(ace-git-worktree switch 081)
git status

# Fix git issues if needed
git checkout main
git branch -D 081-fix-auth  # if needed
```

### Safety Checks

```bash
# Check removal safety before removing
ace-git-worktree switch 081 --help > /dev/null
if [ $? -eq 0 ]; then
  echo "Worktree exists, proceeding with removal"
  ace-git-worktree remove --task 081 --dry-run
else
  echo "Worktree not found, skipping removal"
fi

# Check for uncommitted changes
cd $(ace-git-worktree switch 081)
if [ -n "$(git status --porcelain)" ]; then
  echo "Worktree has uncommitted changes"
  git status
else
  echo "Worktree is clean"
fi
```

## Integration with Development Workflow

### Daily Workflow Management

```bash
#!/bin/bash
# Daily worktree management script

# 1. Check current worktree status
echo "=== Current Worktree Status ==="
ace-git-worktree list --show-tasks --format simple

# 2. Clean up if needed
echo "=== Cleanup Check ==="
if ace-git-worktree prune --dry-run | grep -q "Pruning"; then
  echo "Cleaning up deleted worktrees..."
  ace-git-worktree prune --cleanup-directories
else
  echo "No cleanup needed"
fi

# 3. Show configuration
echo "=== Configuration ==="
ace-git-worktree config --validate
```

### Task Completion Workflow

```bash
#!/bin/bash
# Complete task and cleanup worktree

TASK_ID="$1"
if [ -z "$TASK_ID" ]; then
  echo "Usage: $0 <task-id>"
  exit 1
fi

# 1. Switch to worktree and check status
echo "Checking worktree for task $TASK_ID..."
WORKTREE_PATH=$(ace-git-worktree switch "$TASK_ID")
cd "$WORKTREE_PATH"

# 2. Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: Worktree has uncommitted changes"
  git status
  read -p "Continue with removal? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting removal"
    exit 1
  fi
fi

# 3. Return to main and remove worktree
cd ..
echo "Removing worktree for task $TASK_ID..."
ace-git-worktree remove --task "$TASK_ID"

# 4. Clean up if needed
ace-git-worktree prune
```

## Success Criteria

- Worktrees listed with correct information
- Successfully switched to target worktree
- Worktrees removed cleanly with proper cleanup
- Deleted worktree metadata pruned from git
- Configuration validated and accessible
- Automation scripts work correctly
- Error conditions handled gracefully

## Response Template

**Action:** [list/switch/remove/prune/config]
**Worktree(s):** [Count and type of worktrees affected]
**Location(s):** [Paths involved]
**Status:** [Current state after operation]
**Next Steps:** [Recommended follow-up actions]