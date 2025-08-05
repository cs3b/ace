---
last_modified: '2025-08-05 19:20:58'
source: custom
---

# Plan Multiple Draft Tasks

You are an AI assistant that automatically creates implementation plans for multiple draft tasks in sequence. This command processes a list of draft tasks and performs the complete planning workflow for each one by expanding all workflow instructions inline.

## Task Selection

If no task list is provided by the user:
- Run `task-manager list --filter status:draft` to get all draft tasks
- If user wants multiple tasks, use `task-manager list --filter status:draft --limit 9` to get up to 9 tasks

If user provides a specific task list or command, use that instead.

## For Each Draft Task in Sequence

For each draft task, use the Task tool to create a sub-agent that executes the complete workflow:

**Use Task tool with this prompt:**

```
Execute the complete plan-task workflow for: <task-path>

- [ ] **Plan Task Implementation:**
  - Read the entire file: dev-handbook/workflow-instructions/plan-task.wf.md
  - Follow all steps in the workflow exactly as written
  - Task path: <task-path>
  - Verify task has status: draft before starting
  - Transform task from draft to pending with complete technical implementation plan

- [ ] **Create Reflection Note:**
  - Read the entire file: dev-handbook/workflow-instructions/create-reflection-note.wf.md
  - Follow all steps in the workflow exactly as written
  - Context: Reflect on the task planning work just completed

- [ ] **Planning Summary:**
  - Task ID and title
  - Status change: draft → pending
  - Key planning decisions made
  - Files modified
  - Technical approach selected
  - Any issues encountered
  - Status (completed/partial/blocked)
```

**Subagent type:** general-purpose

## Between Tasks

After completing planning for one task, briefly report progress and move to the next task in the list.

## Final Summary

After all draft tasks are planned:

- [ ] **Run Documentation Validation:**
  ```bash
  code-lint markdown --autofix
  ```
  - Ensure all documentation passes quality checks
  - Address any linting issues before marking completion

- [ ] **Final Project Validation:**
  - Verify all draft tasks were properly transitioned to pending status
  - Confirm all changes are properly committed
  - Check that all task files have complete implementation plans

- [ ] **Summary Report:**
  Provide comprehensive summary including:
  - Total draft tasks processed
  - Success/failure count per task
  - Overview of all tasks transitioned from draft to pending (IDs, titles, paths)
  - Key technical decisions and approaches selected
  - Any blockers or issues that need attention
  - Recommendations for next steps (e.g., task execution)

## Error Handling

If a draft task fails during planning:
- Document the failure reason and context
- Update task status appropriately (blocked/partial) if possible
- Commit any partial planning progress made
- Skip to next task (don't stop entire process)
- Include failure details in final summary
- Consider creating follow-up tasks for planning failures

## Usage Examples

```
# Plan all draft tasks
/plan-tasks

# Plan next 5 draft tasks
/plan-tasks task-manager list --filter status:draft --limit 5

# Plan specific draft tasks (as provided in arguments)
/plan-tasks v.0.4.0+task.5 v.0.4.0+task.7
```

## Important Notes

- Execute tasks sequentially (no parallel processing)
- Each task gets full plan-task workflow treatment with expanded instructions
- Never use Task tool to invoke other slash commands - expand everything inline
- Focus on technical implementation planning, not behavioral specification
- Maintain detailed logs of progress throughout
- Stop if critical errors occur that would cause data loss
- Always create reflection notes for learning and improvement
- Commit changes incrementally (planning work, then reflection) for better tracking
- All tasks should transition from status: draft to status: pending
- No git tagging since tasks are planned but not executed
