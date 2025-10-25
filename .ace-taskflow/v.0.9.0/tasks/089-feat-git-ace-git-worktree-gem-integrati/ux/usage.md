# ace-git-worktree Usage Guide

## Overview

`ace-git-worktree` is a CLI tool for managing git worktrees with integrated task awareness. It creates isolated development environments for tasks by automatically fetching task metadata from ace-taskflow and configuring worktrees with consistent naming conventions.

**Available Commands:**
- `ace-git-worktree create` - Create new task-aware or traditional worktrees
- `ace-git-worktree list` - List all worktrees with task associations
- `ace-git-worktree switch` - Navigate to a worktree by task ID or name
- `ace-git-worktree remove` - Remove a worktree with cleanup
- `ace-git-worktree prune` - Clean up deleted worktrees from git metadata
- `ace-git-worktree config` - Display current configuration

**Key Benefits:**
- Automatic task metadata integration
- Configurable naming conventions for directories and branches
- Automated mise environment trust
- Deterministic output for AI agent consumption
- Follows ACE ATOM architecture patterns

## Command Types

This tool provides **bash CLI commands** (not Claude Code commands). All commands are executed in your terminal.

**Basic syntax:**
```bash
ace-git-worktree <command> [options] [arguments]
```

## Command Structure

### Create Command

**Task-aware creation (recommended):**
```bash
ace-git-worktree create --task <task-id> [options]
```

**Traditional creation:**
```bash
ace-git-worktree create <branch-name> [options]
```

**Common Options:**
- `--task <id>` - Task ID (081, task.081, or v.0.9.0+081)
- `--path <path>` - Override default worktree root path
- `--no-mise-trust` - Skip automatic mise trust
- `--dry-run` - Show what would be created without creating

### List Command

```bash
ace-git-worktree list [options]
```

**Options:**
- `--format <json|table>` - Output format (default: table)
- `--show-tasks` - Include associated task IDs in output

### Switch Command

```bash
ace-git-worktree switch <identifier>
```

**Identifier can be:**
- Task number: `081`
- Task with prefix: `task.081`
- Branch name: `081-fix-bug`
- Directory name: `task.081`

### Remove Command

```bash
ace-git-worktree remove <identifier> [options]
```

**Options:**
- `--force` - Remove even if there are uncommitted changes

### Prune Command

```bash
ace-git-worktree prune
```

Clean up references to worktrees that have been manually deleted.

## Usage Scenarios

### Scenario 1: Creating a Task-Aware Worktree

**Goal:** Create an isolated development environment for task 081

**Commands:**
```bash
# Create worktree for task 081
ace-git-worktree create --task 081

# Expected output:
# Fetching task metadata from ace-taskflow...
# Task found: v.0.9.0+task.081 - Fix authentication bug
# Creating worktree at: .ace-wt/task.081
# Creating branch: 081-fix-authentication-bug
# Trusting mise.toml...
# ✓ Worktree created successfully
#
# Path: /Users/mc/Ps/myproject/.ace-wt/task.081
# Branch: 081-fix-authentication-bug
```

**What happens internally:**
1. Tool queries `ace-taskflow task 081` to get task metadata
2. Extracts task ID, title, and generates slug
3. Creates directory using configured format: `.ace-wt/task.081`
4. Creates branch using configured format: `081-fix-authentication-bug`
5. Runs `git worktree add .ace-wt/task.081 -b 081-fix-authentication-bug`
6. Detects `mise.toml` and runs `mise trust` in worktree directory
7. Outputs paths for AI agent consumption

### Scenario 2: Traditional Worktree Creation

**Goal:** Create a worktree for non-task work (e.g., experiments)

**Commands:**
```bash
# Create worktree with custom branch name
ace-git-worktree create experimental-feature --path .ace-wt/experiment

# Expected output:
# Creating worktree at: .ace-wt/experiment
# Creating branch: experimental-feature
# Trusting mise.toml...
# ✓ Worktree created successfully
#
# Path: /Users/mc/Ps/myproject/.ace-wt/experiment
# Branch: experimental-feature
```

### Scenario 3: Listing All Worktrees

**Goal:** View all active worktrees and their task associations

**Commands:**
```bash
# List in table format
ace-git-worktree list --show-tasks

# Expected output (table):
# DIRECTORY          BRANCH                        TASK
# task.081           081-fix-authentication-bug    v.0.9.0+task.081
# task.079           079-add-dark-mode            v.0.9.0+task.079
# experiment         experimental-feature          -

# List in JSON format (for AI agents)
ace-git-worktree list --format json --show-tasks

# Expected output (JSON):
# {
#   "worktrees": [
#     {
#       "path": "/Users/mc/Ps/myproject/.ace-wt/task.081",
#       "directory": "task.081",
#       "branch": "081-fix-authentication-bug",
#       "task_id": "v.0.9.0+task.081"
#     },
#     ...
#   ]
# }
```

### Scenario 4: Switching to a Worktree

**Goal:** Navigate to a worktree directory

**Commands:**
```bash
# Switch by task ID
ace-git-worktree switch 081

# Expected output:
# /Users/mc/Ps/myproject/.ace-wt/task.081

# Switch by task prefix
ace-git-worktree switch task.081

# Switch by directory name
ace-git-worktree switch task.081

# Switch by branch name
ace-git-worktree switch 081-fix-authentication-bug
```

**Note:** The command outputs the path to stdout. In bash, you can use:
```bash
cd $(ace-git-worktree switch 081)
```

Or create a shell alias/function for convenience.

### Scenario 5: Error Handling - Task Not Found

**Goal:** Handle invalid task ID gracefully

**Commands:**
```bash
ace-git-worktree create --task 999

# Expected output:
# Error: Task not found: 999
#
# Suggestion: Verify task ID using: ace-taskflow tasks
# Exit code: 1
```

### Scenario 6: Dry Run Before Creation

**Goal:** Preview what will be created before executing

**Commands:**
```bash
ace-git-worktree create --task 081 --dry-run

# Expected output:
# [DRY RUN] Would create worktree:
#   Directory: .ace-wt/task.081
#   Branch: 081-fix-authentication-bug
#   Task: v.0.9.0+task.081 - Fix authentication bug
#   Mise trust: yes
#
# No changes made.
```

## Command Reference

### ace-git-worktree create

**Syntax:**
```bash
ace-git-worktree create --task <task-id> [options]
ace-git-worktree create <branch-name> [options]
```

**Parameters:**
- `--task <id>` - Task identifier (081, task.081, v.0.9.0+081)
- `<branch-name>` - Branch name for traditional worktree
- `--path <path>` - Custom worktree root path (default: from config)
- `--no-mise-trust` - Skip automatic mise trust
- `--dry-run` - Preview without creating

**Input/Output:**
- Input: Task ID or branch name via CLI arguments
- Output: Worktree path and branch name to stdout
- Exit code: 0 on success, 1 on error

**Internal implementation:**
- Uses `ace-taskflow task <id>` to fetch metadata
- Executes `git worktree add` command
- Runs `mise trust` if mise.toml detected
- Parses configuration from `.ace/git/worktree.yml`

### ace-git-worktree list

**Syntax:**
```bash
ace-git-worktree list [--format <format>] [--show-tasks]
```

**Parameters:**
- `--format <json|table>` - Output format (default: table)
- `--show-tasks` - Include task ID associations

**Input/Output:**
- Input: Options via CLI flags
- Output: Formatted list to stdout
- Exit code: 0 on success, 1 on error

**Internal implementation:**
- Uses `git worktree list --porcelain` to get worktrees
- Matches worktree paths against task directory patterns
- Queries ace-taskflow to resolve task IDs
- Formats output as table or JSON

### ace-git-worktree switch

**Syntax:**
```bash
ace-git-worktree switch <identifier>
```

**Parameters:**
- `<identifier>` - Task ID, task prefix, branch name, or directory name

**Input/Output:**
- Input: Identifier via CLI argument
- Output: Absolute worktree path to stdout
- Exit code: 0 on success, 1 if not found

**Internal implementation:**
- Queries `git worktree list` for all worktrees
- Matches identifier against task IDs, directories, and branches
- Returns first match or error if not found

### ace-git-worktree remove

**Syntax:**
```bash
ace-git-worktree remove <identifier> [--force]
```

**Parameters:**
- `<identifier>` - Worktree identifier
- `--force` - Remove even with uncommitted changes

**Input/Output:**
- Input: Identifier and options via CLI
- Output: Confirmation message to stdout
- Exit code: 0 on success, 1 on error

**Internal implementation:**
- Resolves identifier to worktree path
- Checks for uncommitted changes (unless --force)
- Executes `git worktree remove <path>`
- Cleans up any task association metadata

### ace-git-worktree prune

**Syntax:**
```bash
ace-git-worktree prune
```

**Input/Output:**
- Output: List of pruned worktrees to stdout
- Exit code: 0 on success, 1 on error

**Internal implementation:**
- Executes `git worktree prune`
- Reports deleted worktree references

### ace-git-worktree config

**Syntax:**
```bash
ace-git-worktree config [--show]
```

**Input/Output:**
- Output: Current configuration to stdout
- Exit code: 0 on success

**Internal implementation:**
- Loads configuration via `Ace::Core.config.get('ace', 'git', 'worktree')`
- Displays merged configuration (defaults + user overrides)

## Configuration Reference

**File location:** `.ace/git/worktree.yml`

**Example configuration:**
```yaml
git:
  worktree:
    # Root directory for all worktrees (relative to project root)
    root_path: ".ace-wt"

    # Mise integration
    mise_trust_auto: true

    # Task-based naming conventions
    task:
      # Directory naming: {id}, {task_id}, {release}, {slug}
      directory_format: "task.{id}"        # Results in: task.081

      # Branch naming: {id}, {task_id}, {release}, {slug}
      branch_format: "{id}-{slug}"         # Results in: 081-fix-bug

    # Cleanup policies
    cleanup:
      on_merge: false      # Auto-remove when branch merged
      on_delete: true      # Remove worktree when branch deleted
```

**Available template variables:**
- `{id}` - Task number only (e.g., "081")
- `{task_id}` - Full task ID (e.g., "v.0.9.0+task.081")
- `{release}` - Release version (e.g., "v.0.9.0")
- `{slug}` - Task title slug (e.g., "fix-authentication-bug")

**Alternative format examples:**
```yaml
# Minimal task numbers
directory_format: "{id}"
branch_format: "{id}"
# Results: 081/ with branch 081

# Full task IDs
directory_format: "{task_id}"
branch_format: "{task_id}"
# Results: v.0.9.0+task.081/ with branch v.0.9.0+task.081

# Task prefix in branches
directory_format: "task.{id}"
branch_format: "task-{id}-{slug}"
# Results: task.081/ with branch task-081-fix-bug
```

## Tips and Best Practices

### Working with Multiple Tasks
- Each task gets its own worktree, allowing parallel development
- Use descriptive task titles - they become branch names
- Keep worktree root (`.ace-wt/`) in `.gitignore`

### Mise Environment Trust
- Worktree creation automatically trusts `mise.toml` when detected
- Use `--no-mise-trust` if you prefer manual trust
- Mise trust is per-directory, so each worktree needs individual trust

### AI Agent Integration
- Use `--format json` for structured output
- All commands return deterministic, parseable output
- Exit codes: 0 for success, 1 for errors
- Paths are always absolute in output

### Performance Considerations
- Worktree creation is fast (git operation + metadata lookup)
- `list` command queries git and ace-taskflow (may be slower with many worktrees)
- Use `--show-tasks` only when needed (requires additional ace-taskflow queries)

### Naming Best Practices
- Keep task titles concise (long titles create long branch names)
- Git branch name limits: 255 characters (tool will truncate if needed)
- Avoid special characters in task titles (/, \, :, etc.)
- Use consistent slug format: lowercase-with-hyphens

### Troubleshooting

**Problem:** "Task not found: 081"
- **Cause:** Task doesn't exist or ace-taskflow not accessible
- **Solution:** Verify with `ace-taskflow task 081` or `ace-taskflow tasks`

**Problem:** "Directory already exists"
- **Cause:** Worktree directory already created
- **Solution:** Remove existing worktree or use different path

**Problem:** "Mise trust failed"
- **Cause:** mise not installed or mise.toml issues
- **Solution:** Install mise or use `--no-mise-trust`

**Problem:** "Not in a git repository"
- **Cause:** Running command outside git repo
- **Solution:** Navigate to repository root

**Problem:** "ace-taskflow command not found"
- **Cause:** ace-taskflow gem not installed
- **Solution:** `gem install ace-taskflow` or add to Gemfile

## Migration Notes

**This is a new tool** - no legacy commands to migrate from.

**Integration with existing workflows:**
- Compatible with existing git worktree commands
- ace-taskflow integration is optional (traditional mode available)
- Configuration follows ACE cascade pattern (project/user/default)
- Can be used alongside manual `git worktree` commands

**Relationship to git worktree:**
- Wrapper around `git worktree` commands
- Adds task awareness and automation
- All standard git worktree operations still work
- Use `git worktree list` to see all worktrees (including manually created ones)
