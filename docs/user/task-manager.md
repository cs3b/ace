# Task Manager CLI User Guide

## Overview

The Task Manager is a command-line tool that provides a focused interface for managing development tasks within the Coding Agent Tools ecosystem. It offers a streamlined way to find, track, and generate task identifiers for project management workflows.

### Key Features

- **Find Next Tasks**: Identify the next actionable task to work on
- **Browse Recent Activity**: View recently modified tasks and their status
- **List All Tasks**: See complete task overview with dependency relationships
- **Generate Task IDs**: Create new task identifiers for project releases
- **Smart Filtering**: Use limits and time-based filters to focus on relevant tasks

## Installation

The task-manager CLI is included with the Coding Agent Tools gem:

```bash
# Install the gem
gem install coding_agent_tools

# Or add to your Gemfile
gem 'coding_agent_tools'
bundle install
```

Once installed, the `task-manager` command will be available in your PATH.

## Quick Start

```bash
# Get help
task-manager --help

# Find your next task to work on
task-manager next

# See what's been happening recently
task-manager recent

# Generate a new task ID
task-manager generate-id v.1.0.0
```

## Commands Reference

### `task-manager next`

Find the next actionable task to work on based on dependencies and priority.

**Usage:**
```bash
task-manager next [OPTIONS]
```

**Options:**
- `--limit=VALUE` - Maximum number of tasks to return (default: 1)
- `--debug, -d` - Enable debug output for troubleshooting
- `--help, -h` - Show command help

**Examples:**

```bash
# Get the single next task
task-manager next

# Get the next 3 actionable tasks
task-manager next --limit 3

# Debug mode for troubleshooting
task-manager next --debug
```

**Sample Output:**
```
  ID:    v.0.3.0+task.09
  Title: Update Task Management Binstubs
  Path:  dev-taskflow/current/v.0.3.0-migration/tasks/v.0.3.0+task.09-update-task-management-binstubs.md
  Status: pending
  Dependencies: v.0.3.0+task.08
```

### `task-manager recent`

Find recently modified tasks based on file modification time.

**Usage:**
```bash
task-manager recent [OPTIONS]
```

**Options:**
- `--last=VALUE` - Time period to search (default: "1.day")
  - Formats: `2.days`, `1.week`, `3.hours`, `30.minutes`
- `--limit=VALUE` - Maximum number of tasks to return (default: 10)
- `--debug, -d` - Enable debug output
- `--help, -h` - Show command help

**Examples:**

```bash
# Recent tasks from the last day (default)
task-manager recent

# Tasks from the last 2 days, limit to 5 results
task-manager recent --last 2.days --limit 5

# Recent tasks from the last week
task-manager recent --last 1.week

# Show only the 3 most recent tasks
task-manager recent --limit 3
```

**Sample Output:**
```
Recent Tasks (1/30 shown):
==================================================
  ID:    v.0.3.0+task.08
  Title: Implement Task CLI Commands
  Path:  dev-taskflow/current/v.0.3.0-migration/tasks/v.0.3.0+task.08-implement-task-cli-commands.md
  Status: done
  Modified: 1 hours ago
  Dependencies: v.0.3.0+task.07
```

### `task-manager list`

List all tasks in the current release with dependency-aware ordering.

**Usage:**
```bash
task-manager list [OPTIONS]
```

**Options:**
- `--show-cycles` - Show additional information about dependency cycles
- `--debug, -d` - Enable debug output
- `--help, -h` - Show command help

**Examples:**

```bash
# List all tasks
task-manager list

# Show dependency cycle information
task-manager list --show-cycles

# Debug mode
task-manager list --debug
```

**Sample Output:**
```
All Tasks (15 total):
==================================================

  1. v.0.3.0+task.01
     Title: Setup Project Structure
     Status: DONE
     Path: dev-taskflow/current/v.0.3.0-migration/tasks/v.0.3.0+task.01-setup.md
     Priority: HIGH

  2. v.0.3.0+task.02
     Title: Implement Core Features
     Status: IN-PROGRESS
     Path: dev-taskflow/current/v.0.3.0-migration/tasks/v.0.3.0+task.02-core.md
     Dependencies: v.0.3.0+task.01
     Priority: HIGH
```

### `task-manager generate-id`

Generate new task identifiers for the current or specified release.

**Usage:**
```bash
task-manager generate-id [VERSION] [OPTIONS]
```

**Arguments:**
- `VERSION` - Version string (e.g., 'v.0.3.0'). Auto-detected if not provided.

**Options:**
- `--limit=VALUE` - Number of task IDs to generate (default: 1)
- `--debug, -d` - Enable debug output
- `--help, -h` - Show command help

**Examples:**

```bash
# Generate next task ID (auto-detect version)
task-manager generate-id

# Generate task ID for specific version
task-manager generate-id v.1.0.0

# Generate multiple task IDs
task-manager generate-id --limit 3

# Generate multiple IDs for specific version
task-manager generate-id v.1.0.0 --limit 5
```

**Sample Output:**
```bash
# Single ID
v.0.3.0+task.09

# Multiple IDs
Generated 3 task IDs:
  v.0.3.0+task.01
  v.0.3.0+task.02
  v.0.3.0+task.03
```

### `task-manager version`

Display the current version of the task manager.

**Usage:**
```bash
task-manager version
task-manager --version
task-manager -v
```

**Sample Output:**
```
Task Manager 0.2.71
```

## Time Period Formats

The `--last` option in the `recent` command supports flexible time period formats:

| Format | Description | Example |
|--------|-------------|---------|
| `X.days` | X number of days | `2.days`, `7.days` |
| `X.weeks` | X number of weeks | `1.week`, `2.weeks` |
| `X.hours` | X number of hours | `3.hours`, `12.hours` |
| `X.minutes` | X number of minutes | `30.minutes`, `90.minutes` |

## Common Workflows

### Daily Task Management

```bash
# Start your day: see what you worked on recently
task-manager recent --last 1.day

# Get your next task
task-manager next

# Need more options? Get the next 3 tasks
task-manager next --limit 3
```

### Weekly Review

```bash
# See all activity from the past week
task-manager recent --last 1.week --limit 20

# Get overview of all current tasks
task-manager list
```

### Project Planning

```bash
# Generate task IDs for new feature
task-manager generate-id v.2.0.0 --limit 5

# Check all tasks to understand project status
task-manager list --show-cycles
```

### Sprint Management

```bash
# See recent completed work
task-manager recent --last 2.weeks | grep "Status: done"

# Find next highest priority tasks
task-manager next --limit 10
```

## Troubleshooting

### Common Issues

#### "No actionable tasks found"
This means either:
- All tasks are completed (`done` status)
- Remaining tasks have unmet dependencies
- No tasks exist in the current release

**Solution:** Check task dependencies and status:
```bash
task-manager list --show-cycles
```

#### "Could not determine release version"
The `generate-id` command couldn't auto-detect the current release.

**Solution:** Specify the version explicitly:
```bash
task-manager generate-id v.1.0.0
```

#### "Path failed safety validation"
Security validation is preventing access to task files.

**Solution:** Run from the project root directory or use debug mode:
```bash
task-manager next --debug
```

### Debug Mode

Use the `--debug` flag with any command to get detailed error information:

```bash
task-manager next --debug
task-manager recent --debug --last 1.week
```

Debug mode provides:
- Full error stack traces
- Path resolution details
- Security validation information
- Task loading diagnostics

### Getting Help

```bash
# General help
task-manager --help

# Command-specific help
task-manager next --help
task-manager recent --help
task-manager list --help
task-manager generate-id --help
```

## Integration with Development Workflows

### Git Hooks

Integrate task management into your git workflow:

```bash
# In a pre-commit hook
NEXT_TASK=$(task-manager next --limit 1)
echo "Next task after this commit: $NEXT_TASK"
```

### CI/CD Integration

Use in continuous integration:

```bash
# Check for dependency cycles
task-manager list --show-cycles
if [ $? -ne 0 ]; then
  echo "Task dependency cycles detected!"
  exit 1
fi
```

### Project Automation

```bash
# Generate weekly reports
echo "## Tasks completed this week"
task-manager recent --last 1.week | grep "Status: done"

echo "## Next priorities"
task-manager next --limit 5
```

## Best Practices

1. **Regular Reviews**: Use `task-manager recent` daily to track progress
2. **Dependency Management**: Check `task-manager list --show-cycles` regularly
3. **Planning**: Use `task-manager next --limit 10` for sprint planning
4. **Documentation**: Include task IDs in commit messages and documentation
5. **Automation**: Integrate task-manager commands into scripts and workflows

## Related Tools

- **coding_agent_tools task**: Full CLI interface with additional options
- **bin/tn**: Project-specific task navigation script
- **bin/tal**: Project-specific task listing script

The task-manager provides a focused, user-friendly interface to the underlying task management system, making it easy to stay organized and productive in your development workflow.