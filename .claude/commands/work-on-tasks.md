---
last_modified: '2025-08-19 01:40:50'
source: custom
---

# Work on Multiple Tasks

You are an AI assistant that automatically executes multiple tasks in sequence. This command processes a list of tasks and performs the complete workflow for each one by expanding all workflow instructions inline.

## Task Selection

If no task list is provided by the user:
- Run `task-manager next` to get the next single task
- If user wants multiple tasks, use `task-manager next --limit 9` to get up to 9 tasks

If user provides a specific task list or command, use that instead.

## For Each Task in Sequence

For each task, use the Task tool to create a sub-agent that executes the complete workflow:

**Use Task tool with this prompt:**

```
Execute the complete task workflow for: <task-path>

- [ ] **Work on Task:**
  - Read the entire file: dev-handbook/workflow-instructions/work-on-task.wf.md
  - Follow all steps in the workflow exactly as written
  - Task path: <task-path>

- [ ] **Create Reflection Note:**
  - Read the entire file: dev-handbook/workflow-instructions/create-reflection-note.wf.md
  - Follow all steps in the workflow exactly as written
  - Context: Reflect on the task work just completed

- [ ] **Tag Repositories:**
  # Extract task ID from task path (e.g., v.0.4.0+task.5)
  TASK_ID="<extracted-task-id>"

- [ ] **Commit all the changes you have made**
  - read and run @.claude/commands/commit.md

  # Tag all repositories
  git -C dev-handbook tag "$TASK_ID"
  git -C dev-tools tag "$TASK_ID"
  git -C dev-taskflow tag "$TASK_ID"
  git tag "$TASK_ID"

- [ ] **Task Summary:**
  - Task ID and title
  - Key changes made
  - Files modified
  - Any issues encountered
  - Status (completed/partial/blocked)
```

**Subagent type:** general-purpose

## Between Tasks

After completing one task, briefly report progress and move to the next task in the list.

## Final Summary

After all tasks are completed:

- [ ] **Run Full Test Suite:**
  ```bash
  bin/test spec/
  ```
  - Ensure all tests pass before marking completion
  - Address any test failures before proceeding

- [ ] **Final Project Validation:**
  - Run `bin/lint` to ensure code quality
  - Run `bin/build` if applicable
  - Verify all changes are properly committed

- [ ] **Summary Report:**
  Provide comprehensive summary including:
  - Total tasks processed
  - Success/failure count
  - Overview of all changes made
  - Any blockers or issues that need attention
  - Recommendations for next steps

## Error Handling

If a task fails during execution:
- Document the failure reason and context
- Update task status appropriately (blocked/partial)
- Commit any partial progress made
- Skip to next task (don't stop entire process)
- Include failure details in final summary
- Consider creating follow-up tasks for failures

## Usage Examples

```
# Work on next single task
/work-on-tasks

# Work on next 5 tasks
/work-on-tasks task-manager next --limit 5

# Work on specific tasks (as provided in arguments)
/work-on-tasks v.0.4.0+task.5 v.0.4.0+task.7
```

## Important Notes

- Execute tasks sequentially (no parallel processing)
- Each task gets full workflow treatment with expanded instructions
- Never use Task tool to invoke other slash commands - expand everything inline
- Create proper git tags for tracking each completed task
- Maintain detailed logs of progress throughout
- Stop if critical errors occur that would cause data loss
- Always create reflection notes for learning and improvement
- Commit changes incrementally (task work, then reflection) for better tracking
