---
name: work-on-tasks
allowed-tools: Bash, Read, Task
description: Execute work on multiple pending tasks in sequence
argument-hint: "[task-id-pattern]"
doc-type: workflow
purpose: work-on-tasks workflow instruction
update:
  frequency: on-change
  last-updated: '2025-10-02'
---

# Work on Multiple Tasks Workflow

## Goal

Process multiple pending tasks and execute implementation work for each one in sequence, with comprehensive error handling and progress reporting.

## Prerequisites

- Pending tasks exist (discoverable via `ace-taskflow tasks --status pending`)
- Access to `work-on-task` singular workflow via `ace-nav wfi://work-on-task`
- Understanding of ace-taskflow commands and git operations

## Variables

- `$task_pattern`: Optional pattern or list to filter pending tasks (from argument)

## Process Steps

### Step 1: Discover Pending Tasks

**If no task pattern provided:**
```bash
# Get next pending task (singular)
ace-taskflow task
```

**If task pattern provided:**
- Use the provided pattern/list to filter tasks
- Support specific task IDs or ranges
- Use `ace-taskflow tasks --status pending` for filtering

**Output:**
- List of pending task IDs/paths to process
- Total count of tasks found

### Step 2: Process Each Pending Task Sequentially

For each pending task in the list:

**2.1 Start Processing:**
- Report: "Working on task N of M: [task-id] [task-title]"
- Verify task status is `pending`

**2.2 Execute Work on Task Workflow:**

Use Task tool to delegate to singular workflow:

**Task tool prompt:**
```
Execute work-on-task workflow for task: [task-id]

ARGUMENTS: [task-id]

Follow the complete work-on-task workflow:
1. Read and execute: ace-nav wfi://work-on-task
2. Execute all implementation steps
3. Update task status to done when complete
4. Follow all workflow steps exactly
5. Report work outcomes when complete

Expected output:
- Task ID and updated status (done/blocked)
- Key changes made
- Files modified
- Tests run and results
- Any issues encountered
```

**Subagent type:** general-purpose

**2.3 Create Git Tags (After Successful Completion):**

If task completed successfully:
```bash
# Extract task ID from task path
TASK_ID="[task-id]"

# Tag all relevant repositories
git -C ace-taskflow tag "$TASK_ID" 2>/dev/null || true
git -C ace-git-commit tag "$TASK_ID" 2>/dev/null || true
git -C dev-handbook tag "$TASK_ID" 2>/dev/null || true
git -C dev-tools tag "$TASK_ID" 2>/dev/null || true
git tag "$TASK_ID" 2>/dev/null || true

# Report tagging status
echo "Git tags created for task: $TASK_ID"
```

**Note:** Tags mark completion points for tracking and rollback purposes.

**2.4 Error Handling:**

If work execution fails:
- Log the failure with task ID and error details
- Check if task was marked as `blocked`
- Add to failures list
- Continue to next task (don't stop batch)

If git tagging fails:
- Report warning but don't fail the batch
- Add to warnings list
- Include in final summary

**2.5 Progress Update:**
- Brief summary of work completed
- Status transition confirmed (pending→done or pending→blocked)
- Current success/failure count
- Move to next task

### Step 3: Generate Final Summary

After all pending tasks processed:

**3.1 Run Full Test Suite:**
```bash
bin/test
```
- Ensure all tests pass
- Address any test failures

**3.2 Run Documentation Validation:**
```bash
bin/lint
```
- Ensure all documentation passes quality checks
- Fix any linting issues found

**3.3 Final Project Validation:**
```bash
bin/build
```
- Verify project builds successfully (if applicable)

**3.4 Create Summary Report:**

Provide comprehensive summary including:

**Statistics:**
- Total pending tasks processed: X
- Successfully completed (pending→done): Y
- Blocked: Z
- Failures: W

**Completed Tasks:**
| Task ID | Title | Status | Git Tag | Key Changes |
|---------|-------|--------|---------|-------------|
| v.X.Y+NNN | ... | done | ✓ | ... |

**Blocked/Failed Tasks (if any):**
- Task ID: [id]
- Status: [blocked/failed]
- Reason: [description]
- Action needed: [recommendation]

**Warnings (if any):**
- Issue: [description]
- Context: [details]

**Recommendations:**
- Next steps (e.g., run /ace:review-tasks, address blockers)
- Any follow-up actions needed

## Error Handling Strategies

### Task Discovery Failure
- **Symptom:** `ace-taskflow task` or `ace-taskflow tasks --status pending` returns no results or errors
- **Action:** Report issue, check if pending tasks exist, exit gracefully

### Work Execution Failure
- **Symptom:** Work-on-task workflow fails or returns error
- **Action:** Log failure, check if task was blocked, skip to next task, include in final summary

### Test Failure
- **Symptom:** `bin/test` fails after work execution
- **Action:** Report failures, may need to mark tasks as blocked, manual intervention required

### Git Tagging Failure
- **Symptom:** Git tag command fails for one or more repositories
- **Action:** Warn user, work still completed, manual tagging may be needed

### Validation Failure
- **Symptom:** `bin/lint` or `bin/build` fails after work
- **Action:** Attempt auto-fix, report issues, may need manual intervention

## Output / Success Criteria

- All pending tasks processed (or failures documented)
- Tasks transitioned from `status: pending` to `status: done` or `status: blocked`
- Git tags created for completed tasks
- All tests pass
- Documentation validation passes
- Build succeeds (if applicable)
- Comprehensive summary report generated
- Clear next steps provided

## Usage Examples

```bash
# Work on next single pending task
/ace:work-on-tasks

# Work on specific task pattern (if supported)
/ace:work-on-tasks [pattern]

# Work on specific tasks by ID
/ace:work-on-tasks v.X.Y+NNN v.X.Y+MMM
```

## Important Notes

- Execute tasks sequentially (no parallel processing)
- Each task gets full work-on-task workflow treatment
- Use Task tool to delegate to singular workflow
- Always create git tags for completed tasks
- Run full test suite after all work
- Maintain detailed progress logs
- Continue on failure (collect all results)
- Always provide comprehensive final summary
- Commit changes are handled by individual work-on-task workflows
