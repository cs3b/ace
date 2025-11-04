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

# List all worktrees with task associations
ace-git-worktree list --show-tasks

# Switch to a task worktree
cd $(ace-git-worktree switch 081)

# Remove a task worktree with cleanup
ace-git-worktree remove --task 081

# Clean up deleted worktrees
ace-git-worktree prune
```

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

Configuration is loaded from `.ace/git/worktree.yml`. See `.ace.example/git/worktree.yml` for a complete template:

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

# Force removal (with uncommitted changes)
ace-git-worktree remove --task 081 --force

# Keep directory (remove git tracking only)
ace-git-worktree remove --task 081 --keep-directory
```

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

- **ace-support-core** (~> 0.9.0) - Configuration cascade management
- **ace-git-diff** (~> 0.1.0) - Safe git command execution
- **ace-taskflow** (~> 0.9.0) - Task metadata and status management

## Development

### Setup

```bash
git clone https://github.com/ace-ecosystem/ace-meta
cd ace-meta/ace-git-worktree
bundle install
```

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
- **ace-git-diff**: Safe git command execution
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
- Verify task ID: `ace-taskflow task show 081`
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

Bug reports and pull requests are welcome on GitHub at https://github.com/ace-ecosystem/ace-meta.