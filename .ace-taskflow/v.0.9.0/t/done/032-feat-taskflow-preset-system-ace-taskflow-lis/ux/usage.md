# Task 032: Preset System for Listings - Usage Examples

## Current Behavior (Before)

```bash
# Default shows all tasks with no filtering
$ ace-taskflow tasks
[Lists ALL tasks]

# Must use flags for filtering
$ ace-taskflow tasks --recent --days 3
$ ace-taskflow tasks --status pending,in-progress
$ ace-taskflow tasks --all --sort priority:desc

# Similar pattern for ideas and releases
$ ace-taskflow ideas --backlog
$ ace-taskflow releases --active
```

## New Behavior (After)

```bash
# Default uses "next" preset (pending & in-progress, sorted by priority)
$ ace-taskflow tasks
Tasks (next preset): 5 actionable items
[Shows only relevant tasks for immediate work]

# Use presets as commands
$ ace-taskflow tasks recent
$ ace-taskflow tasks all
$ ace-taskflow tasks pending
$ ace-taskflow tasks blocked

# Apply filters on top of presets
$ ace-taskflow tasks recent --days 1
$ ace-taskflow tasks next --priority high
```

## Usage Scenarios

### Scenario 1: Morning Standup - What Did I Work On?
```bash
# Before: Complex flag combination
$ ace-taskflow tasks --recent --days 1 --status done,in-progress

# After: Simple preset
$ ace-taskflow tasks yesterday
Yesterday's Activity (3 tasks):
  ✓ task.025  Fixed context loader crash
  → task.026  Implementing preset system
  ✓ task.027  Updated documentation
```

### Scenario 2: Sprint Planning - What's Next?
```bash
# Before: Manual filtering
$ ace-taskflow tasks --status pending --priority high,critical --sort priority:desc

# After: Purpose-built preset
$ ace-taskflow tasks sprint-ready
Sprint Ready (8 tasks by priority):
  🔴 task.030  Critical: Fix production bug
  🟠 task.031  High: Implement auth system
  🟠 task.032  High: Database migration
```

### Scenario 3: Custom Team Presets
```bash
# Create team-specific preset in .ace/taskflow/presets/frontend.yml
---
description: Frontend team tasks
base: next
filters:
  context: [ui, css, react]
  labels: [frontend]
sort: priority:desc

# Use the custom preset
$ ace-taskflow tasks frontend
Frontend Tasks (4 items):
  task.035  Update React components
  task.036  Fix CSS layout issues
```

### Scenario 4: Preset Composition
```bash
# Start with a preset, add filters
$ ace-taskflow tasks recent --status done
Recently Completed (12 tasks):
  ✓ task.025  Completed 2 hours ago
  ✓ task.024  Completed 5 hours ago

# Combine with other options
$ ace-taskflow tasks next --estimate "< 2h"
Quick Tasks (3 items, under 2 hours):
  task.038  Fix typo in README (15m)
  task.039  Update config schema (1h)
```

### Scenario 5: Consistent Interface Across Entities
```bash
# Tasks
$ ace-taskflow tasks next
$ ace-taskflow tasks recent
$ ace-taskflow tasks all

# Ideas (same pattern)
$ ace-taskflow ideas next
$ ace-taskflow ideas recent
$ ace-taskflow ideas all

# Releases (same pattern)
$ ace-taskflow releases active
$ ace-taskflow releases upcoming
$ ace-taskflow releases all
```

### Scenario 6: AI Agent Usage
```bash
# AI agents can use semantic presets
$ ace-taskflow tasks ready-for-review
Tasks Ready for Review (6 items):
  task.040  PR #123 - Needs code review
  task.041  Docs update - Needs technical review

# Clear intent for automation
$ ace-taskflow tasks blocked
Blocked Tasks (2 items):
  ⚠ task.042  Waiting on: task.040
  ⚠ task.043  Waiting on: external API access
```

## Preset Configuration Examples

### Default Presets (Built-in)
```yaml
# .ace/taskflow/presets/next.yml
description: Next actionable tasks
filters:
  status: [pending, in-progress]
sort: sort:asc,priority:desc
limit: 10

# .ace/taskflow/presets/recent.yml
description: Recently modified tasks
time_filter: modified
days: 7
sort: modified:desc

# .ace/taskflow/presets/blocked.yml
description: Tasks with unmet dependencies
filters:
  has_blockers: true
sort: priority:desc
```

### Custom Team Presets
```yaml
# .ace/taskflow/presets/code-review.yml
description: Tasks needing code review
filters:
  status: [pending-review]
  labels: [needs-review]
sort: created:asc

# .ace/taskflow/presets/quick-wins.yml
description: Quick tasks that can be done fast
filters:
  estimate: ["< 30m"]
  status: [pending]
sort: estimate:asc
```

## Benefits

1. **Intuitive Commands**: `tasks recent` is clearer than `tasks --recent --days 7`
2. **Consistent Interface**: Same pattern across tasks, ideas, and releases
3. **Customizable**: Teams can define their own presets
4. **Composable**: Start with preset, add filters as needed
5. **AI-Friendly**: Semantic presets are easier for agents to understand
6. **Reduces Cognitive Load**: Common queries become simple commands