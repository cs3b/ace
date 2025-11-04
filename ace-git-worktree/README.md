# ace-git-worktree

Git worktree management with integrated ACE task awareness. Creates isolated development environments for tasks by automatically fetching task metadata from ace-taskflow and configuring worktrees with consistent naming conventions.

## Overview

`ace-git-worktree` provides:

- **Task-Aware Worktree Creation**: Automatically fetches task metadata and creates appropriately named worktrees
- **Status Management**: Updates task status to in-progress when creating worktrees
- **Metadata Tracking**: Adds worktree information to task frontmatter for clear association
- **Mise Integration**: Automatically trusts mise.toml files in worktrees
- **Configuration-Driven**: All naming conventions and behaviors driven by configuration
- **AI-Native**: Deterministic, parseable output for AI agent consumption

## Installation

Add this gem to your application's Gemfile:

```ruby
gem 'ace-git-worktree'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ace-git-worktree
```

## Quick Start

### Task-Aware Worktree Creation

Create a worktree for a specific task:

```bash
# Create worktree for task 081 (automatically marks as in-progress)
ace-git-worktree create --task 081

# Skip automatic status update
ace-git-worktree create --task 081 --no-status-update

# Use custom commit message
ace-git-worktree create --task 081 --commit-message "feat: starting authentication fix"
```

### Traditional Worktree Creation

Create a worktree without task integration:

```bash
ace-git-worktree create feature-branch --path .ace-wt/feature
```

### Manage Worktrees

```bash
# List all worktrees
ace-git-worktree list --show-tasks

# Switch to a worktree
cd $(ace-git-worktree switch 081)

# Remove a worktree
ace-git-worktree remove 081

# Clean up deleted worktrees
ace-git-worktree prune
```

## Configuration

Configure via `.ace/git/worktree.yml`:

```yaml
git:
  worktree:
    # Root directory for all worktrees
    root_path: ".ace-wt"

    # Mise integration
    mise_trust_auto: true

    # Task-based naming conventions
    task:
      directory_format: "task.{id}"        # Results in: task.081
      branch_format: "{id}-{slug}"         # Results in: 081-fix-bug

      # Workflow automation
      auto_mark_in_progress: true
      auto_commit_task: true
      commit_message_format: "chore(task-{id}): mark as in-progress, creating worktree"
      add_worktree_metadata: true
```

### Template Variables

- `{id}` - Task number (e.g., "081")
- `{task_id}` - Full task ID (e.g., "v.0.9.0+task.081")
- `{release}` - Release version (e.g., "v.0.9.0")
- `{slug}` - Task title slug (e.g., "fix-authentication-bug")

## Commands

### create

Create a new worktree:

```bash
ace-git-worktree create --task <task-id> [options]
ace-git-worktree create <branch-name> [options]
```

Options:
- `--task <id>` - Task identifier (081, task.081, v.0.9.0+081)
- `--path <path>` - Custom worktree path
- `--no-mise-trust` - Skip automatic mise trust
- `--dry-run` - Preview without creating
- `--no-status-update` - Skip marking task as in-progress
- `--no-commit` - Skip committing task changes
- `--commit-message <msg>` - Custom commit message

### list

List all worktrees:

```bash
ace-git-worktree list [--format json|table] [--show-tasks]
```

### switch

Navigate to a worktree:

```bash
ace-git-worktree switch <identifier>
```

### remove

Remove a worktree:

```bash
ace-git-worktree remove <identifier> [--force]
```

### prune

Clean up deleted worktrees:

```bash
ace-git-worktree prune
```

### config

Display current configuration:

```bash
ace-git-worktree config
```

## Architecture

This gem follows the ACE ATOM architecture:

- **Atoms**: Pure functions for git commands, path manipulation, slug generation
- **Molecules**: Worktree operations, task metadata fetching, mise trust execution
- **Organisms**: Orchestration of complete workflows
- **Models**: Data structures for configuration and metadata

## Development

After checking out the repo, run:

```bash
bundle install
rake test
```

To run tests for a specific layer:

```bash
ruby -Ilib:test test/atoms/*_test.rb
ruby -Ilib:test test/molecules/*_test.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/ace-git-worktree.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).