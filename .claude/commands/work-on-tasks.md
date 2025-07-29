# Work on Multiple Tasks

You are an AI assistant that automatically executes multiple tasks in sequence. This command processes a list of tasks and performs the complete workflow for each one.

## Task Selection

If no task list is provided by the user:
- Run `task-manager next` to get the next single task
- If user wants multiple tasks, use `task-manager next --limit 9` to get up to 9 tasks

If user provides a specific task list or command, use that instead.

## For Each Task in Sequence

Execute the following steps for each task:

### 1. Work on Task
Run the work-on-task command for the specific task:
```
/work-on-task <task-path>
```

### 2. Create Reflection Note
After completing the task work, create a reflection:
```
/create-reflection-note
```

### 3. Commit Changes
Commit all changes made during task execution:
```
/commit
```

### 4. Tag Repositories
Create git tags across all repositories using the task full ID:

```bash
# Extract task ID from task path (e.g., v.0.3.0+task.225)
TASK_ID="<extracted-task-id>"

# Tag all repositories
git -C dev-handbook tag "$TASK_ID"
git -C dev-tools tag "$TASK_ID" 
git -C dev-taskflow tag "$TASK_ID"
git tag "$TASK_ID"

# Push tags (optional - be careful)
# git-commit  # This pushes changes, tags handled separately
```

### 5. Summary
Provide a summary of work completed for this task:
- Task ID and title
- Key changes made
- Files modified
- Any issues encountered
- Status (completed/partial/blocked)

## Between Tasks

After completing one task, briefly report progress and move to the next task in the list.

## Final Summary

After all tasks are completed, provide:
- Total tasks processed
- Success/failure count
- Overview of all changes made
- Any blockers or issues that need attention
- Recommendations for next steps

## Error Handling

If a task fails:
- Document the failure reason
- Skip to next task (don't stop entire process)
- Include failure in final summary
- Consider creating follow-up tasks for failures

## Usage Examples

```
# Work on next single task
/work-on-tasks

# Work on next 5 tasks  
/work-on-tasks task-manager next --limit 5

# Work on specific tasks
/work-on-tasks v.0.3.0+task.225 v.0.3.0+task.226 v.0.3.0+task.227
```

## Important Notes

- Execute tasks sequentially (no parallel processing)
- Each task gets full workflow treatment
- Create proper git tags for tracking
- Maintain detailed logs of progress
- Stop if critical errors occur
- Always create reflection notes for learning