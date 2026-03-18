# ace-git-worktree

Task-aware git worktree management for the ACE ecosystem.

[![Gem Version](https://badge.fury.io/rb/ace-git-worktree.svg)](https://badge.fury.io/rb/ace-git-worktree)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**ace-git-worktree** provides seamless, task-focused development workflows by creating and managing git worktrees integrated with ACE's task management system. It enables both human developers and AI agents to efficiently work on multiple tasks concurrently without context switching overhead.

## Features

- 🔗 **Task-Aware Worktree Creation** - Automatically create worktrees with task metadata
- 📋 **ace-taskflow Integration** - Fetch task information and update status automatically
- ⚙️ **Configuration-Driven** - Customizable naming conventions and behaviors
- 🔧 **Mise Automation** - Automatic `mise trust` execution for development environments
- 🌳 **Traditional Support** - Standard git worktree operations (create, list, remove, prune, switch)
- 🎯 **AI-Friendly** - Deterministic output for automated agents and workflows
- 🏗️ **ATOM Architecture** - Clean, maintainable code structure

## Quick Start

### Installation

```bash
gem install ace-git-worktree
```

Or add to your Gemfile:

```ruby
gem 'ace-git-worktree'
```

### Basic Usage

```bash
# Create a task-aware worktree
ace-git-worktree create --task 081

# Create a worktree for a GitHub PR
ace-git-worktree create --pr 26

# Create a worktree from a remote branch
ace-git-worktree create --from origin/feature/auth
ace-git-worktree create -b origin/feature/auth  # Short form

# Create a worktree from a local branch
ace-git-worktree create --from my-feature

# List all worktrees with task associations
ace-git-worktree list --show-tasks

# Switch to a task worktree
cd $(ace-git-worktree switch 081)

# Remove a task worktree with cleanup
ace-git-worktree remove --task 081

# Clean up deleted worktrees
ace-git-worktree prune
```

## PR and Branch-Based Workflows

**ace-git-worktree** supports creating worktrees directly from GitHub pull requests or specific branches, streamlining code review and feature development workflows.

### PR Worktrees

Create isolated worktrees for reviewing or working on pull requests:

```bash
# Create worktree for PR #26
ace-git-worktree create --pr 26

# Alternative syntax
ace-git-worktree create --pull-request 26

# With dry-run to preview
ace-git-worktree create --pr 26 --dry-run
```

**Requirements:**
- GitHub CLI (`gh`) must be installed and authenticated
- Run `gh auth login` if not already authenticated

**Features:**
- Automatically fetches PR metadata and branch information
- Creates worktree with remote tracking
- **Fork PR Detection**: Detects cross-repository PRs and warns about read-only limitations
- Configurable naming conventions

**Fork PR Warning:**
When creating a worktree for a PR from a forked repository, you'll see:
```
⚠️  This PR is from a fork (user/repo). You can review the code but cannot push directly.
```
This prevents confusion when trying to push changes to a read-only fork branch.

**Default Behavior:**
- Directory: `.ace-wt/ace-pr-26/`
- Branch: `pr-26` tracking `origin/<pr-head-branch>`

### Branch Worktrees

Create worktrees from existing branches (local or remote):

```bash
# Remote branch (auto-fetches and sets up tracking)
ace-git-worktree create --from origin/feature/authentication
ace-git-worktree create -b upstream/release/v2.0  # Short form

# Local branch (no tracking)
ace-git-worktree create --from my-local-feature

# Complex branch names (handles slashes)
ace-git-worktree create --from origin/feature/auth/oauth2
```

**Features:**
- Auto-detects remote vs. local branches
- Automatically fetches remote branches before creation
- Sets up tracking for remote branches
- Preserves full branch path to avoid naming collisions

**Naming:**
- Remote `origin/feature/auth` → Branch: `feature/auth`, Dir: `feature-auth`
- Local `my-feature` → Branch: `my-feature`, Dir: `my-feature`

### Configuration

Customize PR and branch worktree behavior in `.ace/git/worktree.yml`:

```yaml
git:
  worktree:
    pr:
      directory_format: "ace-pr-{number}"  # PR worktree directory
      branch_format: "pr-{number}-{slug}"   # Local branch name
      remote_name: "origin"                # Default remote
      fetch_before_create: true            # Auto-fetch remote

    branch:
      fetch_if_remote: true                # Auto-fetch remote branches
      auto_detect_remote: true             # Auto-detect remote vs local
```

**Template Variables for PR Format:**
- `{number}` - PR number (e.g., `26`)
- `{slug}` - Slugified PR title (e.g., `add-authentication`)
- `{base_branch}` - Base branch name (e.g., `main`)

## Task-Aware Workflow

The primary workflow creates isolated development environments for tasks with integrated status tracking:

1. **Create worktree for task**: `ace-git-worktree create --task 081`
   - Fetches task metadata from ace-taskflow
   - Marks task as in-progress (configurable)
   - Adds worktree metadata to task file
   - Commits task changes to main branch
   - Creates worktree with naming: `.ace-wt/task.081/`
   - Creates branch: `081-slug-of-task-title`
   - Automatically trusts `mise.toml` if present

2. **Work in isolated environment**: `cd $(ace-git-worktree switch 081)`
   - Clean, isolated workspace for the task
   - No context switching between tasks
   - All changes tracked in separate branch

3. **Cleanup when done**: `ace-git-worktree remove --task 081`
   - Removes worktree metadata from task
   - Cleans up git worktree
   - Optionally removes directory

## Configuration

Configuration is loaded from `.ace/git/worktree.yml`. See `.ace-defaults/git/worktree.yml` for a complete template:

```yaml
git:
  worktree:
    root_path: ".ace-wt"                    # Worktree root directory
    mise_trust_auto: true                     # Automatic mise trust

    task:
      directory_format: "task.{id}"           # task.081
      branch_format: "{id}-{slug}"           # 081-fix-authentication-bug
      auto_mark_in_progress: true            # Mark tasks as in-progress
      auto_commit_task: true                  # Commit task changes
      add_worktree_metadata: true            # Add metadata to task files

    cleanup:
      on_merge: false                         # Auto-cleanup on merge
      on_delete: true                         # Auto-cleanup on delete
```

### Worktree Root Path

The `root_path` setting determines where worktrees are created. It supports flexible configurations:

**Inside project (default):**
```yaml
root_path: ".ace-wt"              # Creates: project/.ace-wt/task-name/
```

**Outside project (parent directory):**
```yaml
root_path: "../"                   # Creates: parent-dir/task-name/
```

**Custom location:**
```yaml
root_path: "~/worktrees"           # Creates: ~/worktrees/task-name/
root_path: "/var/worktrees"        # Creates: /var/worktrees/task-name/
```

**Benefits of external worktrees:**
- Keeps project directory clean
- Avoids IDE file watcher overhead
- Prevents nested git repository issues
- Easier to manage separate disk space

**Note:** Relative paths are resolved relative to the project root, not the current working directory.

### After-Create Hooks

You can configure commands to run automatically after successful worktree creation (both classic and task-based):

```yaml
git:
  worktree:
    hooks:
      after_create:
        - command: "find {worktree_path} -maxdepth 1 -name 'mise*.toml' -exec mise trust {} \\;"
          timeout: 5
          continue_on_error: true
        - command: "echo 'Worktree ready at {worktree_path}'"
          timeout: 2
```

**Available template variables:**
- `{worktree_path}` - Full path to the created worktree
- `{project_root}` - Project root directory
- `{task_id}` - Task ID (only for task-based worktrees)

**Hook options:**
- `command` - Shell command to execute (required)
- `timeout` - Timeout in seconds (default: 10)
- `continue_on_error` - Continue if hook fails (default: true)

**Common use cases:**
- Automatically trust mise.toml files
- Initialize development environment
- Set up IDE workspace files
- Run post-setup scripts

Hook failures are non-blocking by default and appear as warnings in the output.

### Template Variables

Available variables for naming formats:
- `{id}` - Task numeric ID (e.g., `081`)
- `{task_id}` - Full task ID (e.g., `task.081`)
- `{release}` - Release version (e.g., `v.0.9.0`)
- `{slug}` - URL-safe slug from task title (e.g., `fix-authentication-bug`)

## Commands Reference

### create
Create new worktrees (task-aware or traditional)

```bash
# Task-aware creation
ace-git-worktree create --task 081
ace-git-worktree create --task v.0.9.0+081

# Traditional creation
ace-git-worktree create feature-branch

# Options
--path <path>              Custom worktree path
--dry-run                  Show what would be created
--no-mise-trust           Skip automatic mise trust
--no-status-update        Skip marking task as in-progress
--no-commit               Skip committing task changes
```

### list
List worktrees with filtering and formatting

```bash
# List all worktrees
ace-git-worktree list

# With task associations
ace-git-worktree list --show-tasks

# Different formats
ace-git-worktree list --format json
ace-git-worktree list --format simple

# Filtering
ace-git-worktree list --task-associated
ace-git-worktree list --search auth
```

### switch
Switch to worktree by various identifiers

```bash
# By task ID
cd $(ace-git-worktree switch 081)

# By branch name
cd $(ace-git-worktree switch feature-branch)

# By directory name
cd $(ace-git-worktree switch task.081)

# By full path
cd $(ace-git-worktree switch /path/to/worktree)
```

### remove
Remove worktrees with safety checks

```bash
# Remove task worktree
ace-git-worktree remove --task 081

# Remove by branch name
ace-git-worktree remove feature-branch

# Remove worktree AND delete the branch (long form)
ace-git-worktree remove feature-branch --delete-branch

# Remove worktree AND delete the branch (short form)
ace-git-worktree remove feature-branch -db

# Force removal (with uncommitted changes and unmerged branch)
ace-git-worktree remove --task 081 --force -db

# Keep directory (remove git tracking only)
ace-git-worktree remove --task 081 --keep-directory
```

**Branch Deletion Behavior:**
- By default, removing a worktree keeps the associated branch
- Use `--delete-branch` (or `-db`) to also delete the branch after worktree removal
- Without `--force`, only merged branches are deleted (safe mode)
- With `--force`, unmerged branches can be deleted (use with caution)

**Orphaned Branch Cleanup:**
If a worktree has already been removed but the branch still exists, you can delete the orphaned branch:

```bash
# First removal (worktree only)
ace-git-worktree remove feature-branch
# → Worktree removed, branch still exists

# Second removal (delete orphaned branch)
ace-git-worktree remove feature-branch --delete-branch
# → Deleted orphaned branch: feature-branch
```

This works for both classic and task-based branches.

### prune
Clean up deleted worktrees

```bash
# Prune git metadata
ace-git-worktree prune

# Remove orphaned directories too
ace-git-worktree prune --cleanup-directories

# Dry run to preview
ace-git-worktree prune --dry-run
```

### config
Show and manage configuration

```bash
# Show current configuration
ace-git-worktree config
ace-git-worktree config --show

# Validate configuration
ace-git-worktree config --validate

# Show configuration file locations
ace-git-worktree config --files
```

## Architecture

ace-git-worktree follows the ATOM architecture pattern:

- **Atoms**: Pure functions (git operations, path manipulation, string processing)
- **Molecules**: Business logic components (task fetching, worktree operations, metadata management)
- **Organisms**: High-level orchestrators (complete workflows, unified interfaces)
- **Models**: Data structures with validation (configuration, task metadata, worktree info)
- **Commands**: CLI interface implementations

## Dependencies

### Required Dependencies

- **ace-support-core** (>= 0.9.0) - Configuration cascade management
- **ace-git** (~> 0.3.6) - Unified git operations with PR metadata, command execution, and diff support

### Compatibility

| ace-git-worktree | ace-git | Notes |
|------------------|---------|-------|
| 0.6.0+           | ~> 0.3  | Uses ace-git for git operations and PR metadata |
| 0.5.x            | N/A     | Pre-ace-git (used internal git commands) |

### Optional Dependencies

- **ace-taskflow** (>= 0.10.0) - Task metadata and status management
  - Required for task-aware worktree operations
  - Used for fetching task information and updating status
  - Not required for traditional worktree operations

### System Dependencies

- **git** (version 2.0+) - Git version control system
- **mise** (optional) - Development environment manager
  - Used for automatic environment setup
  - If not available, mise trust operations are skipped

## Troubleshooting

### Common Issues

#### ace-taskflow not found

**Error:** `ace-taskflow is not available or not in PATH`

**Solutions:**
```bash
# 1. Install ace-taskflow
gem install ace-taskflow

# 2. Check if it's in PATH
which ace-taskflow

# 3. Add to PATH if needed (example for bash)
echo 'export PATH="$HOME/.gem/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Alternative:** Use traditional worktree creation without task integration:
```bash
ace-git-worktree create <branch-name>
```

#### Git repository not found

**Error:** `fatal: not a git repository` or `git command failed`

**Solutions:**
```bash
# 1. Initialize git repository
git init

# 2. Check git status
git status

# 3. Ensure you're in the correct directory
pwd
ls -la .git
```

#### Permission denied errors

**Error:** `Permission denied` or `access denied`

**Solutions:**
```bash
# 1. Check directory permissions
ls -la

# 2. Ensure git repository is writable
chmod -R u+w .git

# 3. Check worktree directory permissions
ls -la /path/to/worktrees
```

#### Task not found

**Error:** `Task not found` or `Task 'XXX' does not exist`

**Solutions:**
```bash
# 1. Check available tasks
ace-task list

# 2. Verify task ID format
# Try these formats: 081, task.081, v.0.9.0+081

# 3. Check current release context
ace-release

# 4. List recent tasks
ace-task list recent
```

#### Worktree already exists

**Error:** `Worktree path already exists` or `Directory already exists`

**Solutions:**
```bash
# 1. List existing worktrees
ace-git-worktree list

# 2. Use different path
ace-git-worktree create --task 081 --path /different/path

# 3. Remove existing worktree first
ace-git-worktree remove /path/to/existing/worktree

# 4. Use force flag (caution)
ace-git-worktree create --task 081 --force
```

#### Configuration issues

**Error:** `Configuration not found` or `Invalid configuration`

**Solutions:**
```bash
# 1. Show current configuration
ace-git-worktree config show

# 2. Validate configuration
ace-git-worktree config validate

# 3. Show configuration file locations
ace-git-worktree config files

# 4. Create example configuration
mkdir -p .ace/git
cp ace-git-worktree/.ace-defaults/git/worktree.yml .ace/git/worktree.yml
```

### Debug Mode

Enable verbose output for debugging:

```bash
# Use --verbose flag where available
ace-git-worktree --verbose create --task 081

# Check ace-taskflow availability
ace-taskflow --version

# Test git operations
git worktree list
git status
```

### Getting Help

```bash
# Show general help
ace-git-worktree --help

# Show command-specific help
ace-git-worktree create --help
ace-git-worktree list --help
ace-git-worktree switch --help

# Check version
ace-git-worktree --version
```

### Reporting Issues

When reporting issues, include:

1. **Command used:** Full command with arguments
2. **Error message:** Complete error output
3. **System information:**
   ```bash
   ace-git-worktree --version
   git --version
   ruby --version
   which ace-taskflow
   ```
4. **Configuration:** `ace-git-worktree config show`
5. **Git status:** `git status` and `git worktree list`

For more help, open an issue at: https://github.com/cs3b/ace/issues

## Development

### Setup

```bash
git clone https://github.com/cs3b/ace
cd ace/ace-git-worktree
bundle install
```

### Mono-Repo Development (Recommended)

For local development in the ACE mono-repo, you can run ace-git-worktree directly without installing the gem:

```bash
# Run from mono-repo root using binstub wrapper
./bin/ace-git-worktree --help
./bin/ace-git-worktree create --task 081
./bin/ace-git-worktree list --show-tasks

# All commands work the same as the installed gem
# Uses root Gemfile for consistent development environment
# No need for local gem installation during development
```

**Benefits of mono-repo development:**
- **No Installation Required**: Run commands directly without gem installation
- **Consistent Environment**: Uses mono-repo root Gemfile for dependency management
- **Faster Development**: Skip gem build/install cycle during development
- **Workspace Awareness**: Proper git worktree context handling

### Testing

```bash
# Run all tests
rake test

# Run with coverage
rake coverage

# Run specific test types
ruby -Ilib:test test/atoms/git_command_test.rb
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Integration with ACE Ecosystem

ace-git-worktree integrates seamlessly with other ACE tools:

- **ace-taskflow**: Task metadata fetching and status updates
- **ace-git-commit**: Consistent commit message generation
- **ace-git**: Unified git operations (command execution, PR metadata, diff generation)
- **ace-support-core**: Configuration cascade management

## Examples

### Daily Development Workflow

```bash
# Start work on task 081
ace-git-worktree create --task 081
cd $(ace-git-worktree switch 081)

# Work on the task...
git add .
git commit -m "Implement authentication fix"

# When task is complete
cd ..
ace-git-worktree remove --task 081
```

### AI Agent Integration

```bash
# AI agent can programmatically find and switch to worktrees
WORKTREE_PATH=$(ace-git-worktree switch --task 081)
cd "$WORKTREE_PATH"

# Get worktree status in JSON format
STATUS=$(ace-git-worktree list --format json --show-tasks)
echo "$STATUS" | jq '.worktrees[] | select(.task_id == "081")'
```

### Bulk Operations

```bash
# List all task-associated worktrees
ace-git-worktree list --task-associated --format simple

# Clean up all orphaned worktrees
ace-git-worktree prune --cleanup-directories --verbose
```

## Troubleshooting

### Common Issues

**"Task not found"**
- Verify task ID: `ace-task show 081`
- Check ace-taskflow is available: `ace-taskflow --version`

**"Not in a git repository"**
- Run from git repository root
- Initialize git: `git init`

**"Configuration invalid"**
- Validate: `ace-git-worktree config --validate`
- Check file locations: `ace-git-worktree config --files`

**"Worktree has uncommitted changes"**
- Commit or stash changes first
- Use `--force` to remove anyway (changes will be lost)

### Debug Mode

Enable verbose output for debugging:

```bash
ace-git-worktree create --task 081 --dry-run
ace-git-worktree list --verbose
ace-git-worktree config --show
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cs3b/ace.