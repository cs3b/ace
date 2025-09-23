# ace-taskflow User Experience Examples

## Overview

ace-taskflow provides a unified interface for managing your development workflow through releases, tasks, and ideas. This document shows real-world usage examples for common workflows.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Daily Developer Workflow](#daily-developer-workflow)
3. [Release Management](#release-management)
4. [Task Management](#task-management)
5. [Idea Capture and Promotion](#idea-capture-and-promotion)
6. [Advanced Workflows](#advanced-workflows)

---

## Quick Start

### First Time Setup

```bash
# Check your current release
ace-taskflow release

# See what to work on next
ace-taskflow task

# Capture a quick idea
ace-taskflow idea "Add caching to improve API response time"
```

### Essential Commands

```bash
# Release info
ace-taskflow release                      # Current release info
ace-taskflow release list                 # All releases

# Task management
ace-taskflow task                         # Next actionable task
ace-taskflow task list                    # All tasks in current release
ace-taskflow task start task.019          # Start working on a task
ace-taskflow task done task.019           # Mark task as complete

# Idea capture
ace-taskflow idea "Quick thought"         # Capture to backlog
ace-taskflow idea list                    # See all ideas
```

---

## Daily Developer Workflow

### Morning Standup

```bash
# What release am I working on?
$ ace-taskflow release
Current Release: v.0.9.0-mono-repo-multiple-gems
Status: active
Progress: 14/18 tasks complete (78%)
In Progress: 2 tasks
Pending: 2 tasks

# What did I work on recently?
$ ace-taskflow task recent --days 1
Recent Tasks (last 24 hours):
  ✓ task.018 - Create ace-nav gem (completed 2h ago)
  ⚡ task.019 - Implement ace-taskflow commands (in-progress)

# What should I work on next?
$ ace-taskflow task next --limit 3
Next actionable tasks:
1. task.019 - Implement ace-taskflow release and task management
2. task.007 - Create ace-git gem with ace-gc only
3. task.008 - Configure .ace for this project
```

### Starting Work on a Task

```bash
# Get task details
$ ace-taskflow task show task.019
Task: v.0.9.0+task.019
Title: Implement ace-taskflow Release and Task Management Commands
Status: pending → in-progress
Priority: high
Estimate: 3d
Path: tasks/v.0.9.0+task.019-implement-ace-taskflow-release-and-task-management-commands.md

# Mark it as in-progress
$ ace-taskflow task start task.019
Task task.019 marked as in-progress
Started at: 2025-09-23 10:30:00

# Open the task file (if needed)
$ ace-taskflow task show task.019 --open
```

### Completing Work

```bash
# Mark task as done
$ ace-taskflow task done task.019
Task task.019 marked as complete
Duration: 2d 4h (estimated: 3d)

# Quick status check
$ ace-taskflow release status
Release: v.0.9.0-mono-repo-multiple-gems
Progress: ████████████████░░░░ 83% (15/18)
Completed today: 1
In progress: 1
Remaining: 2
```

---

## Release Management

### Working with Releases

```bash
# List all releases
$ ace-taskflow release list
Releases:
  CURRENT:
    v.0.9.0-mono-repo-multiple-gems (15/18 tasks)

  BACKLOG:
    v.0.10.0-performance-improvements (planned)
    v.0.11.0-enhanced-testing (draft)

  DONE:
    v.0.8.0-initial-setup (18/18 tasks)
    v.0.7.0-prototype (12/12 tasks)

# Get detailed release information
$ ace-taskflow release status
Release: v.0.9.0-mono-repo-multiple-gems
Created: 2025-09-19
Duration: 4 days
Tasks:
  Completed: 15 (83%)
  In Progress: 1 (6%)
  Pending: 2 (11%)
Velocity: 3.75 tasks/day
Estimated completion: 1 day remaining
```

### Creating a New Release

```bash
# Create a new release in backlog
$ ace-taskflow release create v.0.10.0-performance-improvements
Created release: v.0.10.0-performance-improvements
Path: dev-taskflow/backlog/v.0.10.0-performance-improvements/
Status: backlog

# Switch context to work on it
$ ace-taskflow release switch v.0.10.0
Switched to release: v.0.10.0-performance-improvements
Note: This is a backlog release. Use 'release promote' when ready to make it current.
```

### Completing a Release

```bash
# Check if ready to complete
$ ace-taskflow release validate
Release validation for v.0.9.0:
  ✓ No tasks in 'in-progress' status
  ✓ All high-priority tasks completed
  ✓ Test coverage acceptable
  ⚠ 2 pending tasks remain (consider rescheduling)

# Move pending tasks to next release
$ ace-taskflow task move task.008,task.009 --to v.0.10.0
Moved 2 tasks to v.0.10.0-performance-improvements

# Complete the release
$ ace-taskflow release complete
Release v.0.9.0-mono-repo-multiple-gems completed!
Moved to: dev-taskflow/done/v.0.9.0-mono-repo-multiple-gems/
Tasks completed: 16/18 (2 rescheduled)

# Promote next release
$ ace-taskflow release promote
Promoted v.0.10.0-performance-improvements to current
Path: dev-taskflow/current/v.0.10.0-performance-improvements/
```

---

## Task Management

### Creating Tasks

```bash
# Create a new task in current release
$ ace-taskflow task create "Implement caching layer for API responses"
Created task: v.0.10.0+task.001
Path: tasks/v.0.10.0+task.001-implement-caching-layer-for-api-responses.md
Status: draft

# Create a task with options
$ ace-taskflow task create "Fix memory leak in worker process" \
  --priority high \
  --estimate 1d \
  --status pending
Created task: v.0.10.0+task.002
```

### Task Lifecycle

```bash
# View task in different statuses
$ ace-taskflow task list --status draft
Draft tasks (need planning):
  task.001 - Implement caching layer

$ ace-taskflow task list --status pending
Pending tasks (ready to start):
  task.002 - Fix memory leak
  task.003 - Update documentation

$ ace-taskflow task list --status in-progress
Tasks in progress:
  task.004 - Refactor authentication (started by: you, 2h ago)

# Move through lifecycle
$ ace-taskflow task start task.001
$ ace-taskflow task done task.001
```

### Filtering and Sorting

```bash
# High priority tasks only
$ ace-taskflow task list --priority high
High priority tasks:
  task.002 - Fix memory leak (pending)
  task.005 - Security patch (pending)

# Sort by different criteria
$ ace-taskflow task list --sort priority:desc,created:asc
$ ace-taskflow task list --sort estimate:asc

# Complex filters
$ ace-taskflow task list \
  --status pending,in-progress \
  --priority high,medium \
  --sort priority:desc
```

### Working Across Releases

```bash
# View backlog tasks
$ ace-taskflow task list --backlog
Backlog tasks:
  task.030 - Migrate to GraphQL
  task.031 - Add multi-language support

# View tasks in specific release
$ ace-taskflow task list --release v.0.11.0
Tasks in v.0.11.0-enhanced-testing:
  task.001 - Add integration test suite
  task.002 - Set up CI/CD pipeline

# Move task between releases
$ ace-taskflow task move task.030 --to current
Moved task.030 to current release (v.0.10.0)

$ ace-taskflow task reschedule task.031 --to v.0.12.0
Rescheduled task.031 to v.0.12.0
```

---

## Idea Capture and Promotion

### Quick Idea Capture

```bash
# Capture to backlog (default)
$ ace-taskflow idea "Investigate WebSocket for real-time updates"
Captured idea: backlog/ideas/20250923-143022-investigate-websocket.md

# Capture to current release
$ ace-taskflow idea "Add input validation for user form" --current
Captured idea: current/v.0.10.0/ideas/20250923-143045-add-input-validation.md

# Capture with category
$ ace-taskflow idea "Optimize database indexes" --category performance
Captured idea: backlog/ideas/performance/20250923-143100-optimize-database.md
```

### Managing Ideas

```bash
# List all ideas
$ ace-taskflow idea list
Ideas (12 total):
  BACKLOG (8):
    20250923-websocket-investigation.md
    20250922-graphql-migration.md
    20250921-caching-strategy.md
    ...

  CURRENT RELEASE (4):
    20250923-input-validation.md
    20250923-error-handling.md
    ...

# View specific idea
$ ace-taskflow idea show 20250923-websocket
Title: Investigate WebSocket for real-time updates
Captured: 2025-09-23 14:30:22
Category: feature
Content:
  Look into replacing polling with WebSocket connections
  for dashboard updates. Could reduce server load and
  improve UX with instant updates.

# Search ideas
$ ace-taskflow idea list --search "cache"
Matching ideas:
  20250921-caching-strategy.md
  20250920-redis-cache.md
```

### Converting Ideas to Tasks

```bash
# Convert single idea to task
$ ace-taskflow task from-idea backlog/ideas/20250923-websocket.md
Creating task from idea: Investigate WebSocket for real-time updates

Enter priority (high/medium/low) [medium]: high
Enter estimate (e.g., 2d, 4h) [TBD]: 3d
Enter initial status (draft/pending) [draft]: draft

Created task: v.0.10.0+task.006
Original idea moved to: current/v.0.10.0/docs/ideas/task.006-websocket.md

# Batch conversion with defaults
$ ace-taskflow task from-idea backlog/ideas/*.md --auto
Converting 8 ideas to tasks...
Created 8 draft tasks in current release
Ideas moved to: current/v.0.10.0/docs/ideas/
```

---

## Advanced Workflows

### Release Planning Session

```bash
# Review backlog ideas for next release
$ ace-taskflow idea list --backlog | head -20

# Create next release
$ ace-taskflow release create v.0.11.0-user-experience

# Convert promising ideas to tasks
$ ace-taskflow task from-idea backlog/ideas/ux-*.md \
  --release v.0.11.0 \
  --priority medium \
  --status draft

# Review the new release
$ ace-taskflow task list --release v.0.11.0
$ ace-taskflow release status --release v.0.11.0
```

### Sprint Planning

```bash
# Get overview of current state
$ ace-taskflow release status --verbose

# List all pending tasks with estimates
$ ace-taskflow task list --status pending --format detailed
task.001 [3d] Implement caching layer (high priority)
task.002 [1d] Fix memory leak (high priority)
task.003 [2d] Update documentation (medium priority)
task.004 [4h] Add input validation (low priority)
Total: 6.5 days of work

# Assign tasks for sprint (mark as in-progress)
$ ace-taskflow task start task.001,task.002
Started 2 tasks
Sprint capacity: 4d committed
```

### Daily Task Flow

```bash
# Morning: Check status and pick task
$ ace-taskflow release status --brief
$ ace-taskflow task next
$ ace-taskflow task start task.007

# During work: Capture ideas without context switching
$ ace-taskflow idea "Refactor this module to use strategy pattern" --current

# Afternoon: Complete task and pick next
$ ace-taskflow task done task.007
$ ace-taskflow task next

# End of day: Review progress
$ ace-taskflow task recent --today
$ ace-taskflow release status
```

### CI/CD Integration

```bash
# Validate before deployment
$ ace-taskflow release validate --strict
Release validation: PASSED
  ✓ No incomplete high-priority tasks
  ✓ All tests passing
  ✓ Documentation updated
  ✓ Change log generated

# Generate release notes
$ ace-taskflow release changelog
## v.0.10.0 - Performance Improvements

### Completed (16 tasks)
- Implement caching layer for API responses
- Optimize database queries
- Add connection pooling
...

### Known Issues
- Minor UI glitch in settings page (task.045)

# Export metrics
$ ace-taskflow release metrics --format json > metrics.json
$ ace-taskflow task stats --format csv > task-stats.csv
```

### Task Templates and Folders

```bash
# Create complex task with folder structure
$ ace-taskflow task create "Implement OAuth2 authentication" \
  --with-folder \
  --template feature
Created task: v.0.10.0+task.010
Created folder: tasks/task.010-implement-oauth2-authentication/
  README.md
  research/
  design/
  implementation/
  tests/

# Add files to task folder
$ cd tasks/task.010-implement-oauth2-authentication/
$ echo "# OAuth2 Research Notes" > research/oauth2-providers.md
$ echo "# API Design" > design/api-spec.md
```

### Bulk Operations

```bash
# Reschedule multiple tasks
$ ace-taskflow task reschedule task.020,task.021,task.022 \
  --to v.0.11.0 \
  --reason "Deprioritized for performance work"
Rescheduled 3 tasks to v.0.11.0

# Bulk status update
$ ace-taskflow task update task.* \
  --status pending \
  --where "status:draft AND priority:high"
Updated 4 tasks from draft to pending

# Archive old ideas
$ ace-taskflow idea archive --older-than 30d
Archived 15 ideas older than 30 days
Moved to: backlog/ideas/.archive/
```

---

## Configuration Examples

### Custom Paths (.ace/taskflow.yml)

```yaml
taskflow:
  release:
    current_path: "./releases/active"
    backlog_path: "./releases/planning"
    done_path: "./releases/archive"

  task:
    directory: "work-items"
    use_folders: true

  idea:
    directory: "ideas"
    default_location: current  # Capture to current by default
```

### Command Aliases

```bash
# Add to shell config (.bashrc, .zshrc, config.fish)
alias atr='ace-taskflow release'
alias att='ace-taskflow task'
alias ati='ace-taskflow idea'

# Quick workflows
alias next='ace-taskflow task next'
alias done='ace-taskflow task done'
alias idea='ace-taskflow idea'

# Usage
$ next
$ done task.019
$ idea "Quick thought"
```

---

## Tips and Best Practices

1. **Daily Routine**: Start with `ace-taskflow task next` to focus immediately
2. **Idea Capture**: Use `ace-taskflow idea` liberally - review weekly
3. **Task Sizing**: Keep tasks under 3 days for better tracking
4. **Release Cycles**: Complete releases regularly (2-4 weeks)
5. **Context Switching**: Use `--current`, `--backlog`, `--release` flags effectively
6. **Automation**: Integrate with git hooks for automatic status updates
7. **Reviews**: Use `ace-taskflow task recent` for standups and reviews

---

## Troubleshooting

```bash
# Debug mode for detailed output
$ ace-taskflow task --debug

# Check configuration
$ ace-taskflow config show

# Verify file integrity
$ ace-taskflow validate

# Get help
$ ace-taskflow --help
$ ace-taskflow task --help
$ ace-taskflow release --help
```