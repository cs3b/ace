# Batch Task Operations - Usage Guide

This document provides practical examples of how to use the batch task commands in Claude Code.

## Overview

Batch task commands allow you to process multiple tasks in a single command invocation, streamlining your workflow when managing multiple related tasks.

**Available Claude Code Commands:**
- `/ace:draft-tasks` - Create multiple draft tasks from idea files
- `/ace:plan-tasks` - Plan implementation for multiple draft tasks
- `/ace:work-on-tasks` - Execute work on multiple tasks
- `/ace:review-tasks` - Review multiple tasks

## Command Types

This guide uses two types of commands:

### Claude Code Commands (Slash Commands)
Commands starting with `/` are executed **within Claude Code**:
```
/ace:draft-tasks
/ace:plan-tasks
/ace:work-on-tasks
/ace:review-tasks
```

### Bash CLI Commands
Commands without `/` are **terminal/bash commands**:
```bash
ace-taskflow ideas --backlog
ace-taskflow tasks --status draft
ace-taskflow tasks recent
ace-taskflow idea done <reference>
ace-nav wfi://draft-tasks
```

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
# Step 1: Check what ideas are in the backlog (bash command)
ace-taskflow ideas --backlog
```

```
# Step 2: Create draft tasks from all ideas (Claude Code command)
/ace:draft-tasks

# Output:
# Processing 5 idea files...
#
# [1/5] Processing: 20250930-improve-test-coverage
#   ✓ Created task v.0.9.0+task.048: Improve test coverage
#   ✓ Idea marked as done (ace-taskflow idea done 20250930-improve-test-coverage)
#
# [2/5] Processing: 20250930-refactor-config-loader
#   ✓ Created task v.0.9.0+task.049: Refactor config loader
#   ✓ Idea marked as done (ace-taskflow idea done 20250930-refactor-config-loader)
#
# ... (3 more)
#
# Summary:
# - Total ideas processed: 5
# - Tasks created: 5
# - Ideas marked as done: 5
# - Failures: 0
# - New task IDs: 048, 049, 050, 051, 052
```

### Scenario 2: Planning Multiple Tasks

**Goal**: Add implementation plans to all draft tasks

```bash
# Step 1: See which tasks need planning (bash command)
ace-taskflow tasks --status draft
```

```
# Step 2: Plan all draft tasks (Claude Code command)
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

**Goal**: Work through specific pending tasks

```bash
# Step 1: Identify pending tasks (bash command)
ace-taskflow tasks --status pending
```

```
# Step 2: Work on specific tasks by ID (Claude Code command)
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

```
# Review all tasks to identify issues (Claude Code command)
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
# First, check specific ideas in backlog (bash command)
ace-taskflow ideas --backlog | grep "20250930"
```

```
# Draft tasks from specific idea references (Claude Code command)
/ace:draft-tasks 20250930-improve-test-coverage 20250930-refactor-config-loader
```

```
# Plan tasks with specific IDs (Claude Code command)
/ace:plan-tasks v.0.9.0+task.048 v.0.9.0+task.049 v.0.9.0+task.050
```

```bash
# Work on next 3 pending tasks - first identify them (bash command)
ace-taskflow tasks --status pending --limit 3
```

```
# Then work on them (Claude Code command)
/ace:work-on-tasks v.0.9.0+task.048 v.0.9.0+task.049 v.0.9.0+task.050
```

```bash
# Review only draft tasks - first check which ones (bash command)
ace-taskflow tasks --status draft
```

```
# Then review specific tasks (Claude Code command)
/ace:review-tasks v.0.9.0+task.053 v.0.9.0+task.054
```

### Scenario 6: Error Handling and Recovery

**Goal**: Handle failures gracefully and continue processing

```
# Attempt to work on multiple tasks (Claude Code command)
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

```
# Monday: Convert ideas to draft tasks (Claude Code)
/ace:draft-tasks
```

```
# Tuesday: Plan implementation for drafts (Claude Code)
/ace:plan-tasks
```

```
# Wednesday-Thursday: Execute tasks (Claude Code)
/ace:work-on-tasks
```

```
# Friday: Review completed work (Claude Code)
/ace:review-tasks
```

### Release Preparation Workflow

```bash
# 1. Review all pending tasks - check status (bash)
ace-taskflow tasks --status pending
```

```
# 2. Review them (Claude Code)
/ace:review-tasks
```

```
# 3. Plan any remaining drafts (Claude Code)
/ace:plan-tasks
```

```bash
# 4. Work through pending items - identify them (bash)
ace-taskflow tasks --status pending
```

```
# 5. Work on them (Claude Code)
/ace:work-on-tasks [task-ids]
```

```
# 6. Final quality review (Claude Code)
/ace:review-tasks
```

## Tips and Best Practices

### 1. Start Small
Begin with a few tasks to understand the workflow:
```bash
# Check available ideas first (bash)
ace-taskflow ideas --backlog
```

```
# Process just 2-3 ideas first (Claude Code)
/ace:draft-tasks idea-reference-1 idea-reference-2
```

```
# Plan one task to see the process (Claude Code)
/ace:plan-tasks v.0.9.0+task.048
```

### 2. Use Flags Effectively
Leverage ace-taskflow flags to target specific tasks:
```bash
# By status (bash)
ace-taskflow tasks --status pending

# Recent tasks (bash)
ace-taskflow tasks recent

# With limit (bash)
ace-taskflow tasks --status pending --limit 5

# By release (bash)
ace-taskflow tasks --release v.0.9.0
```

### 3. Check Status Before Processing
Always verify task status before batch operations:
```bash
# Check draft tasks before planning (bash)
ace-taskflow tasks --status draft

# Check pending tasks before working (bash)
ace-taskflow tasks --status pending
```

### 4. Handle Failures Gracefully
Review failure summaries and address blockers:
```bash
# After a failed batch operation, check blocked tasks (bash)
ace-taskflow tasks --status blocked
```

```
# Work on blockers individually (Claude Code)
/ace:work-on-tasks v.0.9.0+task.049
```

### 5. Incremental Processing
For large batches, process in smaller chunks:
```bash
# Check how many ideas you have (bash)
ace-taskflow ideas --backlog
```

```
# Instead of all at once, process in batches (Claude Code)
/ace:draft-tasks idea-ref-1 idea-ref-2 idea-ref-3
```

```
# ... review results, then continue ...
/ace:draft-tasks idea-ref-4 idea-ref-5 idea-ref-6
```

## Command Reference

### /ace:draft-tasks

**Type**: Claude Code command

**Purpose**: Create multiple draft tasks from idea files

**Input Discovery**: Uses `ace-taskflow ideas --backlog` to find ideas

**Idea Cleanup**: Uses `ace-taskflow idea done <reference>` to mark ideas as done

**Usage**:
```
/ace:draft-tasks                          # All ideas in backlog
/ace:draft-tasks idea-ref-1 idea-ref-2    # Specific idea references
```

**Output**: Task IDs, ideas marked as done, error summary

---

### /ace:plan-tasks

**Type**: Claude Code command

**Purpose**: Add implementation plans to draft tasks

**Input Discovery**: Uses `ace-taskflow tasks --status draft` to find draft tasks

**Usage**:
```
/ace:plan-tasks                           # All draft tasks
/ace:plan-tasks v.0.9.0+task.048         # Specific task
/ace:plan-tasks task.048 task.049        # Multiple tasks
```

**Output**: Status transitions (draft→pending), planning summaries, technical decisions

---

### /ace:work-on-tasks

**Type**: Claude Code command

**Purpose**: Execute implementation work on tasks

**Input Discovery**: Uses `ace-taskflow tasks --status pending` to find pending tasks

**Usage**:
```
/ace:work-on-tasks                        # Next pending task(s)
/ace:work-on-tasks v.0.9.0+task.048      # Specific task
/ace:work-on-tasks task.048 task.049     # Multiple tasks
```

**Output**: Implementation status, test results, git tags, status transitions

---

### /ace:review-tasks

**Type**: Claude Code command

**Purpose**: Review tasks for quality and completeness

**Input Discovery**: Uses `ace-taskflow tasks` with various flags (--status, --release, etc.) or `ace-taskflow tasks recent`

**Usage**:
```
/ace:review-tasks                         # Next actionable tasks
/ace:review-tasks v.0.9.0+task.048       # Specific task
/ace:review-tasks task.048 task.049      # Multiple tasks
```

**Output**: Questions, readiness assessment, needs_review flags

## Troubleshooting

### Problem: Command doesn't find any tasks

**Check** (using bash commands):
```bash
# Verify tasks exist (bash)
ace-taskflow tasks

# Check current release (bash)
ace-taskflow release

# Verify task status (bash)
ace-taskflow tasks --status draft
```

### Problem: Workflow not found

**Check** (using bash commands):
```bash
# Verify workflow exists (bash)
ace-nav wfi://draft-tasks --list
ace-nav wfi://plan-tasks --list

# Check all task workflows (bash)
ace-nav 'wfi://*tasks' --list
```

### Problem: Tasks in wrong status

**Fix**:
```bash
# Check task metadata (bash)
ace-taskflow task show 048
```

Then manually edit task file and change status in frontmatter if needed.

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
