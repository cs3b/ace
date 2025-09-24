# Task 026: Reschedule Subcommand Usage

## Q: How do I configure the default reschedule strategy?

**A:** Set the default strategy in `.ace/taskflow.yml`:

```yaml
# .ace/taskflow.yml
taskflow:
  tasks:
    defaults:
      reschedule_strategy: add_next  # Default: tasks go to front of queue
      # or: reschedule_strategy: add_at_end  # Tasks go to end of queue
```

With `add_next` as default (recommended):
```bash
# Places tasks at front of queue (based on config)
ace-taskflow tasks reschedule 025 026 027

# Override to place at end
ace-taskflow tasks reschedule 025 026 027 --add-at-end
```

## Q: How do I reschedule tasks to change their priority order?

**A:** Use the `tasks reschedule` subcommand with task IDs:

```bash
ace-taskflow tasks reschedule 025 026 027
```

This reorders the specified tasks based on your configured default strategy (or `add_next` if not configured).

## Q: How do I make tasks urgent by moving them to the front?

**A:** Use the `--add-next` flag to place tasks before all other pending tasks:

```bash
ace-taskflow tasks reschedule 031 032 --add-next
```

Expected behavior:
- Tasks 031 and 032 get lower sort values than existing pending tasks
- They appear first when running `ace-taskflow task` (next task)
- Relative order between 031 and 032 is preserved

## Q: What task ID formats are supported?

**A:** The reschedule command accepts multiple formats:

```bash
# Full task ID
ace-taskflow tasks reschedule v.0.9.0+task.025 v.0.9.0+task.026

# Just the numbers
ace-taskflow tasks reschedule 025 026 027

# Task with prefix
ace-taskflow tasks reschedule task.025 task.026

# Mix of formats
ace-taskflow tasks reschedule 025 v.0.9.0+task.026 task.027

# From different contexts
ace-taskflow tasks reschedule backlog+015 v.0.9.0+task.025
```

## Q: How do I position tasks relative to another specific task?

**A:** Use `--after` or `--before` to place tasks relative to another task:

```bash
# Place tasks 025, 026, 027 right after task 029
ace-taskflow tasks reschedule 025 026 027 --after task.029

# Short form using just the number
ace-taskflow tasks reschedule 025 026 027 --after 029

# Place tasks before task 030
ace-taskflow tasks reschedule 025 026 027 --before 030
```

This is particularly useful for:
- Grouping related tasks together
- Inserting prerequisites before dependent tasks
- Maintaining logical task flow

## Q: How does the sort value system work?

**A:** Tasks use a `sort` field in their frontmatter:

```yaml
---
id: v.0.9.0+task.025
status: pending
sort: 1000
---
```

Reschedule behavior:
- `--add-next`: Assigns sort values starting below minimum pending task
- `--add-at-end`: Assigns sort values after maximum task
- `--after <task>`: Assigns sort values immediately after the specified task
- `--before <task>`: Assigns sort values immediately before the specified task
- Default strategy: Configured via `reschedule_strategy` (defaults to `add_next`)
- Preserves gaps between values for future insertions

## Q: Can I reschedule tasks across different releases?

**A:** Yes, but use with caution:

```bash
# Move task from backlog to current release
ace-taskflow tasks reschedule backlog+025 --release v.0.9.0

# Reschedule within specific release
ace-taskflow tasks reschedule 025 026 --release v.0.10.0
```

Note: Cross-release rescheduling may require the move command instead.

## Q: How do I reschedule completed or in-progress tasks?

**A:** The command works with tasks in any status:

```bash
# Reschedule completed tasks (useful for documentation order)
ace-taskflow tasks reschedule 020 021 022 --status done

# Reorder in-progress tasks
ace-taskflow tasks reschedule 025 026 --status in-progress
```

## Q: What happens to task dependencies when rescheduling?

**A:** Dependencies are preserved but you get warnings:

```bash
ace-taskflow tasks reschedule 030 025
# Warning: Task 030 depends on 025 - this may create invalid ordering

ace-taskflow tasks reschedule 025 030 --check-dependencies
# Error: Cannot place 025 after 030 - dependency violation
```

## Q: How do I see the effect of rescheduling?

**A:** Check task order before and after:

```bash
# Before
ace-taskflow tasks --status pending --limit 5

# Reschedule
ace-taskflow tasks reschedule 040 041 042 --add-next

# After
ace-taskflow tasks --status pending --limit 5
# Now shows 040, 041, 042 at the top
```

## Q: Can I reschedule using partial matches?

**A:** Yes, the command supports partial matching:

```bash
# Partial ID match
ace-taskflow tasks reschedule auth login cache
# Finds tasks with "auth", "login", "cache" in their IDs

# Warning if ambiguous
ace-taskflow tasks reschedule user
# Warning: Multiple matches for "user":
#   - v.0.9.0+task.025-user-authentication
#   - v.0.9.0+task.031-user-profile
# Please be more specific
```

## Q: How do I batch reschedule based on patterns?

**A:** Combine with task filtering:

```bash
# Get all bug tasks and prioritize them
ace-taskflow tasks --grep "bug|fix" --format ids | xargs ace-taskflow tasks reschedule --add-next

# Deprioritize all documentation tasks
ace-taskflow tasks --grep "docs|documentation" --format ids | xargs ace-taskflow tasks reschedule --add-at-end
```

## Common Usage Patterns

### With default strategy configured (add_next)
```bash
# Uses configured default - places at front
ace-taskflow tasks reschedule 025 026 027

# Override to place at end
ace-taskflow tasks reschedule 028 029 --add-at-end
```

### Daily prioritization
```bash
# Move today's critical tasks to front
ace-taskflow tasks reschedule 025 026 027 --add-next

# Place follow-up tasks right after current work
ace-taskflow tasks reschedule 031 032 --after 030
```

### Sprint planning
```bash
# Reorder entire sprint backlog
ace-taskflow tasks reschedule 025 026 027 028 029 030 031 032

# Group related features together
ace-taskflow tasks reschedule 040 041 042 --after 039  # UI tasks after design task
ace-taskflow tasks reschedule 043 044 --after 042      # Tests after implementation
```

### Emergency reprioritization
```bash
# Urgent bug fix jumps the queue
ace-taskflow tasks reschedule 045 --add-next

# Insert hotfix before current work
ace-taskflow tasks reschedule 046 --before 025
```

### Dependency management
```bash
# Place prerequisites before dependent task
ace-taskflow tasks reschedule 050 051 --before 052

# Group all related tasks together
ace-taskflow tasks reschedule auth-tasks --after 060
ace-taskflow tasks reschedule db-migration --before auth-tasks
```

## Troubleshooting

### Tasks not appearing in expected order

Check sort values:
```bash
ace-taskflow tasks --debug | grep "sort:"
```

Reset sort values:
```bash
ace-taskflow tasks reschedule --reset-sort
# Renumbers all tasks with clean sort values
```

### Reschedule not working

Verify task status and location:
```bash
# Check if task exists and is editable
ace-taskflow task 025 --content | head -10

# Ensure you have write permissions
ls -la .ace-taskflow/v.0.9.0/t/025/
```