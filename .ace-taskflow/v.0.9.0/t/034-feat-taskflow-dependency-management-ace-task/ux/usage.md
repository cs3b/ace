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

# No way to see what tasks are actually ready to work on
$ ace-taskflow tasks
[Shows all pending tasks, even those that can't be started yet]
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

# Show only actionable tasks
$ ace-taskflow tasks --ready
Ready Tasks (3 of 15 pending):
  task.025  Database migration (no dependencies)
  task.027  Update documentation (no dependencies)
  task.028  Fix unit tests (dependencies met)
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
$ ace-taskflow task show 035 --dependencies
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
```

### Scenario 4: Finding Next Actionable Tasks
```bash
$ ace-taskflow tasks --ready
Actionable Tasks (5 tasks with all dependencies met):
================================================
  task.041  ○ 🟠  Fix critical bug (no dependencies)
  task.042  ○ 🟠  Update API docs (dependencies: ✓)
  task.043  ○ 🟡  Refactor auth module (dependencies: ✓)
  task.044  ○ 🟡  Add logging (no dependencies)
  task.045  ○ ⚪  Clean up tests (dependencies: ✓)

Blocked Tasks: 8 (use --blocked to see details)
```

### Scenario 5: Critical Path Analysis
```bash
$ ace-taskflow task critical-path 040
Critical Path to task.040 - Launch v1.0:
================================================
Days  Task
  3   task.035 - Complete backend features
  2   task.036 - Frontend integration
  1   task.037 - End-to-end testing
  1   task.038 - Performance optimization
  2   task.039 - Security audit
  1   task.040 - Launch v1.0
────────────────────────────────────────────────
 10   Total days (minimum time to complete)

Parallel tracks available:
  - Documentation (tasks 041-043): 5 days
  - Marketing prep (tasks 044-045): 3 days
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

### Scenario 7: Smart Status Transitions
```bash
# Attempting to start a blocked task
$ ace-taskflow task start 035
Cannot start task.035: Waiting on 2 dependencies:
  - task.033: Create frontend (pending)
  - task.034: Design UI mockups (pending)

Would you like to:
  1. Start task.033 instead (ready)
  2. Start task.034 instead (ready)
  3. View all ready tasks
  4. Cancel
Choice: 1

Starting task.033: Create frontend
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
# AI agent queries for next task
$ ace-taskflow task next
Suggested next task: task.041
Reason: High priority, no dependencies, estimated 2h

Alternative ready tasks:
  task.042 (high priority, deps met, 4h)
  task.043 (medium priority, no deps, 1h)

# AI agent checks if it can start a specific task
$ ace-taskflow task can-start 035
{
  "can_start": false,
  "reason": "blocked_by_dependencies",
  "blocking_tasks": ["task.033", "task.034"],
  "blocking_tasks_status": {
    "task.033": "pending",
    "task.034": "pending"
  }
}
```

### Scenario 10: Visual Dependency Graph
```bash
$ ace-taskflow tasks --graph
Task Dependency Graph:
================================================
     ┌─────────┐
     │task.025 │
     └────┬────┘
          │
    ┌─────┴─────┐
    ▼           ▼
┌────────┐  ┌────────┐
│task.026│  │task.027│
└────┬───┘  └───┬────┘
     │          │
     └────┬─────┘
          ▼
     ┌────────┐
     │task.028│ ← You are here
     └────┬───┘
          ▼
     ┌────────┐
     │task.029│
     └────────┘

Legend: ✓ done  → in-progress  ○ pending  ⚠ blocked
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