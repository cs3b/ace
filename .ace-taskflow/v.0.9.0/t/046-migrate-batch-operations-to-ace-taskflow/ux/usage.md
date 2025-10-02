# Batch Task Operations - Usage Guide

This document provides practical examples of how to use the batch task commands in Claude Code.

## Overview

Batch task commands allow you to process multiple tasks in a single command invocation, streamlining your workflow when managing multiple related tasks.

**Available Commands:**
- `/ace:draft-tasks` - Create multiple draft tasks from idea files
- `/ace:plan-tasks` - Plan implementation for multiple draft tasks
- `/ace:work-on-tasks` - Execute work on multiple tasks
- `/ace:review-tasks` - Review multiple tasks

## Command Structure

All batch commands follow the same invocation pattern:

```
/ace:[command-name] [optional-pattern-or-list]
```

**Without arguments**: Uses sensible defaults (e.g., next 5 tasks, all ideas in backlog)
**With arguments**: Processes specific tasks or patterns

## Usage Scenarios

### Scenario 1: Weekly Planning Session

**Goal**: Review backlog ideas and create draft tasks for the week

```bash
# Step 1: Check what ideas are in the backlog
ls .ace-taskflow/v.0.9.0/ideas/

# Step 2: Create draft tasks from all ideas
/ace:draft-tasks

# Output:
# Processing 5 idea files...
#
# [1/5] Processing: 20250930-improve-test-coverage.md
#   ✓ Created task v.0.9.0+task.048: Improve test coverage
#   ✓ Idea file moved to release docs
#
# [2/5] Processing: 20250930-refactor-config-loader.md
#   ✓ Created task v.0.9.0+task.049: Refactor config loader
#   ✓ Idea file moved to release docs
#
# ... (3 more)
#
# Summary:
# - Total ideas processed: 5
# - Tasks created: 5
# - Failures: 0
# - New task IDs: 048, 049, 050, 051, 052
```

### Scenario 2: Planning Multiple Tasks

**Goal**: Add implementation plans to all draft tasks

```bash
# Step 1: See which tasks need planning
ace-taskflow tasks --filter status:draft

# Step 2: Plan all draft tasks
/ace:plan-tasks

# Output:
# Found 5 draft tasks to plan...
#
# [1/5] Planning task v.0.9.0+task.048: Improve test coverage
#   ✓ Technical research completed
#   ✓ Implementation plan added
#   ✓ Status: draft → pending
#
# [2/5] Planning task v.0.9.0+task.049: Refactor config loader
#   ✓ Technical research completed
#   ✓ Implementation plan added
#   ✓ Status: draft → pending
#
# ... (3 more)
#
# Summary:
# - Total tasks planned: 5
# - Status transitions: 5 (draft → pending)
# - Failures: 0
# - Ready for implementation: 048, 049, 050, 051, 052
```

### Scenario 3: Focused Development Sprint

**Goal**: Work through specific high-priority tasks

```bash
# Step 1: Identify high-priority pending tasks
ace-taskflow tasks --filter priority:high status:pending

# Step 2: Work on specific tasks by ID
/ace:work-on-tasks v.0.9.0+task.048 v.0.9.0+task.050

# Output:
# Processing 2 tasks...
#
# [1/2] Working on v.0.9.0+task.048: Improve test coverage
#   ✓ Implementation completed
#   ✓ Tests passing
#   ✓ Status: pending → completed
#   ✓ Git tag: v.0.9.0+task.048
#
# [2/2] Working on v.0.9.0+task.050: Add API documentation
#   ✓ Implementation completed
#   ✓ Tests passing
#   ✓ Status: pending → completed
#   ✓ Git tag: v.0.9.0+task.050
#
# Summary:
# - Total tasks processed: 2
# - Completed: 2
# - Failures: 0
# - Git tags created: v.0.9.0+task.048, v.0.9.0+task.050
```

### Scenario 4: Quality Review Cycle

**Goal**: Review all tasks in current release for quality and completeness

```bash
# Step 1: Review all tasks to identify issues
/ace:review-tasks

# Output:
# Found 8 tasks to review (excluding completed)...
#
# [1/8] Reviewing v.0.9.0+task.048: Improve test coverage
#   ✓ Questions generated: 2 (1 HIGH, 1 MEDIUM)
#   ✓ Content analysis complete
#   ⚠ needs_review: true (requires human input)
#
# [2/8] Reviewing v.0.9.0+task.049: Refactor config loader
#   ✓ Questions generated: 0
#   ✓ Implementation ready
#
# ... (6 more)
#
# Summary:
# - Total tasks reviewed: 8
# - Questions generated: 15 (5 HIGH, 7 MEDIUM, 3 LOW)
# - Tasks needing review: 3
# - Implementation ready: 5
#
# High Priority Questions:
#   • Task 048: How should we handle backwards compatibility?
#   • Task 051: Which API version should we target?
#   ... (3 more)
```

### Scenario 5: Selective Processing with Patterns

**Goal**: Process only specific subsets of tasks

```bash
# Draft tasks from specific idea files
/ace:draft-tasks .ace-taskflow/v.0.9.0/ideas/20250930-*.md

# Plan tasks with specific IDs
/ace:plan-tasks v.0.9.0+task.048 v.0.9.0+task.049 v.0.9.0+task.050

# Work on next 3 pending tasks
ace-taskflow tasks --filter status:pending --limit 3
/ace:work-on-tasks v.0.9.0+task.048 v.0.9.0+task.049 v.0.9.0+task.050

# Review only draft tasks (check for clarity)
ace-taskflow tasks --filter status:draft
/ace:review-tasks v.0.9.0+task.053 v.0.9.0+task.054
```

### Scenario 6: Error Handling and Recovery

**Goal**: Handle failures gracefully and continue processing

```bash
# Attempt to work on multiple tasks
/ace:work-on-tasks v.0.9.0+task.048 v.0.9.0+task.049 v.0.9.0+task.050

# Output:
# Processing 3 tasks...
#
# [1/3] Working on v.0.9.0+task.048: Improve test coverage
#   ✓ Implementation completed
#   ✓ Tests passing
#   ✓ Status: pending → completed
#
# [2/3] Working on v.0.9.0+task.049: Refactor config loader
#   ✗ ERROR: Test failures detected
#   ✗ Status: pending → blocked
#   ✗ Details: 3 test failures in config_loader_spec.rb
#
# [3/3] Working on v.0.9.0+task.050: Add API documentation
#   ✓ Implementation completed
#   ✓ Tests passing
#   ✓ Status: pending → completed
#
# Summary:
# - Total tasks processed: 3
# - Completed: 2
# - Blocked: 1
# - Failures: 1
#
# Failed Tasks:
#   • v.0.9.0+task.049: Test failures - requires manual intervention
#
# Next Steps:
#   • Fix test failures in task 049
#   • Re-run: /ace:work-on-tasks v.0.9.0+task.049
```

## Workflow Integration

### Typical Weekly Workflow

```bash
# Monday: Convert ideas to draft tasks
/ace:draft-tasks

# Tuesday: Plan implementation for drafts
/ace:plan-tasks

# Wednesday-Thursday: Execute tasks
/ace:work-on-tasks

# Friday: Review completed work
/ace:review-tasks
```

### Release Preparation Workflow

```bash
# 1. Review all pending tasks
ace-taskflow tasks --filter status:pending
/ace:review-tasks

# 2. Plan any remaining drafts
/ace:plan-tasks

# 3. Work through high-priority items
ace-taskflow tasks --filter priority:high status:pending
/ace:work-on-tasks [task-ids]

# 4. Final quality review
/ace:review-tasks
```

## Tips and Best Practices

### 1. Start Small
Begin with a few tasks to understand the workflow:
```bash
# Process just 2-3 tasks first
/ace:draft-tasks .ace-taskflow/v.0.9.0/ideas/idea1.md
/ace:plan-tasks v.0.9.0+task.048
```

### 2. Use Filters Effectively
Leverage ace-taskflow filters to target specific tasks:
```bash
# High priority only
ace-taskflow tasks --filter priority:high status:pending

# Specific estimate
ace-taskflow tasks --filter estimate:2h

# Multiple filters
ace-taskflow tasks --filter priority:high status:pending estimate:2h
```

### 3. Check Status Before Processing
Always verify task status before batch operations:
```bash
# Check draft tasks before planning
ace-taskflow tasks --filter status:draft

# Check pending tasks before working
ace-taskflow tasks --filter status:pending
```

### 4. Handle Failures Gracefully
Review failure summaries and address blockers:
```bash
# After a failed batch operation, check blocked tasks
ace-taskflow tasks --filter status:blocked

# Work on blockers individually
/ace:work-on-tasks v.0.9.0+task.049
```

### 5. Incremental Processing
For large batches, process in smaller chunks:
```bash
# Instead of all at once
/ace:draft-tasks  # might process 20 ideas

# Process in batches
/ace:draft-tasks idea1.md idea2.md idea3.md
# ... review results ...
/ace:draft-tasks idea4.md idea5.md idea6.md
```

## Command Reference

### /ace:draft-tasks

**Purpose**: Create multiple draft tasks from idea files

**Usage**:
```bash
/ace:draft-tasks                          # All ideas in backlog
/ace:draft-tasks idea1.md idea2.md        # Specific files
/ace:draft-tasks pattern-*.md             # Pattern matching
```

**Output**: Task IDs, idea file movements, error summary

---

### /ace:plan-tasks

**Purpose**: Add implementation plans to draft tasks

**Usage**:
```bash
/ace:plan-tasks                           # All draft tasks
/ace:plan-tasks v.0.9.0+task.048         # Specific task
/ace:plan-tasks task.048 task.049        # Multiple tasks
```

**Output**: Status transitions, planning summaries, technical decisions

---

### /ace:work-on-tasks

**Purpose**: Execute implementation work on tasks

**Usage**:
```bash
/ace:work-on-tasks                        # Next pending task
/ace:work-on-tasks v.0.9.0+task.048      # Specific task
/ace:work-on-tasks task.048 task.049     # Multiple tasks
```

**Output**: Implementation status, test results, git tags

---

### /ace:review-tasks

**Purpose**: Review tasks for quality and completeness

**Usage**:
```bash
/ace:review-tasks                         # Next 5 actionable tasks
/ace:review-tasks v.0.9.0+task.048       # Specific task
/ace:review-tasks                         # All non-completed
```

**Output**: Questions, readiness assessment, needs_review flags

## Troubleshooting

### Problem: Command doesn't find any tasks

**Check**:
```bash
# Verify tasks exist
ace-taskflow tasks --all

# Check current release
ace-taskflow release

# Verify task status
ace-taskflow tasks --filter status:draft
```

### Problem: Workflow not found

**Check**:
```bash
# Verify workflow exists
ace-nav wfi://draft-tasks --list
ace-nav wfi://plan-tasks --list

# Check all task workflows
ace-nav 'wfi://*tasks' --list
```

### Problem: Tasks in wrong status

**Fix**:
```bash
# Check task metadata
ace-taskflow task show 048

# Manually update if needed (edit task file)
# Change status in frontmatter
```

## Migration Notes

**Legacy Commands** (will be removed):
- `/draft-tasks` → Use `/ace:draft-tasks`
- `/plan-tasks` → Use `/ace:plan-tasks`
- `/work-on-tasks` → Use `/ace:work-on-tasks`
- `/review-tasks` → Use `/ace:review-tasks`

**Key Differences**:
- New commands use `ace-nav wfi://` protocol
- Improved error handling and reporting
- Better progress feedback
- Consistent with other /ace: commands

**Transition Period**:
Both legacy and new commands will work during migration, but new commands are recommended for all new work.
