# ace-taskflow User Experience Examples

## Overview

ace-taskflow provides a unified interface for managing your development workflow through releases, tasks, and ideas. It features a clean directory structure (.ace-taskflow/), qualified task references (v.0.9.0+018, backlog+025), and simple release transitions (promote/demote).

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
ace-taskflow release                      # Show active release(s)
ace-taskflow releases                     # List all releases

# Task management
ace-taskflow task                         # Next task from active release
ace-taskflow tasks                        # List tasks in active release
ace-taskflow task start 019               # Start working on a task
ace-taskflow task done 019                # Mark task as complete

# Qualified task references
ace-taskflow task v.0.9.0+018             # Task from specific release
ace-taskflow task backlog+025             # Task from backlog

# Idea capture
ace-taskflow idea "Quick thought"         # Capture to active release
ace-taskflow idea "Future work" --backlog # Capture to backlog
ace-taskflow ideas                        # List all ideas
```

---

## Daily Developer Workflow

### Morning Standup

```bash
# What release am I working on?
$ ace-taskflow release
Active Release: v.0.9.0
Location: .ace-taskflow/v.0.9.0/
Progress: 14/18 tasks complete (78%)
In Progress: 2 tasks
Pending: 2 tasks

# What did I work on recently?
$ ace-taskflow tasks --recent --days 1
Recent Tasks (last 24 hours):
  ✓ task.018 - Create ace-nav gem (completed 2h ago)
  ⚡ task.019 - Implement ace-taskflow commands (in-progress)

# What should I work on next?
$ ace-taskflow task
Next task: 019 - Implement ace-taskflow release and task management
Priority: high, Estimate: 3d
Path: .ace-taskflow/v.0.9.0/t/019/task.md

# Check backlog tasks?
$ ace-taskflow task --backlog
Next backlog task: 025 - Refactor authentication module

# See more options?
$ ace-taskflow tasks --status pending
Pending tasks in v.0.9.0:
  019 - Implement ace-taskflow
  007 - Create ace-git gem
  008 - Configure .ace project
```

### Starting Work on a Task

```bash
# Get task details (multiple ways)
$ ace-taskflow task 019                   # Current context
$ ace-taskflow task v.0.9.0+019           # Explicit release
$ ace-taskflow task current+019           # Explicit current

Task: 019
Title: Implement ace-taskflow Release and Task Management
Status: pending
Priority: high
Path: .ace-taskflow/v.0.9.0/t/019/task.md

# Mark it as in-progress
$ ace-taskflow task start 019
Task 019 marked as in-progress
Started at: 2025-09-23 10:30:00

# Task has its own folder now
$ ls .ace-taskflow/v.0.9.0/t/019/
task.md  ux/  qa/  docs/
```

### Completing Work

```bash
# Mark task as done
$ ace-taskflow task done 019
Task 019 marked as complete
Duration: 2d 4h (estimated: 3d)

# Quick status check
$ ace-taskflow release
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
$ ace-taskflow releases
Releases:
  ACTIVE:
    v.0.9.0 (15/18 tasks) - primary
    v.0.9.1 (3/5 tasks)   - hotfix

  BACKLOG:
    v.0.10.0 (planned)
    v.0.11.0 (draft)

  DONE:
    v.0.8.0 (18/18 tasks)
    v.0.7.0 (12/12 tasks)

# Show active release(s)
$ ace-taskflow release
Active Releases (2):
  v.0.9.0 - Main Development (primary)
    Path: .ace-taskflow/v.0.9.0/
    Progress: 15/18 (83%)

  v.0.9.1 - Hotfix
    Path: .ace-taskflow/v.0.9.1/
    Progress: 3/5 (60%)

# Show specific release
$ ace-taskflow release v.0.10.0
Release: v.0.10.0
Status: backlog
Path: .ace-taskflow/backlog/v.0.10.0/
```

### Creating and Promoting Releases

```bash
# Create a new release (always in backlog)
$ ace-taskflow release create v.0.10.0
Created release: v.0.10.0
Path: .ace-taskflow/backlog/v.0.10.0/
Status: backlog

# Promote from backlog to active
$ ace-taskflow release promote v.0.10.0
Promoting v.0.10.0: backlog → active
Moved to: .ace-taskflow/v.0.10.0/

# Or promote the next backlog release
$ ace-taskflow release promote
Promoting v.0.11.0 (lowest in backlog)
```

### Demoting a Release (Completing)

```bash
# Check if ready
$ ace-taskflow release validate
Release validation for v.0.9.0:
  ✓ No tasks in 'in-progress' status
  ✓ All high-priority tasks completed
  ⚠ 2 pending tasks remain

# Move pending tasks using qualified references
$ ace-taskflow task move v.0.9.0+008 v.0.10.0
$ ace-taskflow task move v.0.9.0+009 backlog
Moved tasks to their destinations

# Demote the release (active → done)
$ ace-taskflow release demote v.0.9.0
Demoting v.0.9.0: active → done
Moved to: .ace-taskflow/done/v.0.9.0/
Completed: 16/18 tasks

# Or demote to backlog (rare)
$ ace-taskflow release demote v.0.9.1 --to backlog
Demoting v.0.9.1: active → backlog
```

---

## Task Management

### Creating Tasks

```bash
# Create task in active release
$ ace-taskflow task create "Implement caching layer"
Created task: 001
Path: .ace-taskflow/v.0.10.0/t/001/task.md
Status: draft

# Create task in backlog
$ ace-taskflow task create "Future feature" --backlog
Created task: backlog+042
Path: .ace-taskflow/backlog/t/042/task.md

# Create task in specific release
$ ace-taskflow task create "Hotfix" --release v.0.9.1
Created task: v.0.9.1+003
Path: .ace-taskflow/v.0.9.1/t/003/task.md
```

### Task Lifecycle

```bash
# View tasks in different contexts
$ ace-taskflow tasks                      # Active release
Tasks in v.0.10.0:
  001 - Implement caching layer (draft)
  002 - Fix memory leak (pending)

$ ace-taskflow tasks --backlog            # Backlog tasks
Backlog tasks:
  042 - Future feature (draft)
  043 - Technical debt (pending)

$ ace-taskflow tasks --all                # Everything
All tasks:
  v.0.9.0+018 - Nav gem (done)
  v.0.10.0+001 - Caching (draft)
  backlog+042 - Future feature (draft)

# Move through lifecycle
$ ace-taskflow task start 001
$ ace-taskflow task done 001
```

### Filtering and Sorting

```bash
# High priority tasks only
$ ace-taskflow tasks --priority high
High priority tasks:
  task.002 - Fix memory leak (pending)
  task.005 - Security patch (pending)

# Sort by different criteria
$ ace-taskflow tasks --sort priority:desc,created:asc
$ ace-taskflow tasks --sort estimate:asc

# Complex filters
$ ace-taskflow tasks \
  --status pending,in-progress \
  --priority high,medium \
  --sort priority:desc
```

### Working with Qualified References

```bash
# Reference tasks from any context
$ ace-taskflow task v.0.9.0+018           # Specific release
$ ace-taskflow task backlog+042           # From backlog
$ ace-taskflow task current+001           # Explicit current

# Move tasks between contexts
$ ace-taskflow task move backlog+042 v.0.10.0
Moved task 042: backlog → v.0.10.0
New reference: v.0.10.0+003

$ ace-taskflow task move v.0.9.0+007 backlog
Moved task 007: v.0.9.0 → backlog
New reference: backlog+044

# Cross-release operations
$ ace-taskflow task done v.0.9.1+002      # Complete in different release
$ ace-taskflow task start backlog+043     # Start backlog task
```

---

## Idea Capture and Promotion

### Quick Idea Capture

```bash
# Capture to active release (default)
$ ace-taskflow idea "Add input validation for user form"
Captured: .ace-taskflow/v.0.10.0/ideas/20250923-143045-input-validation.md

# Capture to backlog
$ ace-taskflow idea "Investigate WebSocket" --backlog
Captured: .ace-taskflow/backlog/ideas/20250923-143022-websocket.md

# Capture to specific release
$ ace-taskflow idea "Performance optimization" --release v.0.11.0
Captured: .ace-taskflow/backlog/v.0.11.0/ideas/20250923-143100-performance.md
```

### Managing Ideas

```bash
# List all ideas
$ ace-taskflow ideas
Ideas (12 total):
  v.0.10.0 (4):
    20250923-input-validation.md
    20250923-error-handling.md
    ...

  BACKLOG (8):
    20250923-websocket.md
    20250922-graphql.md
    20250921-caching.md
    ...

# View specific idea
$ ace-taskflow idea 20250923-websocket
Title: Investigate WebSocket for real-time updates
Captured: 2025-09-23 14:30:22
Category: feature
Content:
  Look into replacing polling with WebSocket connections
  for dashboard updates. Could reduce server load and
  improve UX with instant updates.

# Search ideas
$ ace-taskflow ideas --search "cache"
Matching ideas:
  20250921-caching-strategy.md
  20250920-redis-cache.md
```

### Converting Ideas to Tasks

```bash
# Convert idea to task
$ ace-taskflow idea to-task 20250923-websocket
Converting idea to task...

Target release [active/v.0.10.0]: v.0.11.0
Priority [medium]: high
Estimate [TBD]: 3d

Created: v.0.11.0+004
Path: .ace-taskflow/backlog/v.0.11.0/t/004/task.md
Idea archived to: .ace-taskflow/backlog/v.0.11.0/t/004/docs/original-idea.md
```

---

## Advanced Workflows

### Release Planning Session

```bash
# Review backlog ideas
$ ace-taskflow ideas --backlog

# Create and setup new release
$ ace-taskflow release create v.0.11.0
Created in backlog: .ace-taskflow/backlog/v.0.11.0/

# Convert ideas to tasks in new release
$ ace-taskflow idea to-task 20250923-ux-redesign --release v.0.11.0
$ ace-taskflow idea to-task 20250922-dark-mode --release v.0.11.0

# Review and promote when ready
$ ace-taskflow tasks --release v.0.11.0
$ ace-taskflow release promote v.0.11.0
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
$ cd .ace-taskflow/v.0.10.0/t/010/
$ ls
task.md  ux/  qa/  docs/
$ echo "# OAuth2 Research" > docs/research.md
$ echo "# API Design" > docs/api-spec.md
```

### Bulk Operations

```bash
# Move multiple tasks using qualified references
$ ace-taskflow task move v.0.9.0+020 backlog
$ ace-taskflow task move v.0.9.0+021 backlog
$ ace-taskflow task move backlog+030 v.0.11.0
Moved 3 tasks to their destinations

# Bulk operations with shell
$ for task in 020 021 022; do
  ace-taskflow task move v.0.9.0+$task v.0.11.0
done

# Archive old ideas
$ ace-taskflow ideas --older-than 30d | while read idea; do
  ace-taskflow idea archive $idea
done
```

---

## Directory Structure

### New Clean Layout

```
.ace-taskflow/                 # Configurable root
├── backlog/                  # Backlog items
│   ├── ideas/                # Unassigned ideas
│   ├── t/                    # Backlog tasks
│   │   └── 025/
│   │       └── task.md
│   └── v.0.11.0/             # Future release (in backlog)
│       ├── release.md
│       └── t/
├── v.0.9.0/                  # Active release
│   ├── release.md           # Release metadata
│   ├── ideas/                # Release ideas
│   ├── docs/                 # Documentation
│   ├── qa/                   # Tests & reviews
│   ├── reflections/          # Dev notes
│   └── t/                    # Tasks
│       ├── 018/
│       │   ├── task.md      # Main task file
│       │   ├── ux/          # UX designs
│       │   └── qa/          # Tests
│       └── 019/
└── done/                     # Completed releases
    └── v.0.8.0/
```

### Task References

```bash
# Simple (current context)
019                            # Task in active release

# Qualified (explicit context)
current+019                    # Explicit current/active
backlog+025                    # From backlog
v.0.9.0+018                    # From specific release
v.0.11.0+004                   # From backlog release
```

---

## Configuration Examples

### Configuration (.ace/taskflow.yml)

```yaml
taskflow:
  # Root directory for all taskflow data
  root: ".ace-taskflow"              # Default, can be changed

  # Task organization
  task_dir: "t"                      # Tasks folder name

  # Release management
  active_strategy: "lowest"          # How to pick primary active
  allow_multiple_active: true        # Allow multiple active releases

  # Qualified references
  references:
    allow_qualified: true            # Enable v.0.9.0+018 syntax
    allow_cross_release: true        # Can reference other releases

  # Default contexts
  defaults:
    idea_location: "active"          # Where ideas go by default
    task_location: "active"          # Where new tasks go
```

### Command Aliases

```bash
# Add to shell config (.bashrc, .zshrc, config.fish)
alias atr='ace-taskflow release'
alias att='ace-taskflow task'
alias ati='ace-taskflow idea'
alias atrs='ace-taskflow releases'
alias atts='ace-taskflow tasks'
alias atis='ace-taskflow ideas'

# Quick workflows
alias task='ace-taskflow task'
alias done='ace-taskflow task done'
alias idea='ace-taskflow idea'

# Usage
$ task              # See next task
$ done task.019     # Complete task
$ idea "Quick thought"  # Capture idea
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