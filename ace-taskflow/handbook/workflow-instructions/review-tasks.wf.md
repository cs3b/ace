---
name: review-tasks
allowed-tools: Bash, Read, Task
description: Review multiple tasks in sequence and aggregate findings
argument-hint: "[task-id-pattern]"
---

# Review Multiple Tasks Workflow

## Goal

Process multiple tasks through review workflow and aggregate findings, questions, and recommendations with comprehensive error handling and progress reporting.

## Prerequisites

- Tasks exist for review (discoverable via `ace-taskflow tasks` with various filters)
- Access to `review-task` singular workflow via `ace-nav wfi://review-task`
- Understanding of ace-taskflow commands

## Variables

- `$task_pattern`: Optional pattern or list to filter tasks for review (from argument)

## Process Steps

### Step 1: Discover Tasks for Review

**If no task pattern provided (default behavior):**
```bash
# Get next 5 actionable tasks (excludes completed)
ace-taskflow tasks --status pending --limit 5
```

**Common filter patterns if user specifies:**
- Tasks needing human input: `ace-taskflow tasks needs-review` (preset)
- Draft tasks needing clarification: `ace-taskflow tasks --status draft`
- Pending tasks for implementation review: `ace-taskflow tasks --status pending`
- Specific task IDs or ranges

**Output:**
- List of task IDs/paths to review
- Total count of tasks found

### Step 2: Process Each Task Sequentially

For each task in the list:

**2.1 Start Processing:**
- Report: "Reviewing task N of M: [task-id] [task-title]"
- Note current task status (will remain unchanged)

**2.2 Execute Review Task Workflow:**

Use Task tool to delegate to singular workflow:

**Task tool prompt:**
```
Execute review-task workflow for task: [task-id]

ARGUMENTS: [task-id]

Follow the complete review-task workflow:
1. Read and execute: ace-nav wfi://review-task
2. Generate questions by priority (HIGH/MEDIUM/LOW)
3. Conduct research and update content
4. Set needs_review flag appropriately
5. Follow all workflow steps exactly
6. Report review outcomes when complete

Expected output:
- Task ID and status (unchanged)
- Questions generated with priorities
- Research conducted
- Content updates made
- needs_review flag status
- Implementation readiness assessment
- Any issues encountered
```

**Subagent type:** general-purpose

**2.3 Collect Review Data:**

After review completes, collect:
- Questions by priority (HIGH/MEDIUM/LOW)
- needs_review flag status
- Implementation readiness assessment
- Any blockers identified

**2.4 Error Handling:**

If review fails:
- Log the failure with task ID and error details
- Add to failures list
- Continue to next task (don't stop batch)

If partial review completed:
- Save partial progress
- Add to warnings list
- Include in final summary

**2.5 Progress Update:**
- Brief summary of review completed
- Questions count by priority
- needs_review status
- Current success/failure count
- Move to next task

### Step 3: Aggregate Findings and Generate Summary

After all tasks reviewed:

**3.1 Run Documentation Validation:**
```bash
bin/lint
```
- Ensure all documentation passes quality checks
- Fix any linting issues found

**3.2 Aggregate Questions by Priority:**

Group all questions from all task reviews:

**HIGH Priority Questions:**
- [Task ID] Question text
- [Task ID] Question text

**MEDIUM Priority Questions:**
- [Task ID] Question text
- [Task ID] Question text

**LOW Priority Questions:**
- [Task ID] Question text
- [Task ID] Question text

**3.3 Create Summary Report:**

Provide comprehensive summary including:

**Statistics:**
- Total tasks reviewed: X
- Tasks with needs_review:true: Y
- Total questions generated: Z
  - HIGH priority: H
  - MEDIUM priority: M
  - LOW priority: L

**Reviewed Tasks:**
| Task ID | Title | Status | Questions | needs_review | Readiness |
|---------|-------|--------|-----------|--------------|-----------|
| v.X.Y+NNN | ... | pending | 3 (2H, 1M) | true | partial |

**Questions Requiring Attention:**
- List aggregated questions by priority
- Include task context for each question
- Note which need immediate human input

**Implementation Readiness:**
- Tasks ready for implementation: X
- Tasks needing clarification: Y
- Tasks blocked: Z

**Failures (if any):**
- Task ID: [id]
- Error: [description]
- Action needed: [recommendation]

**Warnings (if any):**
- Issue: [description]
- Context: [details]

**Recommendations:**
- Priority actions (e.g., answer HIGH priority questions)
- Tasks ready for /ace:work-on-tasks
- Tasks needing more research or planning
- Any follow-up actions needed

## Error Handling Strategies

### Task Discovery Failure
- **Symptom:** Task listing command returns no results or errors
- **Action:** Report issue, check filter criteria, exit gracefully

### Review Workflow Failure
- **Symptom:** Review-task workflow fails or returns error
- **Action:** Log failure, skip to next task, include in final summary

### Question Aggregation Issues
- **Symptom:** Unable to parse or aggregate questions from reviews
- **Action:** Include raw review output, warn user, continue processing

### Validation Failure
- **Symptom:** `bin/lint` fails after reviews
- **Action:** Attempt auto-fix, report issues, don't fail entire batch

## Output / Success Criteria

- All tasks reviewed (or failures documented)
- Task statuses remain unchanged (review doesn't alter status)
- Questions aggregated by priority across all tasks
- needs_review flags set appropriately
- Implementation readiness assessed for all tasks
- Comprehensive summary report generated
- Documentation validation passes (or issues reported)
- Clear next steps and priority actions identified

## Usage Examples

```bash
# Review next 5 actionable tasks (default)
/ace:review-tasks

# Review all tasks needing human input
/ace:review-tasks --filter needs_review:true

# Review all draft tasks for clarity
/ace:review-tasks --status draft

# Review pending tasks for implementation readiness
/ace:review-tasks --status pending

# Review specific tasks by ID
/ace:review-tasks v.X.Y+NNN v.X.Y+MMM
```

## Important Notes

- Execute tasks sequentially (no parallel processing)
- Each task gets full review-task workflow treatment
- Use Task tool to delegate to singular workflow
- **CRITICAL:** Never change task status during review
- Aggregate questions across all reviews by priority
- Track needs_review flags for follow-up
- Maintain detailed progress logs
- Continue on failure (collect all results)
- Always provide comprehensive final summary with aggregated findings
- Focus on identifying blockers and readiness for implementation
