# Task 034: Task Dependency Management - Usage Examples

## Current Behavior (Before)

```bash
# No dependency tracking
$ ace-taskflow task show 026
Task: v.0.9.0+task.026
Title: Deploy to production
Status: pending
[No information about prerequisites]

# Can start any task regardless of prerequisites
$ ace-taskflow task start 026
Task 026 marked as in-progress
[Even though database migration task 025 must complete first]

# No way to see dependency relationships
$ ace-taskflow tasks
[Shows all pending tasks mixed together without considering dependencies]
```

## New Behavior (After)

```bash
# Clear dependency information
$ ace-taskflow task show 026
Task: v.0.9.0+task.026
Title: Deploy to production
Status: pending (BLOCKED)
Dependencies:
  ⚠ task.025 (pending)  - Complete database migration
  ✓ task.024 (done)     - Update configuration
Blocked by: task.025

# System prevents invalid transitions
$ ace-taskflow task start 026
Error: Cannot start task.026 - blocked by incomplete dependencies:
  - task.025: Complete database migration (status: pending)
Please complete required dependencies first.

# Default sorting considers dependencies automatically
$ ace-taskflow tasks
Tasks: next (15 found)
================================================
# Ready tasks appear first in natural order
  task.025  ○ 🟠  Database migration
  task.027  ○ 🟠  Update documentation
  task.028  ○ 🟡  Fix unit tests (deps: ✓)
# Tasks with unmet dependencies appear after
  task.026  ⚠ 🟠  Deploy to production (blocked by: 025)
  task.030  ⚠ 🟡  Integration tests (blocked by: 028, 029)
```

## Usage Scenarios

### Scenario 1: Setting Up Dependencies

```bash
# Add single dependency
$ ace-taskflow task add-dependency 026 --depends-on 025
Added dependency: task.026 now depends on task.025

# Add multiple dependencies
$ ace-taskflow task add-dependency 030 --depends-on 028,029
Added dependencies: task.030 now depends on task.028, task.029

# Remove dependency
$ ace-taskflow task remove-dependency 026 --depends-on 024
Removed dependency: task.026 no longer depends on task.024
```

### Scenario 2: Circular Dependency Prevention

```bash
$ ace-taskflow task add-dependency 025 --depends-on 026
Error: Cannot add dependency - would create circular dependency:
  task.025 → task.026 → task.025
Dependency chain must be acyclic.
```

### Scenario 3: Viewing Dependency Trees

```bash
# View dependency tree for specific task
$ ace-taskflow task show 035 --tree
Task: v.0.9.0+task.035 - Complete Feature X

Dependency Tree:
└─ task.035 (current) [BLOCKED]
   ├─ ✓ task.031 - Setup infrastructure (done)
   ├─ → task.032 - Implement backend (in-progress)
   │  └─ ✓ task.030 - Design API (done)
   └─ ⚠ task.033 - Create frontend (blocked)
      ├─ ○ task.034 - Design UI mockups (pending)
      └─ → task.032 - Implement backend (in-progress)

Ready to start when: task.032, task.033 complete

# View global dependency tree
$ ace-taskflow tasks --tree
Dependency Tree View:
================================================
Release: v.0.9.0

├─ task.025 - Database migration ○
│  └─ task.026 - Deploy to production ⚠
│     └─ task.040 - Launch v1.0 ⚠
├─ task.027 - Update documentation ○
├─ task.028 - Fix unit tests ○
│  └─ task.030 - Integration tests ⚠
└─ task.032 - Implement backend →
   ├─ task.033 - Create frontend ⚠
   └─ task.035 - Complete Feature X ⚠

Legend: ✓ done  → in-progress  ○ pending  ⚠ blocked
```

### Scenario 4: Default Task Listing with Dependency Sorting

```bash
# Default task listing automatically sorts by dependencies
$ ace-taskflow tasks
Tasks: next (13 pending)
================================================
# Ready tasks (sorted by priority/sort order)
  task.041  ○ 🟠  Fix critical bug
  task.042  ○ 🟠  Update API docs (deps: ✓)
  task.044  ○ 🟡  Add logging
  task.043  ○ 🟡  Refactor auth module (deps: ✓)
  task.045  ○ ⚪  Clean up tests (deps: ✓)

# Blocked tasks (appear after ready tasks)
  task.046  ⚠ 🟠  Deploy feature (blocked by: 041)
  task.047  ⚠ 🟡  Performance test (blocked by: 043, 044)
  task.048  ⚠ ⚪  Documentation (blocked by: 042)

Note: Tasks with unmet dependencies automatically appear after ready tasks
```

### Scenario 5: Dependency Chain Visualization

```bash
# View dependency chain for a specific task
$ ace-taskflow task show 040 --tree
Task: v.0.9.0+task.040 - Launch v1.0

Dependency Chain:
└─ task.040 - Launch v1.0 [BLOCKED]
   ├─ task.039 - Security audit ⚠
   │  └─ task.038 - Performance optimization ⚠
   │     └─ task.037 - End-to-end testing ⚠
   │        └─ task.036 - Frontend integration ⚠
   │           └─ task.035 - Complete backend features →
   └─ task.026 - Deploy to production ⚠
      └─ task.025 - Database migration ○

Blocking tasks: 8 tasks must complete before this can start
Estimated time: 10 days (if all dependencies completed sequentially)
```

### Scenario 6: Bulk Dependency Management

```bash
# Create task with dependencies from the start
$ ace-taskflow task create "Deploy to staging" --depends-on 025,026,027
Created task v.0.9.0+task.050 with 3 dependencies

# Set up a chain of tasks
$ ace-taskflow task chain 051 052 053 054
Created dependency chain: 051 → 052 → 053 → 054

# Make multiple tasks depend on one
$ ace-taskflow task add-dependency 061,062,063 --depends-on 060
Updated 3 tasks to depend on task.060
```

### Scenario 7: Dependency-Aware Task Navigation

```bash
# Default next task considers dependencies
$ ace-taskflow task next
Next task: v.0.9.0+task.025
Title: Database migration
Priority: high
Estimate: 3h
Blocks: task.026 (Deploy to production)

# List shows ready tasks first automatically
$ ace-taskflow tasks next --limit 3
Tasks: next (showing 3 of 15 found)
================================================
  task.025  ○ 🟠  Database migration
  task.027  ○ 🟠  Update documentation
  task.028  ○ 🟡  Fix unit tests (deps: ✓)
```

### Scenario 8: Dependency Status Report

```bash
$ ace-taskflow tasks --dependency-report
Dependency Analysis for v.0.9.0:
================================================
Tasks with dependencies:     28/67 (42%)
Currently blocked:           12/28 (43%)
Ready despite dependencies:  10/28 (36%)
Completed with dependencies: 6/28  (21%)

Longest dependency chains:
  8 levels: task.040 (Launch v1.0)
  6 levels: task.035 (Complete Feature X)
  5 levels: task.030 (Production deploy)

Common blockers:
  task.025 blocks 5 other tasks
  task.032 blocks 3 other tasks

Suggested focus: Complete task.025 to unblock the most work
```

### Scenario 9: AI Agent Workflow

```bash
# AI agent queries for next task (dependencies considered automatically)
$ ace-taskflow task next
{
  "task_id": "v.0.9.0+task.041",
  "title": "Fix critical bug",
  "priority": "high",
  "estimate": "2h",
  "dependencies_met": true,
  "reason": "High priority task with no blocking dependencies"
}

# Default task list already shows ready tasks first
$ ace-taskflow tasks --format json --limit 3
[
  {"id": "task.041", "status": "pending", "blocked": false},
  {"id": "task.042", "status": "pending", "blocked": false},
  {"id": "task.046", "status": "pending", "blocked": true, "blocked_by": ["task.041"]}
]
```

### Scenario 10: Tree View for Dependencies

```bash
$ ace-taskflow tasks --tree
Dependency Tree:
================================================
v.0.9.0 (15 tasks, 8 with dependencies)

# Independent task chains
├─ task.025 ○ Database migration
│  └─ task.026 ⚠ Deploy to production
│     └─ task.040 ⚠ Launch v1.0
│
├─ task.027 ○ Update documentation
│
├─ task.028 → Fix unit tests
│  └─ task.029 ⚠ Integration tests
│
└─ task.032 ○ Implement backend
   ├─ task.033 ⚠ Create frontend
   │  └─ task.035 ⚠ Complete Feature X
   └─ task.034 ⚠ Design UI mockups

Legend: ✓ done  → in-progress  ○ ready  ⚠ blocked
```

## Configuration

```yaml
# .ace/taskflow/config.yml
dependencies:
  enforce_strict: true        # Prevent starting blocked tasks
  allow_circular: false       # Prevent circular dependencies
  auto_cascade: true         # Auto-update dependent task states
  show_in_listings: true     # Show dependency count in task lists
  warn_on_long_chains: 5     # Warn if chain exceeds N levels
```

## Benefits

1. **Prevents Errors**: Can't start tasks out of order
2. **Clear Workflow**: Understand task relationships and prerequisites
3. **Better Planning**: See critical paths and bottlenecks
4. **Autonomous Agents**: AI can determine next actionable tasks reliably
5. **Project Visibility**: Understand what's blocking progress
6. **Efficient Execution**: Focus on tasks that can actually be completed

