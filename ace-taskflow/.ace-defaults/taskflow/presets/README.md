# Taskflow Preset Configuration

Presets provide semantic, reusable filters for listing tasks, ideas, and releases.

## Usage

Copy any of these example preset files to your project's `.ace/taskflow/presets/` directory and customize as needed:

```bash
# Copy a preset example
cp ace-taskflow/.ace-defaults/taskflow/presets/urgent.yml .ace/taskflow/presets/

# Use the preset
ace-task list urgent
ace-idea list urgent  # If type is null/universal
```

## Preset Structure

```yaml
description: "Human-readable description"
type: "tasks"      # "tasks", "ideas", "releases", or null for universal
release: "current"  # "current", "all", "backlog", or specific release
filters:
  status: ["pending", "in-progress"]  # Status filter
  priority: ["high", "critical"]      # Priority filter
  # Add custom filters as needed
sort:
  by: "priority"    # Sort field: priority, status, modified, id, release
  ascending: false  # Sort direction
display:
  group_by: "release"  # Optional grouping
  show_dates: true     # Show timestamps
  days: 7             # Time window for recent items
```

## Type Configuration

- **`type: "tasks"`** - Preset only available for `ace-task list`
- **`type: "ideas"`** - Preset only available for `ace-idea list`
- **`type: "releases"`** - Preset only available for `ace-release list`
- **`type:` (null/empty)** - Universal preset, available for all commands

## Built-in Presets

The following presets are built-in and can be overridden:

- **next** (tasks) - Actionable tasks (pending + in-progress), priority sorted
- **recent** (universal) - Recently modified items
- **all** (universal) - All items across contexts
- **pending** (universal) - Only pending status items
- **in-progress** (universal) - Only in-progress items
- **done** (universal) - Completed items

## Examples in This Directory

- **urgent.yml** - Critical and high-priority tasks needing attention
- **my-work.yml** - Personal in-progress items
- **backlog-ready.yml** - Backlog tasks ready to start
- **weekly-review.yml** - Items for weekly review meetings

## Composing Presets with Filters

You can apply additional filters on top of presets:

```bash
# Add time filter to any preset
ace-task list urgent --days 3

# Add status filter to preset
ace-idea list --status pending

# Get statistics for a preset
ace-task list urgent --stats
```

## Custom Fields

You can add custom fields to the `display` section for specialized rendering. The command implementation will ignore unknown fields, allowing for future extensibility.