---
name: task/plan-batch
allowed-tools: Bash, Read, Task
description: Plan implementation for multiple draft tasks in sequence
argument-hint: "[task-id-pattern]"
doc-type: workflow
purpose: plan-tasks workflow instruction
update:
  frequency: on-change
  last-updated: '2025-10-02'
---

# Plan Multiple Tasks Workflow

## Goal

Process multiple draft tasks and create implementation plans for each one in sequence, with comprehensive error handling and progress reporting.

## Prerequisites

- Draft tasks exist (discoverable via `ace-task list --status draft`)
- Access to `plan-task` singular workflow via `ace-bundle wfi://task/plan`
- Understanding of ace-task commands

## Variables

- `$task_pattern`: Optional pattern or list to filter draft tasks (from argument)

## Process Steps

### Step 1: Discover Draft Tasks

**If no task pattern provided:**
```bash
# Discover all draft tasks
ace-task list --status draft
```

**If task pattern provided:**
- Use the provided pattern/list to filter tasks
- Support specific task IDs or ranges

**Output:**
- List of draft task IDs/paths to process
- Total count of tasks found

### Step 2: Process Each Draft Task Sequentially

For each draft task in the list:

**2.1 Start Processing:**
- Report: "Planning task N of M: [task-id] [task-title]"
- Verify task status is `draft`

**2.2 Execute Plan Task Workflow:**

Use Task tool to delegate to singular workflow:

**Task tool prompt:**
```
Execute plan-task workflow for task: [task-id]

ARGUMENTS: [task-id]

Follow the complete plan-task workflow:
1. Read and execute: ace-bundle wfi://task/plan
2. Transform task from status:draft to status:pending
3. Add complete implementation plan
4. Follow all workflow steps exactly
5. Report planning outcomes when complete

Expected output:
- Task ID and updated status (pending)
- Technical approach selected
- Key planning decisions made
- Files modified
- Any issues encountered
```

**Subagent type:** general-purpose

**2.3 Verify Status Transition:**

After planning succeeds:
```bash
# Verify task status changed
ace-task show [task-id] | grep -q "status:pending" || echo "WARNING: Status not updated"
```

**2.4 Error Handling:**

If planning fails:
- Log the failure with task ID and error details
- Add to failures list
- Continue to next task (don't stop batch)

If status transition fails:
- Report warning
- Add to warnings list
- Include in final summary

**2.5 Progress Update:**
- Brief summary of planning completed
- Status transition confirmed
- Current success/failure count
- Move to next task

### Step 3: Generate Final Summary

After all draft tasks planned:

**3.1 Run Documentation Validation:**
```bash
bin/lint
```
- Ensure all documentation passes quality checks
- Fix any linting issues found

**3.2 Create Summary Report:**

Provide comprehensive summary including:

**Statistics:**
- Total draft tasks processed: X
- Successfully planned (draft→pending): Y
- Failures: Z
- Warnings: W

**Planned Tasks:**
| Task ID | Title | Status | Technical Approach |
|---------|-------|--------|-------------------|
| v.X.Y+NNN | ... | pending | ... |

**Failures (if any):**
- Task ID: [id]
- Error: [description]
- Action needed: [recommendation]

**Warnings (if any):**
- Issue: [description]
- Context: [details]

**Recommendations:**
- Next steps (e.g., run /ace-task-works)
- Any follow-up actions needed

## Error Handling Strategies

### Task Discovery Failure
- **Symptom:** `ace-task list --status draft` returns no results or errors
- **Action:** Report issue, check if draft tasks exist, exit gracefully

### Planning Workflow Failure
- **Symptom:** Plan task workflow fails or returns error
- **Action:** Log failure, skip to next task, include in final summary

### Status Transition Failure
- **Symptom:** Task status remains `draft` after planning
- **Action:** Warn user, check if plan was added but status not updated, manual fix may be needed

### Validation Failure
- **Symptom:** `bin/lint` fails after planning
- **Action:** Attempt auto-fix, report issues, don't fail entire batch

## Output / Success Criteria

- All draft tasks processed (or failures documented)
- Tasks transitioned from `status: draft` to `status: pending`
- Implementation plans added to all tasks
- Comprehensive summary report generated
- Documentation validation passes (or issues reported)
- Clear next steps provided

## Usage Examples

```bash
# Plan all draft tasks
/ace-task-plans

# Plan specific task pattern (if supported)
/ace-task-plans [pattern]

# Plan specific tasks by ID
/ace-task-plans v.X.Y+NNN v.X.Y+MMM
```

## Important Notes

- Execute tasks sequentially (no parallel processing)
- Each task gets full plan-task workflow treatment
- Use Task tool to delegate to singular workflow
- Verify status transitions after each task
- Maintain detailed progress logs
- Continue on failure (collect all results)
- Always provide comprehensive final summary
- No git tagging (planning only, not execution)
