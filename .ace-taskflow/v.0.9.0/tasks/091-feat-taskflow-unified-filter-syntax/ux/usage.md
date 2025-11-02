# Unified Filter Syntax - Usage Guide

## Overview

The unified filter syntax provides a consistent, flexible way to filter tasks, ideas, and releases across all `ace-taskflow` commands. Instead of multiple specialized flags (`--status`, `--priority`, etc.), you now use a single `--filter key:value` syntax that works with any frontmatter field.

**Key Benefits:**
- **Consistent**: One syntax for all filtering needs
- **Flexible**: Filter on any frontmatter field (status, priority, custom fields)
- **Expressive**: Support for OR values, negation, and array matching
- **Extensible**: Works automatically with custom frontmatter fields you add

## Command Types

All filter commands are executed via **bash CLI**:

```bash
# Bash CLI commands
ace-taskflow tasks --filter status:pending
ace-taskflow ideas --filter status:done --filter priority:high
ace-taskflow releases --filter status:active
```

If using **Claude Code** slash commands, these map to the same bash commands:

```
/ace:work-on-tasks --filter status:pending
# Translates to: ace-taskflow tasks --filter status:pending
```

## Command Structure

### Basic Syntax

```bash
ace-taskflow <command> [preset] --filter <key>:<value> [--filter <key>:<value> ...]
```

**Components:**
- `<command>`: `tasks`, `ideas`, or `releases`
- `[preset]`: Optional preset name (next, all, recent, done, etc.)
- `--filter <key>:<value>`: Filter specification (repeatable)
- `--filter-clear`: Clear preset filters before applying new ones

### Filter Operators

1. **Simple Match**: `--filter key:value`
   - Exact match, case-insensitive
   - Example: `--filter status:pending`

2. **OR Values**: `--filter key:value1|value2|value3`
   - Match any of the pipe-separated values
   - Example: `--filter status:pending|in-progress`

3. **Negation**: `--filter key:!value`
   - Exclude matches (NOT operator)
   - Example: `--filter status:!done`

4. **Array Matching**: `--filter key:value`
   - For array fields, matches if value is in the array
   - Example: `--filter dependencies:v.0.9.0+task.081`

5. **Multiple Filters**: Multiple `--filter` flags
   - AND logic: all filters must match
   - Example: `--filter status:pending --filter priority:high`

## Usage Scenarios

### Scenario 1: Find Pending High-Priority Tasks

**Goal**: Find all pending tasks with high priority in the current release

```bash
ace-taskflow tasks --filter status:pending --filter priority:high
```

**Expected Output**:
```
v.0.9.0: 2/97 tasks • Mono-Repo Multiple Gems
Ideas: ✅ 44 | ❓ 23 • 67 total
Tasks: ⚫ 10 | ⚪ 5 | 🟡 0 | 🟢 82 | 🔴 0 • 97 total • 85% complete
========================================
  v.0.9.0+089     ⚪ Create ace-git-worktree gem with task integration
    .ace-taskflow/v.0.9.0/tasks/089-...
    Estimate: 3-4 weeks | Dependencies: v.0.9.0+task.090
```

### Scenario 2: Find Tasks Excluding Certain Statuses

**Goal**: Find all tasks that are NOT done or blocked

```bash
ace-taskflow tasks all --filter status:!done --filter status:!blocked
```

**Alternative (using OR with negation)**:
```bash
ace-taskflow tasks all --filter status:pending|in-progress|draft
```

**Expected Output**: All tasks except done and blocked ones

### Scenario 3: Filter by Custom Frontmatter Fields

**Goal**: Find tasks assigned to the backend team in sprint 12

```bash
ace-taskflow tasks --filter team:backend --filter sprint:12
```

**Note**: Works with any custom fields you add to task frontmatter

**Expected Output**: Only tasks matching both team and sprint criteria

### Scenario 4: Find Recently Modified Ideas with Specific Status

**Goal**: Find ideas modified in last 7 days that are still pending

```bash
ace-taskflow ideas recent --filter status:pending
```

**Expected Output**: Recent pending ideas, sorted by modification time

### Scenario 5: Clear Preset Filters and Apply Custom Filters

**Goal**: Override the 'next' preset's default filters to show all statuses

```bash
ace-taskflow tasks next --filter-clear --filter priority:high
```

**Behavior**:
- `--filter-clear` removes the preset's default `status: [pending, in-progress]` filter
- Only applies the `priority:high` filter
- Keeps preset's release scope and sorting

**Expected Output**: All high-priority tasks regardless of status

### Scenario 6: Find Tasks with Specific Dependencies

**Goal**: Find all incomplete tasks that depend on task.081

```bash
ace-taskflow tasks --filter dependencies:v.0.9.0+task.081 --filter status:!done
```

**Expected Output**: Tasks with task.081 in their dependencies array that aren't done

## Command Reference

### Tasks Command

```bash
ace-taskflow tasks [preset] [options] [--filter key:value ...]
```

**Common Filters:**
- `--filter status:pending|in-progress|done|blocked|draft`
- `--filter priority:high|medium|low`
- `--filter estimate:2h` (exact match on estimate)
- `--filter dependencies:task.081` (array contains)

**Example**:
```bash
# Next actionable high-priority tasks
ace-taskflow tasks next --filter priority:high

# All tasks modified in last 3 days
ace-taskflow tasks recent --days 3

# Tasks ready to work on (pending, no blockers)
ace-taskflow tasks --filter status:pending --filter status:!blocked
```

**Internal Tools Used**: `TasksCommand`, `FilterParser`, `FilterApplier`, `ListPresetManager`

### Ideas Command

```bash
ace-taskflow ideas [preset] [options] [--filter key:value ...]
```

**Common Filters:**
- `--filter status:pending|done`
- `--filter author:username` (custom field)
- `--filter tags:api` (array matching)

**Example**:
```bash
# Pending ideas in backlog
ace-taskflow ideas --filter status:pending --release backlog

# Ideas tagged with 'api' that are done
ace-taskflow ideas --filter tags:api --filter status:done

# Recent ideas (last 7 days) that are pending
ace-taskflow ideas recent --days 7 --filter status:pending
```

**Internal Tools Used**: `IdeasCommand`, `FilterParser`, `FilterApplier`, `ListPresetManager`

### Releases Command

```bash
ace-taskflow releases [preset] [options] [--filter key:value ...]
```

**Common Filters:**
- `--filter status:active|backlog|done`

**Example**:
```bash
# Active releases only
ace-taskflow releases --filter status:active

# All releases except done
ace-taskflow releases all --filter status:!done
```

**Internal Tools Used**: `ReleasesCommand`, `FilterParser`, `FilterApplier`, `ListPresetManager`

## Tips and Best Practices

### Combining Filters Effectively

- **Use OR for alternatives**: `--filter status:pending|in-progress` (status is pending OR in-progress)
- **Use multiple --filter for AND**: `--filter status:pending --filter priority:high` (pending AND high priority)
- **Use negation to exclude**: `--filter status:!done` (exclude done tasks)

### Working with Presets

- **Enhance presets**: Add filters to preset defaults
  ```bash
  ace-taskflow tasks next --filter priority:high
  # Applies preset's status filter (pending|in-progress) AND priority:high
  ```

- **Override presets**: Use `--filter-clear` to ignore preset filters
  ```bash
  ace-taskflow tasks next --filter-clear --filter status:all
  # Ignores preset's status filter, applies your filter instead
  ```

### Performance Considerations

- Filters operate on in-memory data after loading tasks/ideas
- Performance is typically <100ms for datasets up to 500 items
- Complex filter combinations have minimal performance impact

### Common Pitfalls to Avoid

❌ **Don't use old flags** - They are removed:
```bash
ace-taskflow tasks --status pending  # ERROR! Use --filter status:pending
```

❌ **Don't forget quotes** for values with spaces or special characters:
```bash
ace-taskflow tasks --filter "title:API Review"  # Correct
```

❌ **Don't expect regex matching** - Filters use exact matching:
```bash
ace-taskflow tasks --filter "title:task.*"  # Won't work as regex
```

✅ **Do use case-insensitive matching** - It's automatic:
```bash
ace-taskflow tasks --filter status:PENDING  # Works (matches 'pending')
```

## Migration Guide

### From Legacy Flags to --filter Syntax

| **Old Flag** | **New Syntax** | **Example** |
|--------------|----------------|-------------|
| `--status pending,done` | `--filter status:pending\|done` | `ace-taskflow tasks --filter status:pending\|done` |
| `--priority high` | `--filter priority:high` | `ace-taskflow tasks --filter priority:high` |
| `--backlog` | **KEPT** - Release selection alias | `ace-taskflow tasks --backlog` (unchanged) |
| `--current` | **KEPT** - Release selection alias | `ace-taskflow tasks --current` (unchanged) |
| `--active` (releases) | `--filter status:active` | `ace-taskflow releases --filter status:active` |
| `--done` (releases) | `--filter status:done` or use preset | `ace-taskflow releases done` or `--filter status:done` |

### Migration Examples

**Before (v0.9.0)**:
```bash
ace-taskflow tasks --status pending,in-progress --priority high
ace-taskflow releases --active
ace-taskflow ideas --status done
```

**After (v0.10.0+)**:
```bash
ace-taskflow tasks --filter status:pending|in-progress --filter priority:high
ace-taskflow releases --filter status:active
ace-taskflow ideas --filter status:done
```

### Troubleshooting Migration Issues

**Error: "Unknown option: --status"**
- **Cause**: Using removed legacy flag
- **Solution**: Replace with `--filter status:value`

**Error: "Invalid filter syntax"**
- **Cause**: Missing colon or malformed key:value
- **Solution**: Ensure format is `--filter key:value`

**No results with custom fields**
- **Cause**: Custom field name typo or field doesn't exist in frontmatter
- **Solution**: Check frontmatter spelling and case (matching is case-insensitive but field must exist)

**Preset filters not working as expected**
- **Cause**: Using `--filter-clear` unintentionally
- **Solution**: Remove `--filter-clear` to keep preset defaults, or add explicit filters

## Advanced Usage

### Complex Multi-Filter Queries

Find backend tasks in sprint 12 that are high priority and not blocked:
```bash
ace-taskflow tasks \
  --filter team:backend \
  --filter sprint:12 \
  --filter priority:high \
  --filter status:!blocked
```

### Combining with Other Options

```bash
# Filter, sort, and limit
ace-taskflow tasks \
  --filter status:pending \
  --filter priority:high \
  --sort priority:desc \
  --limit 5

# Filter with specific release
ace-taskflow tasks \
  --filter status:pending \
  --release v.0.9.0

# Filter recent items with custom day range
ace-taskflow tasks recent \
  --days 14 \
  --filter status:!done
```

### Using Filters in Scripts

```bash
#!/bin/bash
# Find all high-priority pending tasks and iterate
ace-taskflow tasks --filter status:pending --filter priority:high --path | while read -r task_path; do
  echo "Processing: $task_path"
  # Your processing logic here
done
```

## Summary

The unified `--filter key:value` syntax provides:
- ✅ Consistent filtering across tasks, ideas, and releases
- ✅ Support for any frontmatter field (including custom fields)
- ✅ Flexible operators (OR, negation, array matching)
- ✅ Clear, expressive queries
- ✅ Future-proof extensibility

For detailed implementation information, see the main task specification: `.ace-taskflow/v.0.9.0/tasks/091-feat-taskflow-unified-filter-syntax/task.091.s.md`
